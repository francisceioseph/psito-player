// lib/src/platform/linux_desktop.dart
//
// O player num Linux: as pastas do XDG, o D-Bus da sessão, o `xdg-open`, o `df` e
// o `chmod`.
import 'dart:ffi';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../player/desktop_hooks.dart';
import '../player/mpris.dart';
import '../player/single_instance.dart';
import 'desktop_platform.dart';

/// O barramento da sessão, para os controles de mídia.
DBusClient sessionBus() => DBusClient.session();

/// A pasta de música da pessoa: a do `user-dirs.dirs`, ou `~/Music`. Null se não
/// houver nem uma nem outra.
String? userMusicDir(Map<String, String> env) {
  final home = env['HOME'];
  if (home == null) return null;
  final config = env['XDG_CONFIG_HOME'] ?? p.join(home, '.config');
  final dirs = File(p.join(config, 'user-dirs.dirs'));
  final candidates = <String>[];
  if (dirs.existsSync()) {
    final match = RegExp(
      r'^XDG_MUSIC_DIR="(.*)"$',
      multiLine: true,
    ).firstMatch(dirs.readAsStringSync());
    if (match != null) candidates.add(match[1]!.replaceFirst(r'$HOME', home));
  }
  candidates.add(p.join(home, 'Music'));
  for (final candidate in candidates) {
    if (Directory(candidate).existsSync()) return candidate;
  }
  return null;
}

class _LinuxSession implements DesktopSession {
  final DBusClient _bus;
  final Mpris _mpris;
  final DesktopHooks _hooks;

  _LinuxSession(this._bus, this._mpris, this._hooks);

  @override
  Future<void> close() async {
    await _hooks.dispose();
    await _mpris.close();
    await _bus.close();
  }
}

typedef _ChmodC = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);

_ChmodDart? _chmodFn;

class LinuxDesktop implements DesktopPlatform {
  final Map<String, String> env;

  /// O barramento da sessão. Os testes trocam por um privado.
  final DBusClient Function() connect;

  LinuxDesktop([Map<String, String>? env, this.connect = sessionBus])
    : env = env ?? Platform.environment;

  @override
  String? get homeDir => env['HOME'];

  @override
  String? get musicDir => userMusicDir(env);

  @override
  LibraryServicesPaths get libraryPaths {
    final home = env['HOME'] ?? '.';
    final data = env['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');
    final cache = env['XDG_CACHE_HOME'] ?? p.join(home, '.cache');
    return (
      db: p.join(data, 'psito', 'player', 'library.db'),
      covers: p.join(cache, 'psito', 'player', 'covers'),
      // Fora do cache: limpar o cache traz as dos álbuns de volta, e estas não
      playlistCovers: p.join(data, 'psito', 'player', 'playlist-covers'),
      tagUndo: p.join(data, 'psito', 'player', 'tag-undo'),
    );
  }

  @override
  Future<void> open(String pathOrUrl) async {
    final result = await Process.run('xdg-open', [pathOrUrl]);
    if (result.exitCode != 0) debugPrint('🎵 xdg-open: ${result.stderr}');
  }

  @override
  Future<bool> reveal(String path) async {
    final bus = connect();
    try {
      return await showInFileManager(path, bus);
    } finally {
      await bus.close();
    }
  }

  @override
  Future<AppInstance?> claimInstance(List<String> paths) =>
      SingleInstance.acquire(paths);

  @override
  Future<DesktopSession?> openSession(DesktopSessionRequest request) async {
    final DBusClient bus;
    try {
      bus = connect();
    } catch (e) {
      debugPrint('🎵 sem barramento: $e');
      return null;
    }
    final mpris = Mpris(
      request.playback,
      identity: 'Psito Player',
      onRaise: request.onRaise,
      onQuit: request.onQuit,
    );
    if (await mpris.publish(bus) && request.isOpen()) {
      return _LinuxSession(
        bus,
        mpris,
        DesktopHooks(
          playback: request.playback,
          settings: request.settings,
          bus: bus,
          awakeReason: request.awakeReason,
        ),
      );
    }
    await mpris.close();
    await bus.close();
    return null;
  }

  @override
  (int, String)? diskInfo(String path) {
    try {
      final result = Process.runSync('df', [
        '-B1',
        '--output=avail,fstype',
        path,
      ]);
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String).trim().split('\n');
      final parts = lines.last.trim().split(RegExp(r'\s+'));
      final avail = int.tryParse(parts.first);
      return avail == null || parts.length < 2 ? null : (avail, parts[1]);
    } on ProcessException {
      return null;
    }
  }

  /// O `dart:io` não muda o modo de um arquivo.
  @override
  void restoreFileMode(String path, int mode) {
    final chmod = _chmodFn ??= DynamicLibrary.process()
        .lookupFunction<_ChmodC, _ChmodDart>('chmod');
    final native = path.toNativeUtf8();
    try {
      if (chmod(native, mode) != 0) {
        throw FileSystemException('chmod falhou', path);
      }
    } finally {
      malloc.free(native);
    }
  }
}

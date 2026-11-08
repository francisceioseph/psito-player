// lib/src/platform/windows_desktop.dart
//
// O player no Windows. Por enquanto só o bastante para abrir e tocar: sem
// instância única, sem controles de mídia e sem medir o disco.
import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'desktop_platform.dart';

class _OnlyInstance implements AppInstance {
  @override
  Stream<List<String>> get opens => const Stream.empty();
}

class WindowsDesktop implements DesktopPlatform {
  final Map<String, String> env;

  WindowsDesktop([Map<String, String>? env])
    : env = env ?? Platform.environment;

  String get _home => env['USERPROFILE'] ?? '.';

  /// No Windows, ninguém encurta o caminho para `~`.
  @override
  String? get homeDir => null;

  @override
  String? get musicDir {
    final home = env['USERPROFILE'];
    if (home == null) return null;
    final music = p.windows.join(home, 'Music');
    return Directory(music).existsSync() ? music : null;
  }

  @override
  LibraryServicesPaths get libraryPaths {
    final data = env['APPDATA'] ?? p.windows.join(_home, 'AppData', 'Roaming');
    final cache =
        env['LOCALAPPDATA'] ?? p.windows.join(_home, 'AppData', 'Local');
    return (
      db: p.windows.join(data, 'Psito Player', 'library.db'),
      covers: p.windows.join(cache, 'Psito Player', 'covers'),
      playlistCovers: p.windows.join(data, 'Psito Player', 'playlist-covers'),
      tagUndo: p.windows.join(data, 'Psito Player', 'tag-undo'),
    );
  }

  /// O Explorer abre pastas e endereços. Ele sempre sai com erro, então o código
  /// de saída não diz nada.
  @override
  Future<void> open(String pathOrUrl) async {
    await Process.run('explorer.exe', [pathOrUrl]);
  }

  @override
  Future<bool> reveal(String path) async => false;

  @override
  Future<AppInstance?> claimInstance(List<String> paths) async =>
      _OnlyInstance();

  @override
  Future<DesktopSession?> openSession(DesktopSessionRequest request) async =>
      null;

  @override
  (int, String)? diskInfo(String path) => null;

  /// O Windows não tem o modo de arquivo do Unix.
  @override
  void restoreFileMode(String path, int mode) {}
}

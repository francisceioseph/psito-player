// lib/src/platform/windows_desktop.dart
//
// O player no Windows: as pastas do perfil, o Explorer, os controles de mídia e a
// instância única.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'desktop_platform.dart';
import 'loopback_instance.dart';
import 'windows_session.dart';
import 'windows_smtc.dart';
import 'windows_system.dart';

class WindowsDesktop implements DesktopPlatform {
  final Map<String, String> env;
  final WindowsSystem system;
  final Future<MediaTransport> Function() openTransport;

  WindowsDesktop({
    Map<String, String>? env,
    this.system = const Win32System(),
    this.openTransport = SmtcTransport.open,
  }) : env = env ?? Platform.environment;

  String get _home => env['USERPROFILE'] ?? '.';

  String get _data => p.windows.join(
    env['APPDATA'] ?? p.windows.join(_home, 'AppData', 'Roaming'),
    'Psito Player',
  );

  String get _cache => p.windows.join(
    env['LOCALAPPDATA'] ?? p.windows.join(_home, 'AppData', 'Local'),
    'Psito Player',
  );

  /// No Windows, ninguém encurta o caminho para `~`.
  @override
  String? get homeDir => null;

  @override
  String? get musicDir {
    final home = env['USERPROFILE'];
    final music =
        _ask(system.musicFolder) ??
        (home == null ? null : p.windows.join(home, 'Music'));
    return music != null && Directory(music).existsSync() ? music : null;
  }

  @override
  LibraryServicesPaths get libraryPaths => (
    db: p.windows.join(_data, 'library.db'),
    covers: p.windows.join(_cache, 'covers'),
    playlistCovers: p.windows.join(_data, 'playlist-covers'),
    tagUndo: p.windows.join(_data, 'tag-undo'),
  );

  /// O Explorer abre pastas e endereços. Ele sempre sai com erro, então o código
  /// de saída não diz nada.
  @override
  Future<void> open(String pathOrUrl) async {
    await Process.run('explorer.exe', [pathOrUrl]);
  }

  @override
  Future<bool> reveal(String path) async =>
      _ask(() => system.reveal(p.windows.normalize(path))) ?? false;

  /// Na pasta local: é um processo desta máquina, e a Roaming viaja com o perfil.
  @override
  Future<AppInstance?> claimInstance(List<String> paths) =>
      LoopbackInstance.acquire(
        _cache,
        paths,
        beforeHandOff: () => _ask(system.allowForeground),
      );

  @override
  Future<DesktopSession?> openSession(DesktopSessionRequest request) async {
    final MediaTransport transport;
    try {
      transport = await openTransport();
    } catch (e) {
      debugPrint('🎵 sem os controles de mídia: $e');
      return null;
    }
    if (!request.isOpen()) {
      await transport.close();
      return null;
    }
    return WindowsSession(
      playback: request.playback,
      settings: request.settings,
      transport: transport,
      keepAwake: (on) => _ask(() => system.keepAwake(on)),
    );
  }

  @override
  (int, String)? diskInfo(String path) =>
      _ask<(int, String)?>(() => system.diskInfo(path));

  /// O Windows não tem o modo de arquivo do Unix.
  @override
  void restoreFileMode(String path, int mode) {}

  @override
  FileProblem? fileProblem(int osError) => switch (osError) {
    19 => FileProblem.readOnlyDisk,
    5 || 1314 => FileProblem.noPermission,
    // Inclui o disco de rede que caiu e o OneDrive que não está rodando
    2 || 3 || 15 || 21 || 53 || 55 || 67 || 362 || 1167 => FileProblem.missing,
    39 || 112 || 1295 => FileProblem.noSpace,
    32 || 33 || 1224 => FileProblem.inUse,
    17 => FileProblem.otherDisk,
    _ => null,
  };

  @override
  bool get openFilesBlockReplace => true;

  @override
  bool get strictNames => true;

  @override
  bool samePath(String a, String b) => p.windows.equals(a, b);

  @override
  bool isCloudOnly(String path) =>
      _ask(() => system.isCloudOnly(path)) ?? false;

  /// A busca é por pasta, uma vez só, porque uma playlist repete as mesmas.
  @override
  List<String> realPaths(List<String> paths) {
    final listed = <String, Map<String, String>>{};
    Map<String, String> namesIn(String dir) => listed.putIfAbsent(dir, () {
      try {
        return {
          for (final name in system.listNames(dir)) name.toLowerCase(): name,
        };
      } on FileSystemException {
        return const {};
      }
    });

    String real(String path) {
      if (!p.windows.isAbsolute(path) || p.windows.rootPrefix(path) == r'') {
        return path;
      }
      final parts = p.windows.split(p.windows.normalize(path));
      var at = parts.first.length <= 3
          ? parts.first.toUpperCase()
          : parts.first;
      for (final part in parts.skip(1)) {
        at = p.windows.join(at, namesIn(at)[part.toLowerCase()] ?? part);
      }
      return at;
    }

    return [for (final path in paths) real(path)];
  }

  @override
  bool get watchesSubfolders => true;

  @override
  bool get showsTrackNotice => false;

  /// Uma resposta que não veio não impede de tocar.
  T? _ask<T>(T Function() call) {
    try {
      return call();
    } catch (e) {
      debugPrint('🎵 sem resposta do Windows: $e');
      return null;
    }
  }
}

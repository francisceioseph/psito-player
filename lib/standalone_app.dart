// lib/standalone_app.dart
//
// O player sozinho, num Linux qualquer: o tema, o idioma do sistema e os seletores
// de arquivo do GTK.
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/player_localizations.dart';
import 'player_app.dart';
import 'src/player/desktop_hooks.dart';

/// Os arquivos com que o player abriu: os caminhos absolutos e as URLs `file://`.
List<String> openedFiles(List<String> args) => [
  for (final arg in args)
    if (arg.startsWith('/'))
      arg
    else if (arg.startsWith('file://'))
      Uri.parse(arg).toFilePath(),
];

/// O canal do runner que traz a janela para a frente.
const _window = MethodChannel('psito_player/window');

Future<void> _raiseWindow() async {
  try {
    await _window.invokeMethod<void>('present');
  } on MissingPluginException catch (e) {
    debugPrint('🎵 sem o canal da janela: $e');
  }
}

Future<void> _resizeWindow(Size size, {bool keepAbove = false}) async {
  try {
    await _window.invokeMethod<void>('resize', {
      'width': size.width.round(),
      'height': size.height.round(),
      'above': keepAbove,
    });
  } on MissingPluginException catch (e) {
    debugPrint('🎵 sem o canal da janela: $e');
  }
}

Future<void> _openFolder(String path) async {
  final result = await Process.run('xdg-open', [path]);
  if (result.exitCode != 0) debugPrint('🎵 xdg-open: ${result.stderr}');
}

Future<bool> _revealFile(String path) async {
  final bus = sessionBus();
  try {
    return await showInFileManager(path, bus);
  } finally {
    await bus.close();
  }
}

class StandaloneApp extends StatelessWidget {
  final List<String> initialPaths;

  /// O que chega de outra instância.
  final Stream<List<String>>? openRequests;

  const StandaloneApp({
    super.key,
    this.initialPaths = const [],
    this.openRequests,
  });

  Color get color => const Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => PlayerLocalizations.of(context).appName,
    debugShowCheckedModeBanner: false,
    theme: playerBaseTheme(color),
    localizationsDelegates: PlayerLocalizations.localizationsDelegates,
    supportedLocales: PlayerLocalizations.supportedLocales,
    home: PlayerView(
      createEngine: MediaKitEngine.new,
      openLibrary: openLibraryServices,
      initialPaths: initialPaths,
      openRequests: openRequests,
      raiseWindow: _raiseWindow,
      resizeWindow: _resizeWindow,
      connectBus: sessionBus,
      openFolder: _openFolder,
      revealFile: _revealFile,
      musicDir: userMusicDir(Platform.environment),
      pickFolder: (_) => getDirectoryPath(),
      pickPlaylistFile: (_) async {
        final file = await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'M3U, XSPF, PLS',
              extensions: ['m3u', 'm3u8', 'xspf', 'pls'],
            ),
          ],
        );
        return file?.path;
      },
      pickImage: (_) async {
        final file = await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'JPEG, PNG, WebP',
              extensions: ['jpg', 'jpeg', 'png', 'webp'],
            ),
          ],
        );
        return file?.path;
      },
      pickSaveFile: (_, name) async =>
          (await getSaveLocation(suggestedName: name))?.path,
    ),
  );
}

// lib/standalone_app.dart
//
// O player sozinho, fora do Psito: o tema, o idioma do sistema e os seletores de
// arquivo nativos.
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'l10n/player_localizations.dart';
import 'player_app.dart';

/// Os arquivos com que o player abriu: os caminhos absolutos e as URLs `file://`.
/// [context] é o estilo de caminho do sistema, trocado só nos testes.
List<String> openedFiles(List<String> args, {p.Context? context}) {
  final paths = context ?? p.context;
  return [
    for (final arg in args)
      if (arg.startsWith('file://'))
        Uri.parse(arg).toFilePath(windows: paths.style == p.Style.windows)
      else if (paths.isAbsolute(arg))
        arg,
  ];
}

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
      openSession: desktopPlatform.openSession,
      openFolder: desktopPlatform.open,
      revealFile: desktopPlatform.reveal,
      musicDir: desktopPlatform.musicDir,
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

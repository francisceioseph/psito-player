// lib/src/ui/player_actions.dart
//
// O que os menus e os cartões precisam, em qualquer ponto da árvore, sem passar
// por todas as telas no caminho.
import 'package:flutter/widgets.dart';

import '../library/library_controller.dart';
import '../library/models.dart';
import '../player/playback_controller.dart';

class PlayerActions extends InheritedWidget {
  final LibraryController library;
  final PlaybackController playback;

  /// Grava as faixas num arquivo de playlist, pedindo o formato e onde.
  final Future<void> Function(String name, List<Track> tracks) exportPlaylist;

  /// Mostra o arquivo no gerenciador.
  final Future<void> Function(String path) revealFile;

  const PlayerActions({
    super.key,
    required this.library,
    required this.playback,
    required this.exportPlaylist,
    required this.revealFile,
    required super.child,
  });

  /// Null fora do player, como num teste de um widget sozinho.
  static PlayerActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerActions>();

  @override
  bool updateShouldNotify(PlayerActions old) =>
      library != old.library || playback != old.playback;
}

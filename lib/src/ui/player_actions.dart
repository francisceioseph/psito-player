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

  /// Grava as faixas num M3U, pedindo onde.
  final Future<void> Function(String name, List<Track> tracks) exportPlaylist;

  const PlayerActions({
    super.key,
    required this.library,
    required this.playback,
    required this.exportPlaylist,
    required super.child,
  });

  /// Null fora do player, como num teste de um widget sozinho.
  static PlayerActions? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerActions>();

  @override
  bool updateShouldNotify(PlayerActions old) =>
      library != old.library || playback != old.playback;
}

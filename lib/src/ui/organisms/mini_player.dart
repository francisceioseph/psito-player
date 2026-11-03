// lib/src/ui/organisms/mini_player.dart
//
// O miniplayer: a capa e os controles, numa janelinha que fica por cima das outras.
// Sem altura para a capa, ficam só os controles.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../player/playback_controller.dart';
import '../atoms/cover_art.dart';
import '../format.dart';
import '../molecules/transport_controls.dart';

class MiniPlayer extends StatelessWidget {
  /// Abaixo disto, a capa sai.
  static const artMinHeight = 200.0;

  final PlaybackController playback;
  final VoidCallback onExit;

  const MiniPlayer({super.key, required this.playback, required this.onExit});

  Widget _art(BuildContext context) {
    final l = context.l10n;
    final track = playback.current;
    final label = track == null
        ? l.noTrack
        : '${track.title}, ${artistName(track.artist, context)}';
    return Semantics(
      image: true,
      label: label,
      child: Tooltip(
        message: label,
        child: CoverArt(
          path: track?.coverPath,
          seed: track == null ? 'Psito' : '${track.album}|${track.artist}',
          radius: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [
        if (constraints.maxHeight >= artMinHeight)
          Expanded(child: _art(context))
        else
          const Spacer(),
        ValueListenableBuilder(
          valueListenable: playback.engine.state,
          builder: (context, s, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TransportControls(
                    playback: playback,
                    state: s,
                    toggles: false,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.exitMini,
                icon: const Icon(Icons.open_in_full_rounded),
                onPressed: onExit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    ),
  );
}

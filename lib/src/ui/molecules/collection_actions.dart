// lib/src/ui/molecules/collection_actions.dart
//
// Tocar, Aleatório e pôr na fila, de qualquer coleção de faixas.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../../player/playback_controller.dart';
import '../player_actions.dart';
import 'track_menu.dart';

class CollectionActions extends StatelessWidget {
  final PlaybackController playback;
  final List<Track> tracks;

  /// Botões com nome, ao lado de Tocar e Aleatório.
  final List<Widget> primary;

  /// Botões só com ícone, no fim, como o menu de uma playlist.
  final List<Widget> extra;

  const CollectionActions({
    super.key,
    required this.playback,
    required this.tracks,
    this.primary = const [],
    this.extra = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final any = tracks.isNotEmpty;
    final actions = PlayerActions.maybeOf(context);
    // Em dois grupos, que quebram de linha inteiros: o que tem nome e os ícones
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: any
                  ? () => unawaited(playback.playTracks(tracks))
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.play),
            ),
            FilledButton.tonalIcon(
              onPressed: any
                  ? () => unawaited(playback.shuffleTracks(tracks))
                  : null,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(l.shuffle),
            ),
            ...primary,
          ],
        ),
        Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l.addToQueue,
              icon: const Icon(Icons.queue_music_rounded),
              onPressed: any
                  ? () => unawaited(playback.tracksToQueue(tracks))
                  : null,
            ),
            if (actions != null)
              IconButton(
                tooltip: l.addToPlaylist,
                icon: const Icon(Icons.playlist_add_rounded),
                onPressed: any
                    ? () => unawaited(
                        showAddToPlaylist(context, actions.library, [
                          for (final t in tracks) t.path,
                        ]),
                      )
                    : null,
              ),
            ...extra,
          ],
        ),
      ],
    );
  }
}

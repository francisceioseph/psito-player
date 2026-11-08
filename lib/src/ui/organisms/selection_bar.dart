// lib/src/ui/organisms/selection_bar.dart
//
// A barra das faixas marcadas: quantas são, e o que dá para fazer com todas.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../molecules/track_menu.dart';
import '../player_actions.dart';
import '../track_selection.dart';
import 'tag_batch_dialog.dart';

class SelectionBar extends StatelessWidget {
  /// Abaixo desta largura, só os ícones.
  static const labelsMinWidth = 720.0;

  final TrackSelection selection;
  final PlayerActions actions;

  const SelectionBar({
    super.key,
    required this.selection,
    required this.actions,
  });

  Future<void> _play() async {
    await actions.playback.playTracks(selection.tracks);
    selection.clear();
  }

  Future<void> _add(BuildContext context) async {
    await showAddToPlaylist(context, actions.library, [
      for (final t in selection.tracks) t.path,
    ]);
    selection.clear();
  }

  Future<void> _skip() async {
    for (final track in selection.tracks.where((t) => !t.skip)) {
      await actions.playback.setSkip(track, true);
    }
    selection.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final labels = constraints.maxWidth >= labelsMinWidth;
        Widget button(IconData icon, String label, VoidCallback onPressed) =>
            labels
            ? TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              )
            : IconButton(
                tooltip: label,
                onPressed: onPressed,
                icon: Icon(icon),
              );
        return Material(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: l.selectionClear,
                  onPressed: selection.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    l.selectionCount(selection.count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                button(
                  Icons.play_arrow_rounded,
                  l.play,
                  () => unawaited(_play()),
                ),
                button(
                  Icons.playlist_add_rounded,
                  l.addToPlaylist,
                  () => unawaited(_add(context)),
                ),
                button(
                  Icons.not_interested_rounded,
                  l.skipTrack,
                  () => unawaited(_skip()),
                ),
                button(
                  Icons.edit_rounded,
                  l.tagEditTitle,
                  () => unawaited(
                    showBatchTagEditor(context, actions, selection.tracks),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

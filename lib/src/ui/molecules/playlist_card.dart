// lib/src/ui/molecules/playlist_card.dart
//
// Uma playlist numa grade: o mosaico ou, nas automáticas, o ícone.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../atoms/mosaic_cover.dart';
import '../format.dart';
import '../player_actions.dart';
import 'album_card.dart';
import 'collection_menu.dart';
import 'playable_card.dart';

/// O desenho das automáticas, que não têm capa própria.
class PlaylistIcon extends StatelessWidget {
  final PlaylistKind kind;
  final double? size;

  const PlaylistIcon({super.key, required this.kind, this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (kind) {
      PlaylistKind.mostPlayed => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.trending_up_rounded,
      ),
      PlaylistKind.recentlyAdded => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.schedule_rounded,
      ),
      PlaylistKind.topRated => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.star_rounded,
      ),
      _ => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.favorite_rounded,
      ),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: foreground, size: 36),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onOpen;

  const PlaylistCard({super.key, required this.playlist, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final name = playlistName(playlist, context);
    final facts = playlist.automatic
        ? '${l.trackCount(playlist.trackCount)} · ${l.automaticSuffix}'
        : '${l.trackCount(playlist.trackCount)} · '
              '${formatLength(playlist.duration, context)}';
    final actions = PlayerActions.maybeOf(context);
    return PlayableCard(
      label: name,
      onOpen: onOpen,
      onPlay: actions == null || playlist.trackCount == 0
          ? null
          : () => playLoaded(actions, () => actions.library.tracksOf(playlist)),
      playTooltip: l.playAlbum(name),
      pinned:
          !playlist.automatic &&
          (actions?.library.isPinned(PinKind.playlist, playlist.id) ?? false),
      menu: actions == null
          ? null
          : (context) => playlistMenu(context, actions, playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox.expand(
              child: playlist.automatic && !playlist.mix
                  ? PlaylistIcon(kind: playlist.kind)
                  : MosaicCover(covers: playlist.covers, seed: name),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            facts,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

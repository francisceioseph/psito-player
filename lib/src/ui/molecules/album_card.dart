// lib/src/ui/molecules/album_card.dart
//
// Um álbum numa grade: capa, título e artista.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../atoms/cover_art.dart';
import '../format.dart';
import '../player_actions.dart';
import 'collection_menu.dart';
import 'playable_card.dart';

class AlbumCard extends StatelessWidget {
  static const textHeight = PlayableCard.textHeight;

  final Album album;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onOpen,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final artist = artistName(album.artist, context);
    final detail = album.year == null ? artist : '$artist · ${album.year}';
    final actions = PlayerActions.maybeOf(context);
    return PlayableCard(
      label: '${album.title}, $artist',
      onOpen: onOpen,
      onPlay: onPlay,
      playTooltip: l.playAlbum(album.title),
      menu: actions == null
          ? null
          : (context) => albumMenu(context, actions, album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CoverArt(
              path: album.coverPath,
              seed: '${album.title}|${album.artist}',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
          Text(
            detail,
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

List<PopupMenuEntry<VoidCallback>> albumMenu(
  BuildContext context,
  PlayerActions actions,
  Album album,
) => collectionMenu(
  context,
  actions,
  () => actions.library.store.albumTracks(album.id),
);

/// Toca um grupo de faixas que ainda precisa vir do banco.
void playLoaded(PlayerActions actions, Future<List<Track>> Function() load) =>
    unawaited(() async {
      await actions.playback.playTracks(await load());
    }());

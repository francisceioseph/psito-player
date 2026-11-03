// lib/src/ui/molecules/artist_card.dart
//
// Um artista numa grade: o monograma, o nome e o que há dele.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../atoms/monogram.dart';
import '../format.dart';
import '../player_actions.dart';
import 'album_card.dart';
import 'collection_menu.dart';
import 'playable_card.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onOpen;

  const ArtistCard({super.key, required this.artist, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final name = artistName(artist.name, context);
    final actions = PlayerActions.maybeOf(context);
    Future<List<Track>> load() =>
        actions!.library.store.tracks(TrackQuery(artistId: artist.id));
    return PlayableCard(
      label: name,
      onOpen: onOpen,
      onPlay: actions == null ? null : () => playLoaded(actions, load),
      playTooltip: l.playAlbum(name),
      menu: actions == null
          ? null
          : (context) => collectionMenu(context, actions, load),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(aspectRatio: 1, child: Monogram(name: name)),
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
            '${l.albumCount(artist.albums)} · ${l.trackCount(artist.tracks)}',
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

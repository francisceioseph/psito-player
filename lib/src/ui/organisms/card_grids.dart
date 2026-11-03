// lib/src/ui/organisms/card_grids.dart
//
// As grades de artistas, playlists e gêneros, na mesma medida da de álbuns.
import 'package:flutter/material.dart';

import '../../library/models.dart';
import '../molecules/album_card.dart';
import '../molecules/artist_card.dart';
import '../molecules/genre_card.dart';
import '../molecules/playlist_card.dart';
import 'album_grid.dart';

class ArtistGrid extends StatelessWidget {
  final List<Artist> artists;
  final ValueChanged<Artist> onOpen;
  final bool singleRow;

  const ArtistGrid({
    super.key,
    required this.artists,
    required this.onOpen,
    this.singleRow = false,
  });

  @override
  Widget build(BuildContext context) =>
      singleRow ? singleRowOf(artists.length, _grid) : _grid(artists.length);

  Widget _grid(int count) => SliverGrid.builder(
    gridDelegate: const CardGridDelegate(AlbumCard.textHeight),
    itemCount: count,
    itemBuilder: (context, i) => ArtistCard(
      key: ValueKey(artists[i].id),
      artist: artists[i],
      onOpen: () => onOpen(artists[i]),
    ),
  );
}

class PlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final ValueChanged<Playlist> onOpen;
  final bool singleRow;

  const PlaylistGrid({
    super.key,
    required this.playlists,
    required this.onOpen,
    this.singleRow = false,
  });

  @override
  Widget build(BuildContext context) => singleRow
      ? singleRowOf(playlists.length, _grid)
      : _grid(playlists.length);

  Widget _grid(int count) => SliverGrid.builder(
    gridDelegate: const CardGridDelegate(AlbumCard.textHeight),
    itemCount: count,
    itemBuilder: (context, i) => PlaylistCard(
      key: ValueKey(
        '${playlists[i].kind.name}${playlists[i].id}${playlists[i].name}',
      ),
      playlist: playlists[i],
      onOpen: () => onOpen(playlists[i]),
    ),
  );
}

/// O que foi fixado, de qualquer tipo, na medida das outras grades.
class PinnedGrid extends StatelessWidget {
  final List<Object> items;
  final ValueChanged<Object> onOpen;
  final ValueChanged<Album> onPlayAlbum;
  final bool singleRow;

  const PinnedGrid({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onPlayAlbum,
    this.singleRow = false,
  });

  Widget _item(Object item) => switch (item) {
    final Album album => AlbumCard(
      key: ValueKey('album ${album.id}'),
      album: album,
      onOpen: () => onOpen(album),
      onPlay: () => onPlayAlbum(album),
    ),
    final Artist artist => ArtistCard(
      key: ValueKey('artist ${artist.id}'),
      artist: artist,
      onOpen: () => onOpen(artist),
    ),
    final Playlist playlist => PlaylistCard(
      key: ValueKey('playlist ${playlist.id}'),
      playlist: playlist,
      onOpen: () => onOpen(playlist),
    ),
    _ => throw ArgumentError.value(item),
  };

  Widget _grid(int count) => SliverGrid.builder(
    gridDelegate: const CardGridDelegate(AlbumCard.textHeight),
    itemCount: count,
    itemBuilder: (context, i) => _item(items[i]),
  );

  @override
  Widget build(BuildContext context) =>
      singleRow ? singleRowOf(items.length, _grid) : _grid(items.length);
}

class GenreGrid extends StatelessWidget {
  final List<Genre> genres;
  final ValueChanged<Genre> onOpen;

  const GenreGrid({super.key, required this.genres, required this.onOpen});

  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 280,
      mainAxisExtent: 96,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    ),
    itemCount: genres.length,
    itemBuilder: (context, i) => GenreCard(
      key: ValueKey(genres[i].name),
      genre: genres[i],
      onOpen: () => onOpen(genres[i]),
    ),
  );
}

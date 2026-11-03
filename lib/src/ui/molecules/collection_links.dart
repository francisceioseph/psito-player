// lib/src/ui/molecules/collection_links.dart
//
// Os gêneros e os artistas das faixas de uma coleção, em chips que levam às telas
// deles.
import 'package:flutter/material.dart';

import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../atoms/monogram.dart';
import '../format.dart';

class CollectionLinks extends StatelessWidget {
  static const maxGenres = 4;
  static const maxArtists = 4;

  final List<Track> tracks;
  final LibraryController library;
  final ValueChanged<Object> onOpen;
  final bool showArtists;
  final bool showGenres;

  /// O artista que a tela já mostra, para não repetir.
  final String? exceptArtist;

  const CollectionLinks({
    super.key,
    required this.tracks,
    required this.library,
    required this.onOpen,
    this.showArtists = true,
    this.showGenres = true,
    this.exceptArtist,
  });

  /// Os valores que mais aparecem, sem os vazios.
  static List<String> _top(Iterable<String> values, int limit) {
    final counts = <String, int>{};
    for (final value in values) {
      if (value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final names = counts.keys.toList()..sort((a, b) => counts[b]! - counts[a]!);
    return names.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final genres = showGenres
        ? _top(tracks.map((t) => t.genre?.trim() ?? ''), maxGenres)
        : const <String>[];
    final artists = showArtists
        ? [
            for (final name in _top(
              tracks.map((t) => t.artist).where((a) => a != exceptArtist),
              maxArtists,
            ))
              ...library.artists.where((artist) => artist.name == name),
          ]
        : const <Artist>[];
    if (genres.isEmpty && artists.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final artist in artists)
            ActionChip(
              mouseCursor: WidgetStateMouseCursor.clickable,
              avatar: Monogram(name: artistName(artist.name, context)),
              label: Text(artistName(artist.name, context)),
              onPressed: () => onOpen(artist),
            ),
          for (final genre in genres)
            ActionChip(
              mouseCursor: WidgetStateMouseCursor.clickable,
              label: Text(genre),
              onPressed: () => onOpen(Genre(name: genre)),
            ),
        ],
      ),
    );
  }
}

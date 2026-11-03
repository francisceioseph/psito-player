// lib/src/ui/pages/tracks_page.dart
//
// As faixas de um artista, de um gênero ou de uma pasta. As três diferem só na arte
// e na consulta.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../player/playback_controller.dart';
import '../format.dart';
import '../molecules/collection_actions.dart';
import '../molecules/chip_bar.dart';
import '../molecules/collection_links.dart';
import '../molecules/track_filter.dart';
import '../molecules/section_heading.dart';
import '../organisms/album_grid.dart';
import '../organisms/track_list.dart';
import '../templates/collection_template.dart';

enum _ArtistTab { overview, albums, songs }

class TracksPage extends StatefulWidget {
  /// Quantas faixas cada grupo mostra na visão geral do artista.
  static const overviewTracks = 5;

  final String title;
  final Widget art;
  final TrackQuery query;
  final LibraryController library;
  final PlaybackController playback;
  final VoidCallback onBack;
  final ValueChanged<Album> onOpenAlbum;

  /// Abre um artista ou um gênero, dos chips.
  final ValueChanged<Object> onOpen;

  const TracksPage({
    super.key,
    required this.title,
    required this.art,
    required this.query,
    required this.library,
    required this.playback,
    required this.onBack,
    required this.onOpenAlbum,
    required this.onOpen,
  });

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> with TrackFilter {
  List<Track> _tracks = const [];
  List<Album> _albums = const [];
  int _revision = -1;
  _ArtistTab _tab = _ArtistTab.overview;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(TracksPage old) {
    super.didUpdateWidget(old);
    if (_revision != widget.library.revision) unawaited(_load());
  }

  Future<void> _load() async {
    final store = widget.library.store;
    _revision = widget.library.revision;
    final artist = widget.query.artistId;
    final (tracks, albums) = await (
      store.tracks(widget.query),
      artist == null
          ? Future.value(const <Album>[])
          : store.artistAlbums(artist),
    ).wait;
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _albums = albums;
    });
  }

  Widget _list(List<Track> tracks) => TrackList(
    tracks: tracks,
    library: widget.library,
    playback: widget.playback,
    columns: true,
  );

  void _playAlbum(Album album) =>
      unawaited(widget.playback.playAlbum(album.id));

  /// O artista, por partes: o que você mais ouve e um pouco de cada coisa, os
  /// álbuns inteiros, ou as músicas inteiras.
  List<Widget> _artist(BuildContext context) {
    final l = context.l10n;
    final played = _tracks.where((t) => t.playCount > 0).toList()
      ..sort((a, b) => b.playCount - a.playCount);
    Widget seeAll(_ArtistTab tab) => TextButton(
      onPressed: () => setState(() => _tab = tab),
      child: Text(l.seeAll),
    );
    return [
      SliverToBoxAdapter(
        child: ChipBar<_ArtistTab>(
          options: [
            (_ArtistTab.overview, l.overview),
            (_ArtistTab.albums, l.albums),
            (_ArtistTab.songs, l.songs),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
        ),
      ),
      ...switch (_tab) {
        _ArtistTab.overview => [
          if (played.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeading(l.mostPlayed)),
            _list(played.take(TracksPage.overviewTracks).toList()),
          ],
          if (_albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeading(
                l.albums,
                action: seeAll(_ArtistTab.albums),
              ),
            ),
            AlbumGrid(
              singleRow: true,
              albums: _albums,
              onOpen: widget.onOpenAlbum,
              onPlay: _playAlbum,
            ),
          ],
          SliverToBoxAdapter(
            child: SectionHeading(l.songs, action: seeAll(_ArtistTab.songs)),
          ),
          _list(_tracks.take(TracksPage.overviewTracks).toList()),
        ],
        _ArtistTab.albums => [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          AlbumList(
            albums: _albums,
            onOpen: widget.onOpenAlbum,
            onPlay: _playAlbum,
          ),
        ],
        _ArtistTab.songs => [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _list(_tracks),
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final total = _tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    return CollectionTemplate(
      title: widget.title,
      onBack: widget.onBack,
      art: widget.art,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (_albums.isNotEmpty) l.albumCount(_albums.length),
              l.trackCount(_tracks.length),
              formatLength(total, context),
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
          CollectionLinks(
            tracks: _tracks,
            library: widget.library,
            onOpen: widget.onOpen,
            showArtists: widget.query.artistId == null,
            showGenres: widget.query.genre == null,
          ),
          const SizedBox(height: 12),
          CollectionActions(
            playback: widget.playback,
            tracks: _tracks,
            extra: [filterButton(context)],
          ),
        ],
      ),
      slivers: [
        ...filterSlivers(context, _tracks),
        ...widget.query.artistId != null && !filterActive
            ? _artist(context)
            : [_list(filtered(_tracks))],
      ],
    );
  }
}

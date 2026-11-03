// lib/src/ui/pages/home_page.dart
//
// O Início: o destaque, e fileiras do que já está na biblioteca.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../player/playback_controller.dart';
import '../molecules/section_heading.dart';
import '../organisms/album_grid.dart';
import '../organisms/card_grids.dart';
import '../organisms/continue_card.dart';
import '../organisms/track_list.dart';
import '../templates/page_template.dart';
import '../atoms/toggle_icon_button.dart';

class HomePage extends StatefulWidget {
  static const mostPlayedLimit = 6;

  final LibraryController library;
  final PlaybackController playback;

  /// Abre um álbum, um artista ou uma playlist.
  final ValueChanged<Object> onOpen;
  final ValueChanged<LibrarySection> onSeeLibrary;
  final VoidCallback onSeePlaylists;

  const HomePage({
    super.key,
    required this.library,
    required this.playback,
    required this.onOpen,
    required this.onSeeLibrary,
    required this.onSeePlaylists,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _shelf = 12;

  int _revision = -1;
  var _rediscover = const <Album>[];
  var _artists = const <Artist>[];

  /// Só recalcula quando a biblioteca muda: a tela refaz a cada faixa.
  void _refresh() {
    final library = widget.library;
    if (_revision == library.revision) return;
    _revision = library.revision;
    final recent = {for (final a in library.recent) a.id};
    // A mesma sugestão durante o dia, em vez de mudar a cada volta à tela
    final today = DateTime.now().difference(DateTime(2000)).inDays;
    _rediscover =
        (library.fullAlbums.where((a) => !recent.contains(a.id)).toList()
              ..shuffle(Random(today)))
            .take(_shelf)
            .toList();
    _artists = (List.of(
      library.artists,
    )..sort((a, b) => b.tracks - a.tracks)).take(_shelf).toList();
  }

  void _playAlbum(Album album) =>
      unawaited(widget.playback.playAlbum(album.id));

  @override
  Widget build(BuildContext context) {
    _refresh();
    final l = context.l10n;
    final library = widget.library;
    final playback = widget.playback;
    final playlists = [
      ...library.playlists,
      ...library.autoPlaylists.where((p) => p.trackCount > 0),
    ];
    Widget seeAll(VoidCallback onPressed) =>
        TextButton(onPressed: onPressed, child: Text(l.seeAll));
    return PageTemplate(
      title: l.home,
      slivers: [
        SliverToBoxAdapter(
          child: ValueListenableBuilder(
            valueListenable: playback.engine.state,
            builder: (context, s, _) => ContinueCard(
              track: playback.current,
              resumable: playback.resumable,
              playing: s.playing,
              position: s.position,
              totals: library.totals,
              albums: library.recent,
              onContinue: () => unawaited(playback.togglePlay()),
              onShuffleAll: () => unawaited(playback.shuffleAll()),
            ),
          ),
        ),
        if (library.pinned.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeading(l.pinnedHeading)),
          PinnedGrid(
            singleRow: true,
            items: library.pinned,
            onOpen: widget.onOpen,
            onPlayAlbum: _playAlbum,
          ),
        ],
        if (library.mixes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              l.yourMixes,
              action: ListenableBuilder(
                listenable: playback,
                builder: (context, _) => ToggleIconButton(
                  tooltip: playback.dynamicMix
                      ? l.dynamicMixStop
                      : l.dynamicMixStart,
                  on: playback.dynamicMix,
                  icon: Icons.all_inclusive_rounded,
                  onPressed: () =>
                      unawaited(playback.setDynamicMix(!playback.dynamicMix)),
                ),
              ),
            ),
          ),
          PlaylistGrid(
            singleRow: true,
            playlists: library.mixes,
            onOpen: widget.onOpen,
          ),
        ],
        if (library.recent.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              l.recentlyAdded,
              action: seeAll(() => widget.onSeeLibrary(LibrarySection.albums)),
            ),
          ),
          AlbumGrid(
            singleRow: true,
            albums: library.recent,
            onOpen: widget.onOpen,
            onPlay: _playAlbum,
          ),
        ],
        if (library.mostPlayed.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeading(l.mostPlayed)),
          TrackList(
            grid: true,
            tracks: library.mostPlayed.take(HomePage.mostPlayedLimit).toList(),
            library: library,
            playback: playback,
          ),
        ],
        if (playlists.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              l.yourPlaylists,
              action: seeAll(widget.onSeePlaylists),
            ),
          ),
          PlaylistGrid(
            singleRow: true,
            playlists: playlists,
            onOpen: widget.onOpen,
          ),
        ],
        if (_artists.length > 1) ...[
          SliverToBoxAdapter(
            child: SectionHeading(
              l.artists,
              action: seeAll(() => widget.onSeeLibrary(LibrarySection.artists)),
            ),
          ),
          ArtistGrid(singleRow: true, artists: _artists, onOpen: widget.onOpen),
        ],
        if (_rediscover.isNotEmpty) ...[
          SliverToBoxAdapter(child: SectionHeading(l.rediscover)),
          AlbumGrid(
            singleRow: true,
            albums: _rediscover,
            onOpen: widget.onOpen,
            onPlay: _playAlbum,
          ),
        ],
      ],
    );
  }
}

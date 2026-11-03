// lib/src/ui/pages/playlist_page.dart
//
// Uma playlist. A da pessoa se reordena arrastando ou pelo menu, para quem não
// arrasta, e pode trazer arquivos que não estão na biblioteca.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../player/playback_controller.dart';
import '../atoms/cover_art.dart';
import '../atoms/empty_note.dart';
import '../atoms/mosaic_cover.dart';
import '../format.dart';
import '../molecules/collection_actions.dart';
import '../molecules/collection_links.dart';
import '../molecules/collection_menu.dart';
import '../molecules/track_filter.dart';
import '../organisms/add_tracks_dialog.dart';
import '../molecules/playlist_card.dart';
import '../molecules/track_menu.dart';
import '../molecules/track_row.dart';
import '../organisms/track_list.dart';
import '../templates/collection_template.dart';

class PlaylistPage extends StatefulWidget {
  final Playlist playlist;
  final LibraryController library;
  final PlaybackController playback;
  final VoidCallback onBack;

  /// Abre um artista ou um gênero, dos chips.
  final ValueChanged<Object> onOpen;
  final Future<void> Function(String title, List<Track> tracks) onExport;

  const PlaylistPage({
    super.key,
    required this.playlist,
    required this.library,
    required this.playback,
    required this.onBack,
    required this.onOpen,
    required this.onExport,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> with TrackFilter {
  List<Track> _tracks = const [];
  Set<String> _absent = const {};
  int _revision = -1;

  /// O que o banco tem agora: o nome e a contagem mudam com a tela aberta.
  Playlist get _playlist {
    final original = widget.playlist;
    final library = widget.library;
    final list = switch (original) {
      Playlist(mix: true) => library.mixes.where(
        (p) => p.kind == original.kind && p.name == original.name,
      ),
      Playlist(automatic: true) => library.autoPlaylists.where(
        (p) => p.kind == original.kind,
      ),
      _ => library.playlists.where((p) => p.id == original.id),
    };
    return list.firstOrNull ?? original;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(PlaylistPage old) {
    super.didUpdateWidget(old);
    if (_revision != widget.library.revision) unawaited(_load());
  }

  Future<void> _load() async {
    _revision = widget.library.revision;
    final tracks = await widget.library.tracksOf(widget.playlist);
    // A biblioteca responde pelas dela, e o resto veio de um M3U
    final absent = <String>{};
    for (final track in tracks) {
      if (track.id == 0 && !File(track.path).existsSync()) {
        absent.add(track.path);
      }
    }
    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _absent = absent;
    });
  }

  bool _isMissing(Track track) =>
      _absent.contains(track.path) || widget.library.isMissing(track.path);

  Future<void> _rename() => renamePlaylist(context, widget.library, _playlist);

  Future<void> _delete() async {
    if (await deletePlaylist(context, widget.library, _playlist)) {
      widget.onBack();
    }
  }

  Future<void> _addTracks() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final paths = await showAddTracks(
      context,
      widget.library,
      existing: {for (final t in _tracks) t.path},
    );
    if (paths == null || paths.isEmpty) return;
    await widget.library.addToPlaylist(_playlist.id, paths);
    messenger?.showSnackBar(
      SnackBar(content: Text(l.tracksAdded(paths.length))),
    );
  }

  void _move(int from, int to) {
    setState(() {
      final tracks = List.of(_tracks);
      tracks.insert(to, tracks.removeAt(from));
      _tracks = tracks;
    });
    unawaited(widget.library.movePlaylistTrack(_playlist, from, to));
  }

  void _remove(int index) {
    setState(() => _tracks = List.of(_tracks)..removeAt(index));
    unawaited(widget.library.removeFromPlaylist(_playlist, index));
  }

  Widget _menu(BuildContext context) {
    final l = context.l10n;
    final playlist = _playlist;
    final name = playlistName(playlist, context);
    return PopupMenuButton<VoidCallback>(
      tooltip: l.moreOptions,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (!playlist.automatic)
          PopupMenuItem(
            value: () => unawaited(_rename()),
            child: Text(l.renamePlaylist),
          ),
        PopupMenuItem(
          value: () => unawaited(widget.onExport(name, _tracks)),
          child: Text(l.exportM3u),
        ),
        if (!playlist.automatic)
          PopupMenuItem(
            value: () => unawaited(_delete()),
            child: Text(l.deletePlaylist),
          ),
      ],
    );
  }

  Widget _reorderable(BuildContext context) {
    final l = context.l10n;
    final library = widget.library;
    final playback = widget.playback;
    final current = playback.current?.path;
    return SliverReorderableList(
      itemExtent: TrackRow.extentOf(context),
      itemCount: _tracks.length,
      onReorderItem: _move,
      itemBuilder: (context, i) {
        final track = _tracks[i];
        return TrackRow(
          // A mesma faixa pode entrar duas vezes
          key: ValueKey('$i ${track.path}'),
          track: track,
          current: track.path == current,
          missing: _isMissing(track),
          leading: CoverArt(
            path: track.coverPath,
            seed: '${track.album}|${track.artist}',
            size: 40,
            radius: 8,
          ),
          onFavorite: track.id == 0
              ? null
              : (value) => unawaited(playback.setFavorite(track, value)),
          menu: (context) => [
            ...trackMenu(context, library, playback, track),
            const PopupMenuDivider(),
            if (i > 0)
              PopupMenuItem(
                value: () => _move(i, i - 1),
                child: Text(l.moveUp),
              ),
            if (i < _tracks.length - 1)
              PopupMenuItem(
                value: () => _move(i, i + 1),
                child: Text(l.moveDown),
              ),
            PopupMenuItem(
              value: () => _remove(i),
              child: Text(l.removeFromPlaylist),
            ),
          ],
          trailing: ReorderableDragStartListener(
            index: i,
            child: Tooltip(
              message: l.dragToReorder,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_indicator_rounded),
                ),
              ),
            ),
          ),
          onTap: () => unawaited(playback.playChosen(_tracks, i)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final playlist = _playlist;
    final name = playlistName(playlist, context);
    final total = _tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    return CollectionTemplate(
      title: name,
      onBack: widget.onBack,
      tint: playlist.covers.map((cover) => cover.path).nonNulls.firstOrNull,
      art: playlist.automatic && !playlist.mix
          ? PlaylistIcon(kind: playlist.kind)
          : MosaicCover(covers: playlist.covers, seed: name),
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.trackCount(_tracks.length)} · ${formatLength(total, context)}',
            style: theme.textTheme.bodySmall,
          ),
          CollectionLinks(
            tracks: _tracks,
            library: widget.library,
            onOpen: widget.onOpen,
          ),
          const SizedBox(height: 12),
          CollectionActions(
            playback: widget.playback,
            tracks: _tracks,
            extra: [
              if (!playlist.automatic)
                FilledButton.tonalIcon(
                  onPressed: () => unawaited(_addTracks()),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.addTracks),
                ),
              filterButton(context),
              _menu(context),
            ],
          ),
        ],
      ),
      slivers: [
        ...filterSlivers(context, _tracks),
        if (_tracks.isEmpty)
          SliverToBoxAdapter(
            child: EmptyNote(
              playlist.automatic ? l.nothingHere : l.playlistEmptyHint,
            ),
          )
        // Filtrada, os índices não são os da playlist: nada de reordenar
        else if (playlist.automatic || filterActive)
          TrackList(
            tracks: filtered(_tracks),
            library: widget.library,
            playback: widget.playback,
            isMissing: _isMissing,
          )
        else
          _reorderable(context),
      ],
    );
  }
}

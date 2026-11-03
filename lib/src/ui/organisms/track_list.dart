// lib/src/ui/organisms/track_list.dart
//
// Uma lista de faixas de qualquer tamanho: virtualizada e com a altura fixa, que
// deixa rolar 50 mil linhas sem medir nenhuma.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../player/playback_controller.dart';
import '../atoms/cover_art.dart';
import '../molecules/track_menu.dart';
import '../molecules/track_row.dart';

class TrackList extends StatelessWidget {
  final List<Track> tracks;
  final LibraryController library;
  final PlaybackController playback;

  /// O número da faixa no lugar da capa, como num álbum.
  final bool numbered;

  /// As colunas da lista de músicas.
  final bool columns;

  /// Em colunas, quando a largura dá, como no Início.
  final bool grid;

  /// Quais não dá para tocar. Sem isso, as da pasta que não está lá.
  final bool Function(Track track)? isMissing;

  const TrackList({
    super.key,
    required this.tracks,
    required this.library,
    required this.playback,
    this.numbered = false,
    this.columns = false,
    this.grid = false,
    this.isMissing,
  });

  @override
  Widget build(BuildContext context) {
    final current = playback.current?.path;
    Widget row(BuildContext context, int i) {
      final track = tracks[i];
      final playing = track.path == current;
      final missing = isMissing?.call(track) ?? library.isMissing(track.path);
      return TrackRow(
        track: track,
        current: playing,
        columns: columns,
        missing: missing,
        // Num álbum, o número da faixa já está no começo. Em colunas, no Início,
        // ela continuaria de uma coluna para a outra
        number: numbered || grid ? null : i + 1,
        leading: numbered
            ? (playing
                  ? const Icon(Icons.equalizer_rounded)
                  : Text('${track.trackNumber ?? i + 1}'))
            : CoverArt(
                path: track.coverPath,
                seed: '${track.album}|${track.artist}',
                size: 40,
                radius: 8,
              ),
        menu: (context) => trackMenu(context, library, playback, track),
        onFavorite: track.id == 0
            ? null
            : (value) => unawaited(playback.setFavorite(track, value)),
        onTap: () => unawaited(playback.playChosen(tracks, i)),
      );
    }

    final extent = TrackRow.extentOf(context);
    return grid
        ? SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 520,
              mainAxisExtent: extent,
              crossAxisSpacing: 16,
            ),
            itemCount: tracks.length,
            itemBuilder: row,
          )
        : SliverFixedExtentList.builder(
            itemExtent: extent,
            itemCount: tracks.length,
            itemBuilder: row,
          );
  }
}

// lib/src/ui/pages/track_page.dart
//
// A tela da música: a capa e os dados de um lado e, do outro, a letra grande, os
// detalhes do arquivo e a fila. O painel lateral é a versão de bolso disto.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_store.dart';
import '../../library/models.dart';
import '../../lyrics/lyrics_controller.dart';
import '../../player/playback_controller.dart';
import '../atoms/cover_art.dart';
import '../atoms/cover_tint.dart';
import '../atoms/favorite_button.dart';
import '../format.dart';
import '../molecules/panel_tabs.dart';
import '../molecules/track_menu.dart';
import '../organisms/cover_panel.dart';
import '../organisms/lyrics_view.dart';
import '../organisms/queue_panel.dart';
import '../player_actions.dart';

class TrackPage extends StatelessWidget {
  /// A partir daqui, a capa fica ao lado das abas.
  static const sideMinWidth = 720.0;
  static const artWidth = 340.0;

  /// A letra aqui tem espaço: bem maior que no painel.
  static const lyricsScale = 1.4;

  final PlaybackController playback;
  final LyricsController lyrics;
  final LibraryStore store;
  final PanelTab tab;
  final ValueChanged<PanelTab> onTab;
  final VoidCallback onBack;
  final ValueChanged<List<String>> onSaveQueue;

  const TrackPage({
    super.key,
    required this.playback,
    required this.lyrics,
    required this.store,
    required this.tab,
    required this.onTab,
    required this.onBack,
    required this.onSaveQueue,
  });

  Widget _about(BuildContext context, Track track) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final actions = PlayerActions.maybeOf(context);
    final album = [
      if (track.album.isNotEmpty) track.album,
      if (track.year != null) '${track.year}',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          artistName(track.artist, context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (album.isNotEmpty)
          Text(
            album,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (track.id != 0 || actions != null) ...[
          const SizedBox(height: 8),
          Row(
            spacing: 4,
            children: [
              if (track.id != 0)
                FavoriteButton(
                  favorite: track.favorite,
                  size: 24,
                  onChanged: (value) =>
                      unawaited(playback.setFavorite(track, value)),
                ),
              if (actions != null)
                PopupMenuButton<VoidCallback>(
                  tooltip: l.moreOptions,
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) => action(),
                  itemBuilder: (context) =>
                      trackMenu(context, actions.library, playback, track),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _content(BuildContext context, Track track) => switch (tab) {
    PanelTab.lyrics => MediaQuery.withClampedTextScaling(
      minScaleFactor: lyricsScale,
      maxScaleFactor: lyricsScale * 1.3,
      child: LyricsView(controller: lyrics),
    ),
    PanelTab.cover => CoverPanel(track: track, store: store, showArt: false),
    PanelTab.queue => QueuePanel(playback: playback, onSave: onSaveQueue),
  };

  Widget _tabs(BuildContext context, Track track) => Material(
    color: Theme.of(context).colorScheme.surfaceContainer,
    borderRadius: BorderRadius.circular(28),
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: PanelTabs(
              tab: tab,
              width: constraints.maxWidth,
              onTab: onTab,
              coverLabel: context.l10n.trackDetails,
            ),
          ),
          Expanded(child: _content(context, track)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final track = playback.current;
    final back = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text(l.back),
      ),
    );
    if (track == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            back,
            Expanded(child: Center(child: Text(l.noTrack))),
          ],
        ),
      );
    }
    final cover = CoverArt(
      path: track.coverPath,
      seed: '${track.album}|${track.artist}',
    );
    return CoverTint(
      path: track.coverPath,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= sideMinWidth) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: artWidth,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          back,
                          const SizedBox(height: 8),
                          AspectRatio(aspectRatio: 1, child: cover),
                          const SizedBox(height: 16),
                          _about(context, track),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _tabs(context, track)),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                back,
                if (constraints.maxHeight >= 360) _about(context, track),
                const SizedBox(height: 8),
                Expanded(child: _tabs(context, track)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// lib/src/ui/organisms/player_bar.dart
//
// A barra do player, sempre visível. Na janela larga, em três partes: a faixa, os
// controles com o progresso e a fila com o volume. Na estreita, só o essencial.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../player/engine.dart';
import '../../player/playback_controller.dart';
import '../atoms/favorite_button.dart';
import '../molecules/now_playing_info.dart';
import '../molecules/track_menu.dart';
import '../player_actions.dart';
import '../molecules/seek_bar.dart';
import '../molecules/transport_controls.dart';
import '../molecules/volume_control.dart';
import 'now_playing_panel.dart';

class PlayerBar extends StatelessWidget {
  /// A altura com a margem.
  static const height = 96.0;

  /// A partir daqui, a barra inteira.
  static const fullMinWidth = 760.0;

  /// A partir daqui, a capa e a fila entram na barra estreita.
  static const coverMinWidth = 380.0;

  final PlaybackController playback;
  final ValueChanged<PanelTab> onOpenPanel;

  /// A janela tem altura para o painel. Sem ela, os botões dele saem.
  final bool canOpenPanel;

  const PlayerBar({
    super.key,
    required this.playback,
    required this.onOpenPanel,
    this.canOpenPanel = true,
  });

  void _seek(Duration position) => unawaited(playback.engine.seek(position));

  List<Widget> _panelButtons(BuildContext context) => [
    if (canOpenPanel) ...[
      IconButton(
        tooltip: context.l10n.lyricsTab,
        icon: const Icon(Icons.lyrics_rounded),
        onPressed: () => onOpenPanel(PanelTab.lyrics),
      ),
      IconButton(
        tooltip: context.l10n.queue,
        icon: const Icon(Icons.queue_music_rounded),
        onPressed: () => onOpenPanel(PanelTab.queue),
      ),
    ],
  ];

  /// A faixa, ou o aviso de que deu erro ou não há nenhuma.
  Widget _info(BuildContext context, PlayerState s, double? coverSize) {
    final l = context.l10n;
    final track = playback.current;
    if (s.error != null || track == null) {
      return Text(
        s.error == null ? l.noTrack : l.openFailed,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final info = NowPlayingInfo(
      track: track,
      coverSize: coverSize,
      // Fora da biblioteca, quem leu as tags foi o motor
      title: track.id == 0 ? s.title : null,
    );
    if (!canOpenPanel) return info;
    return Tooltip(
      message: l.coverTab,
      child: InkWell(
        mouseCursor: WidgetStateMouseCursor.clickable,
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpenPanel(PanelTab.cover),
        child: info,
      ),
    );
  }

  Widget? _favorite(PlayerState s) {
    final track = playback.current;
    if (s.error != null || track == null || track.id == 0) return null;
    return FavoriteButton(
      favorite: track.favorite,
      size: 24,
      onChanged: (value) => unawaited(playback.setFavorite(track, value)),
    );
  }

  Widget? _trackMenu(BuildContext context, PlayerState s) {
    final track = playback.current;
    final actions = PlayerActions.maybeOf(context);
    if (s.error != null || track == null || actions == null) return null;
    return PopupMenuButton<VoidCallback>(
      tooltip: context.l10n.moreOptions,
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) => action(),
      itemBuilder: (context) =>
          trackMenu(context, actions.library, playback, track),
    );
  }

  /// Tudo que é botão numa linha só, e o progresso na largura toda, embaixo.
  Widget _full(BuildContext context, PlayerState s) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Row(
        children: [
          Expanded(
            child: Row(
              spacing: 4,
              children: [
                Expanded(child: _info(context, s, 48)),
                ?_favorite(s),
                ?_trackMenu(context, s),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TransportControls(playback: playback, state: s),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 4,
              children: [
                ..._panelButtons(context),
                const SizedBox(width: 4),
                Flexible(
                  child: VolumeControl(
                    volume: s.volume,
                    onChanged: playback.engine.setVolume,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SeekBar(position: s.position, duration: s.duration, onSeek: _seek),
    ],
  );

  Widget _narrow(BuildContext context, PlayerState s, double width) {
    final roomy = width >= coverMinWidth;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: _info(context, s, roomy ? 36 : null)),
              SeekBar(
                position: s.position,
                duration: s.duration,
                onSeek: _seek,
              ),
            ],
          ),
        ),
        TransportControls(playback: playback, state: s, compact: true),
        if (roomy) ..._panelButtons(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ValueListenableBuilder(
              valueListenable: playback.engine.state,
              builder: (context, s, _) => LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth >= fullMinWidth
                    ? _full(context, s)
                    : _narrow(context, s, constraints.maxWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

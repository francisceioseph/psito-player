// lib/src/ui/molecules/track_row.dart
//
// Uma faixa numa lista, com 56 px, ou 48 na densidade compacta: a posição, o começo (o número ou a capa), título e artista,
// formato, letra, duração e o menu. Quanto menos largura, menos colunas.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../atoms/favorite_button.dart';
import '../atoms/star_rating.dart';
import '../atoms/tag_chip.dart';
import '../format.dart';
import '../player_actions.dart';
import 'context_menu.dart';

class TrackRow extends StatelessWidget {
  static const height = 56.0;
  static const compactHeight = 48.0;

  /// A altura de cada linha: o que a densidade pede, e o texto maior cresce junto.
  static double extentOf(BuildContext context) {
    final base = Theme.of(context).visualDensity == VisualDensity.compact
        ? compactHeight
        : height;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return scale > 1 ? base * scale : base;
  }

  /// Abaixo disto, ficam só o título e o que vem depois dele.
  static const detailsMinWidth = 420.0;

  /// Nas colunas, a partir daqui entra o álbum.
  static const albumMinWidth = 640.0;

  // As medidas das colunas, que o cabeçalho repete
  static const numberWidth = 44.0;
  static const leadingWidth = 48.0;
  static const durationWidth = 64.0;
  static const formatWidth = 72.0;
  static const ratingWidth = 48.0;
  static const actionsWidth = 80.0;

  /// Entre o tempo e os ícones.
  static const durationGap = 16.0;
  static const durationGapMinWidth = 280.0;

  final Track track;

  /// A posição na lista, antes do começo da linha. Sai quando falta largura.
  final int? number;

  /// O começo da linha.
  final Widget? leading;

  /// É a faixa que está tocando.
  final bool current;
  final VoidCallback onTap;

  /// O que o menu oferece, ou null sem menu.
  final PopupMenuItemBuilder<VoidCallback>? menu;

  /// Com o botão de abrir o menu. Sem ele, o menu fica no botão direito.
  final bool menuButton;

  /// O botão de depois do menu, como tirar da fila.
  final Widget? trailing;

  /// Com o álbum, a duração e o formato em colunas, como na lista de músicas.
  final bool columns;

  /// O arquivo não está lá agora: fica apagada e não toca.
  final bool missing;

  /// Marca como favorita, ou null sem o botão.
  final ValueChanged<bool>? onFavorite;

  /// Com a duração mesmo sem largura para o resto, como na fila.
  final bool showDuration;

  const TrackRow({
    super.key,
    required this.track,
    required this.onTap,
    this.number,
    this.leading,
    this.current = false,
    this.menu,
    this.menuButton = true,
    this.trailing,
    this.columns = false,
    this.missing = false,
    this.onFavorite,
    this.showDuration = false,
  });

  Widget _muted(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: current
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// A posição, ou o sinal de que é esta que está tocando.
  Widget _number(BuildContext context) {
    final theme = Theme.of(context);
    final color = current
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: SizedBox(
        width: numberWidth,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: current
                ? Icon(Icons.equalizer_rounded, size: 16, color: color)
                : Text(
                    '$number',
                    maxLines: 1,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget? _lyricsIcon(BuildContext context) {
    if (!track.hasLyrics) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: context.l10n.hasLyrics,
        child: Icon(
          Icons.lyrics_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget? _missingIcon(BuildContext context) {
    if (!missing) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: context.l10n.fileUnavailable,
        child: Icon(
          Icons.warning_amber_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget? _favorite() {
    final onFavorite = this.onFavorite;
    if (onFavorite == null) return null;
    return FavoriteButton(favorite: track.favorite, onChanged: onFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final ratings = PlayerActions.ratingsOn(context);
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final artist = artistName(track.artist, context);
    final foreground = current ? scheme.onPrimaryContainer : scheme.onSurface;
    return ContextMenu(
      items: menu,
      child: Material(
        color: current ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          mouseCursor: WidgetStateMouseCursor.clickable,
          borderRadius: BorderRadius.circular(12),
          onTap: missing ? null : onTap,
          child: SizedBox(
            height: extentOf(context),
            child: Opacity(
              opacity: missing ? 0.5 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = constraints.maxWidth >= detailsMinWidth;
                    return Row(
                      children: [
                        if (number != null && details) _number(context),
                        if (leading != null) ...[
                          SizedBox(width: 40, child: Center(child: leading)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          flex: 3,
                          child: Semantics(
                            button: true,
                            label: '${track.title}, $artist',
                            excludeSemantics: true,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: foreground,
                                  ),
                                ),
                                Text(
                                  artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: current
                                        ? foreground
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ?_missingIcon(context),
                        if (columns && constraints.maxWidth >= albumMinWidth)
                          Expanded(
                            flex: 2,
                            child: _muted(context, track.album),
                          ),
                        if (columns && details) ...[
                          SizedBox(
                            width: durationWidth,
                            child: _muted(
                              context,
                              formatDuration(track.duration, locale),
                            ),
                          ),
                          SizedBox(
                            width: formatWidth,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: track.format.isEmpty
                                  ? null
                                  : TagChip(label: track.format),
                            ),
                          ),
                          if (ratings)
                            SizedBox(
                              width: ratingWidth,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: track.rating > 0
                                    ? StarBadge(rating: track.rating)
                                    : null,
                              ),
                            ),
                        ] else if (details) ...[
                          ?_lyricsIcon(context),
                          SizedBox(
                            width: 56,
                            child: Text(
                              formatDuration(track.duration, locale),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: foreground,
                              ),
                            ),
                          ),
                          const SizedBox(width: durationGap),
                        ],
                        if (showDuration && !details) ...[
                          _muted(
                            context,
                            formatDuration(track.duration, locale),
                          ),
                          // No painel mais estreito, a duração só cabe colada
                          if (constraints.maxWidth >= durationGapMinWidth)
                            const SizedBox(width: durationGap),
                        ],
                        if (ratings && details && !columns && track.rating > 0)
                          StarBadge(rating: track.rating),
                        if (details) ?_favorite(),
                        if (menu != null && menuButton)
                          PopupMenuButton<VoidCallback>(
                            tooltip: l.moreOptions,
                            icon: const Icon(Icons.more_vert_rounded),
                            itemBuilder: menu!,
                            onSelected: (action) => action(),
                          ),
                        ?trailing,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

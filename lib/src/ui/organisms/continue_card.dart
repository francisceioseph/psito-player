// lib/src/ui/organisms/continue_card.dart
//
// O destaque da tela Início: onde parou, o que está tocando, ou a biblioteca.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../atoms/cover_art.dart';
import '../atoms/mosaic_cover.dart';
import '../format.dart';

class ContinueCard extends StatelessWidget {
  /// Abaixo disto, a arte sai.
  static const artMinWidth = 420.0;
  static const artSize = 136.0;

  /// A faixa atual, ou null se não há nenhuma.
  final Track? track;

  /// A faixa é a da sessão anterior, e ainda não voltou a tocar.
  final bool resumable;
  final bool playing;
  final Duration position;
  final LibraryTotals totals;

  /// As capas do mosaico, sem faixa.
  final List<Album> albums;
  final VoidCallback onContinue;
  final VoidCallback onShuffleAll;

  const ContinueCard({
    super.key,
    required this.track,
    required this.position,
    required this.onContinue,
    required this.onShuffleAll,
    this.resumable = false,
    this.playing = false,
    this.totals = const LibraryTotals(),
    this.albums = const [],
  });

  Widget _art() {
    final track = this.track;
    if (track != null) {
      return CoverArt(
        path: track.coverPath,
        seed: '${track.album}|${track.artist}',
        size: artSize,
      );
    }
    return SizedBox.square(
      dimension: artSize,
      child: MosaicCover(
        seed: 'library',
        covers: [
          for (final a in albums.take(4))
            (path: a.coverPath, seed: '${a.title}|${a.artist}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final track = this.track;
    final String label;
    final String title;
    final String facts;
    if (track == null) {
      label = l.yourLibrary;
      title = l.trackCount(totals.tracks);
      facts =
          '${l.albumCount(totals.albums)} · '
          '${formatLength(totals.duration, context)}';
    } else {
      final artist = artistName(track.artist, context);
      label = resumable ? l.continueListening : l.nowPlaying;
      title = track.title;
      facts = resumable
          ? l.stoppedAt(
              artist,
              formatDuration(position, locale),
              formatDuration(track.duration, locale),
            )
          : artist;
    }
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall,
        ),
        Text(
          facts,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (track != null)
              FilledButton.icon(
                onPressed: onContinue,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  resumable ? l.continuePlaying : (playing ? l.pause : l.play),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: onShuffleAll,
              icon: const Icon(Icons.shuffle_rounded),
              label: Text(l.shuffleAll),
            ),
          ],
        ),
      ],
    );
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < artMinWidth) return text;
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _art(),
                ),
                const SizedBox(width: 20),
                Expanded(child: text),
              ],
            );
          },
        ),
      ),
    );
  }
}

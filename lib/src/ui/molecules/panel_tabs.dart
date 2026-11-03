// lib/src/ui/molecules/panel_tabs.dart
//
// As abas Letra, Capa e Fila, do painel e da tela da música.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

enum PanelTab { lyrics, cover, queue }

class PanelTabs extends StatelessWidget {
  /// Abaixo desta largura, as abas só com o ícone.
  static const labelsMinWidth = 300.0;

  final PanelTab tab;
  final double width;
  final ValueChanged<PanelTab> onTab;

  /// O nome da aba do meio, onde ela não mostra a capa.
  final String? coverLabel;

  const PanelTabs({
    super.key,
    required this.tab,
    required this.width,
    required this.onTab,
    this.coverLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = width >= labelsMinWidth;
    ButtonSegment<PanelTab> segment(
      PanelTab value,
      String label,
      IconData icon,
    ) => ButtonSegment(
      value: value,
      tooltip: labels ? null : label,
      icon: labels ? null : Icon(icon),
      // O sinal próprio: o do botão não deixa a palavra caber ao lado dele
      label: labels
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value == tab) ...[
                  const Icon(Icons.check_rounded, size: 16),
                  const SizedBox(width: 4),
                ],
                Flexible(child: Text(label, maxLines: 1)),
              ],
            )
          : null,
    );
    return SegmentedButton<PanelTab>(
      segments: [
        segment(PanelTab.lyrics, l.lyricsTab, Icons.lyrics_rounded),
        segment(PanelTab.cover, coverLabel ?? l.coverTab, Icons.album_rounded),
        segment(PanelTab.queue, l.queue, Icons.queue_music_rounded),
      ],
      selected: {tab},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onTab(selection.first),
    );
  }
}

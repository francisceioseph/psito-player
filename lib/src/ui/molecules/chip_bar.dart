// lib/src/ui/molecules/chip_bar.dart
//
// Os filtros de uma tela: um escolhido de cada vez, rolando quando não cabem, ou
// descendo de linha com [wrap].
import 'package:flutter/material.dart';

class ChipBar<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool wrap;

  const ChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final (value, label) in options)
        FilterChip(
          mouseCursor: WidgetStateMouseCursor.clickable,
          label: Text(label),
          selected: value == selected,
          onSelected: (_) => onSelected(value),
        ),
    ];
    if (wrap) return Wrap(spacing: 8, runSpacing: 8, children: chips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final chip in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: chip),
        ],
      ),
    );
  }
}

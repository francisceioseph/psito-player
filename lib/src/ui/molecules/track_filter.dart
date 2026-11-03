// lib/src/ui/molecules/track_filter.dart
//
// A busca dentro de uma lista de faixas: o botão fica nas ações da tela, e o campo
// aparece logo acima da lista. Filtra aqui mesmo, porque as faixas já estão à mão.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../atoms/empty_note.dart';

mixin TrackFilter<T extends StatefulWidget> on State<T> {
  bool _open = false;
  String _text = '';

  bool get filterActive => _open && _text.trim().isNotEmpty;

  /// As que casam com o que foi digitado, em todas as palavras.
  List<Track> filtered(List<Track> tracks) {
    if (!filterActive) return tracks;
    final words = foldedText(_text)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return [
      for (final track in tracks)
        if (_matches(track, words)) track,
    ];
  }

  static bool _matches(Track track, List<String> words) {
    final text = foldedText('${track.title} ${track.artist} ${track.album}');
    return words.every(text.contains);
  }

  void _close() => setState(() {
    _open = false;
    _text = '';
  });

  Widget filterButton(BuildContext context) {
    final l = context.l10n;
    return IconButton(
      tooltip: l.filterList,
      isSelected: _open,
      icon: const Icon(Icons.search_rounded),
      onPressed: () => _open ? _close() : setState(() => _open = true),
    );
  }

  /// O campo e o aviso de nada encontrado. Vazio com a busca fechada.
  List<Widget> filterSlivers(BuildContext context, List<Track> tracks) {
    if (!_open) return const [];
    final l = context.l10n;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _close();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _text = value),
              decoration: InputDecoration(
                labelText: l.filterList,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      if (filterActive && filtered(tracks).isEmpty)
        SliverToBoxAdapter(child: EmptyNote(l.noResults(_text.trim()))),
    ];
  }
}

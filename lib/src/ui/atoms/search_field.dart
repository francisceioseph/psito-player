// lib/src/ui/atoms/search_field.dart
//
// O campo de busca do player: a lupa, a dica e o X para limpar. O desenho vem do
// tema (`inputDecorationTheme`).
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Mais baixo, para ficar dentro de uma lista.
  final bool dense;

  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.dense = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _clear() {
    _text.clear();
    widget.onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.hint,
    child: ListenableBuilder(
      listenable: _text,
      builder: (context, _) => TextField(
        controller: _text,
        focusNode: _focus,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: widget.dense,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _text.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.l10n.clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clear,
                ),
        ),
      ),
    ),
  );
}

// lib/src/ui/molecules/tag_fields.dart
//
// Os campos do editor de tags: texto, número e total, e gênero com as sugestões.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../atoms/changed_mark.dart';

Widget _label(String text, bool changed) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (changed) ...[const ChangedMark(), const SizedBox(width: 6)],
    Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
  ],
);

final _digits = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(4),
];

class TagTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool changed;
  final bool readOnly;
  final bool number;
  final int minLines;

  /// A dica de um campo vazio, como "Vários valores".
  final String? hint;

  /// Um botão ao fim do campo, como apagar em todas as faixas.
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const TagTextField({
    super.key,
    required this.label,
    required this.controller,
    this.changed = false,
    this.readOnly = false,
    this.number = false,
    this.minLines = 1,
    this.hint,
    this.trailing,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    readOnly: readOnly,
    minLines: minLines,
    maxLines: minLines > 1 ? null : 1,
    keyboardType: number ? TextInputType.number : null,
    inputFormatters: number ? _digits : null,
    onChanged: onChanged,
    decoration: InputDecoration(
      label: _label(label, changed),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hint,
      suffixIcon: trailing,
    ),
  );
}

/// Número e total, como "Faixa 3 de 12", num campo só.
class TagPairField extends StatelessWidget {
  final String label;
  final String numberLabel;
  final String totalLabel;
  final TextEditingController number;
  final TextEditingController total;
  final bool changed;
  final bool readOnly;
  final String? numberHint;
  final String? totalHint;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const TagPairField({
    super.key,
    required this.label,
    required this.numberLabel,
    required this.totalLabel,
    required this.number,
    required this.total,
    this.changed = false,
    this.readOnly = false,
    this.numberHint,
    this.totalHint,
    this.trailing,
    this.onChanged,
  });

  Widget _part(String label, TextEditingController controller, String? hint) =>
      Expanded(
        child: Semantics(
          label: label,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            inputFormatters: _digits,
            onChanged: onChanged,
            decoration: InputDecoration.collapsed(
              hintText: hint,
              filled: false,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        label: _label(label, changed),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: trailing,
      ),
      child: Row(
        children: [
          _part(numberLabel, number, numberHint),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ExcludeSemantics(
              child: Text(
                context.l10n.tagPairOf,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          _part(totalLabel, total, totalHint),
        ],
      ),
    );
  }
}

/// O gênero, com o que já existe na biblioteca como sugestão.
class TagGenreField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<Genre> genres;
  final bool changed;
  final bool readOnly;
  final String? hint;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const TagGenreField({
    super.key,
    required this.label,
    required this.controller,
    required this.genres,
    this.changed = false,
    this.readOnly = false,
    this.hint,
    this.trailing,
    this.onChanged,
  });

  @override
  State<TagGenreField> createState() => _TagGenreFieldState();
}

class _TagGenreFieldState extends State<TagGenreField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Iterable<Genre> _options(TextEditingValue value) {
    if (widget.readOnly) return const [];
    final typed = value.text.trim().toLowerCase();
    return widget.genres.where(
      (g) =>
          g.name.isNotEmpty &&
          g.name.toLowerCase() != typed &&
          g.name.toLowerCase().contains(typed),
    );
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<Genre>(
    textEditingController: widget.controller,
    focusNode: _focus,
    displayStringForOption: (genre) => genre.name,
    optionsBuilder: _options,
    onSelected: (genre) => widget.onChanged?.call(genre.name),
    fieldViewBuilder: (context, controller, focus, onSubmitted) => TextField(
      controller: controller,
      focusNode: focus,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        label: _label(widget.label, widget.changed),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: widget.hint,
        suffixIcon: widget.trailing,
      ),
    ),
    optionsViewBuilder: (context, onSelected, options) {
      final theme = Theme.of(context);
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final genre in options)
                  ListTile(
                    dense: true,
                    title: Text(genre.name),
                    trailing: Text(
                      '${genre.tracks}',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => onSelected(genre),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

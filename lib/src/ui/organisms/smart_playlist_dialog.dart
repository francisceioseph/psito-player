// lib/src/ui/organisms/smart_playlist_dialog.dart
//
// Criar e editar uma playlist inteligente: o nome, as regras, a ordem e o limite,
// mostrando quantas músicas entram enquanto se mexe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';

/// As ordens que a tela oferece, em par com o sentido.
const _orders = [
  (TrackSort.title, true),
  (TrackSort.added, false),
  (TrackSort.rating, false),
  (TrackSort.year, false),
];

Future<void> createSmartPlaylist(
  BuildContext context,
  LibraryController library,
) async {
  final result = await _show(context, library, null);
  if (result != null) {
    await library.createSmartPlaylist(result.name, result.rules);
  }
}

Future<void> editSmartPlaylist(
  BuildContext context,
  LibraryController library,
  Playlist playlist,
) async {
  final result = await _show(context, library, playlist);
  if (result == null) return;
  if (result.name != playlist.name) {
    await library.renamePlaylist(playlist, result.name);
  }
  await library.setPlaylistRules(playlist, result.rules);
}

Future<({String name, SmartRules rules})?> _show(
  BuildContext context,
  LibraryController library,
  Playlist? playlist,
) => showDialog(
  context: context,
  builder: (_) => _SmartDialog(library: library, playlist: playlist),
);

class _SmartDialog extends StatefulWidget {
  final LibraryController library;
  final Playlist? playlist;

  const _SmartDialog({required this.library, required this.playlist});

  @override
  State<_SmartDialog> createState() => _SmartDialogState();
}

/// Uma linha sendo editada. A chave segura os campos no lugar quando outra sai.
class _Draft {
  final key = UniqueKey();
  SmartRule rule;

  _Draft(this.rule);
}

class _SmartDialogState extends State<_SmartDialog> {
  late final TextEditingController _name;
  late final TextEditingController _limit;
  late List<_Draft> _drafts;
  late bool _matchAll;
  late (TrackSort, bool) _order;
  int? _count;
  int _asked = 0;

  List<String> get _genres => [
    for (final genre in widget.library.genres)
      if (genre.name.isNotEmpty) genre.name,
  ];

  /// A nota só aparece com as estrelas ligadas, menos em quem já usa.
  List<SmartField> _fieldsFor(SmartRule rule) => [
    SmartField.genre,
    SmartField.year,
    if (widget.library.useRatings || rule.field == SmartField.rating)
      SmartField.rating,
  ];

  SmartRule _blank(SmartField field) => switch (field) {
    SmartField.genre => SmartRule(
      field,
      SmartOp.equals,
      text: _genres.firstOrNull ?? '',
    ),
    SmartField.year => const SmartRule(SmartField.year, SmartOp.atLeast),
    SmartField.rating => const SmartRule(
      SmartField.rating,
      SmartOp.atLeast,
      number: 4,
    ),
  };

  SmartRule get _firstRule =>
      _blank(_genres.isEmpty ? SmartField.year : SmartField.genre);

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlist;
    final rules = playlist?.rules;
    _name = TextEditingController(text: playlist?.name ?? '');
    _limit = TextEditingController(text: rules?.limit?.toString() ?? '');
    _drafts = [
      for (final rule in rules?.rules ?? [_firstRule]) _Draft(rule),
    ];
    _matchAll = rules?.matchAll ?? true;
    final saved = rules == null ? null : (rules.sort, rules.ascending);
    _order = _orders.contains(saved) ? saved! : _orders.first;
    unawaited(_recount());
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  SmartRules get _rules => SmartRules(
    rules: [for (final draft in _drafts) draft.rule],
    matchAll: _matchAll,
    sort: _order.$1,
    ascending: _order.$2,
    limit: int.tryParse(_limit.text),
  );

  bool get _canSave => _name.text.trim().isNotEmpty && _rules.valid;

  Future<void> _recount() async {
    final asked = ++_asked;
    final rules = _rules;
    final count = rules.valid
        ? await widget.library.store.smartCount(rules)
        : null;
    if (mounted && asked == _asked) setState(() => _count = count);
  }

  void _changed(VoidCallback change) {
    setState(change);
    unawaited(_recount());
  }

  String _fieldLabel(SmartField field) {
    final l = context.l10n;
    return switch (field) {
      SmartField.genre => l.ruleGenre,
      SmartField.year => l.ruleYear,
      SmartField.rating => l.ruleRating,
    };
  }

  String _opLabel(SmartOp op) {
    final l = context.l10n;
    return switch (op) {
      SmartOp.equals => l.ruleIs,
      SmartOp.notEquals => l.ruleIsNot,
      SmartOp.atLeast => l.ruleAtLeast,
      SmartOp.atMost => l.ruleAtMost,
    };
  }

  String _orderLabel((TrackSort, bool) order) {
    final l = context.l10n;
    return switch (order.$1) {
      TrackSort.added => l.orderRecent,
      TrackSort.rating => l.orderRating,
      TrackSort.year => l.orderYear,
      _ => l.orderTitle,
    };
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) text,
    required ValueChanged<T> onChanged,
  }) => Semantics(
    label: label,
    child: DropdownButton<T>(
      value: value,
      isDense: true,
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(text(item))),
      ],
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    ),
  );

  Widget _value(_Draft draft) {
    final rule = draft.rule;
    final l = context.l10n;
    SmartRule withNumber(int number) =>
        SmartRule(rule.field, rule.op, number: number);
    return switch (rule.field) {
      SmartField.genre => _dropdown<String>(
        label: l.ruleGenre,
        // Um gênero que saiu da biblioteca continua aparecendo na regra
        value: rule.text.isEmpty ? null : rule.text,
        values: {..._genres, if (rule.text.isNotEmpty) rule.text}.toList(),
        text: (genre) => genre,
        onChanged: (genre) => _changed(
          () => draft.rule = SmartRule(rule.field, rule.op, text: genre),
        ),
      ),
      SmartField.year => _NumberField(
        key: ValueKey(draft.key),
        label: l.ruleYear,
        initial: rule.number == 0 ? '' : '${rule.number}',
        width: 88,
        digits: 4,
        onChanged: (text) =>
            _changed(() => draft.rule = withNumber(int.tryParse(text) ?? 0)),
      ),
      SmartField.rating => _dropdown<int>(
        label: l.ruleRating,
        value: rule.number,
        values: const [1, 2, 3, 4, 5],
        text: (stars) => '★' * stars,
        onChanged: (stars) => _changed(() => draft.rule = withNumber(stars)),
      ),
    };
  }

  Widget _ruleRow(_Draft draft) {
    final l = context.l10n;
    final rule = draft.rule;
    return Padding(
      key: draft.key,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _dropdown<SmartField>(
                  label: l.smartRuleField,
                  value: rule.field,
                  values: _fieldsFor(rule),
                  text: _fieldLabel,
                  onChanged: (field) {
                    if (field != rule.field) {
                      _changed(() => draft.rule = _blank(field));
                    }
                  },
                ),
                _dropdown<SmartOp>(
                  label: l.smartRuleCompare,
                  value: rule.op,
                  values: SmartRule.opsFor(rule.field),
                  text: _opLabel,
                  onChanged: (op) => _changed(
                    () => draft.rule = SmartRule(
                      rule.field,
                      op,
                      text: rule.text,
                      number: rule.number,
                    ),
                  ),
                ),
                _value(draft),
              ],
            ),
          ),
          if (_drafts.length > 1)
            IconButton(
              tooltip: l.removeRule,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _changed(() => _drafts.remove(draft)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final count = _count;
    return AlertDialog(
      title: Text(
        widget.playlist == null ? l.newSmartPlaylist : l.editSmartRules,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.playlist == null,
                decoration: InputDecoration(hintText: l.playlistName),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ..._drafts.map(_ruleRow),
              TextButton.icon(
                onPressed: () =>
                    _changed(() => _drafts.add(_Draft(_firstRule))),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.addRule),
              ),
              if (_drafts.length > 1) ...[
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, label: Text(l.matchAllRules)),
                    ButtonSegment(value: false, label: Text(l.matchAnyRule)),
                  ],
                  selected: {_matchAll},
                  onSelectionChanged: (v) =>
                      _changed(() => _matchAll = v.first),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.smartOrder),
                      const SizedBox(width: 12),
                      _dropdown<(TrackSort, bool)>(
                        label: l.smartOrder,
                        value: _order,
                        values: _orders,
                        text: _orderLabel,
                        onChanged: (order) => _changed(() => _order = order),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _limit,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: InputDecoration(
                        labelText: l.smartLimit,
                        hintText: l.noLimit,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      onChanged: (_) => _changed(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                count == null ? '' : l.trackCount(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _canSave
              ? () =>
                    Navigator.of(context)
                        .pop((name: _name.text.trim(), rules: _rules))
              : null,
          child: Text(widget.playlist == null ? l.create : l.save),
        ),
      ],
    );
  }
}

/// Um campo só de números, que guarda o próprio texto.
class _NumberField extends StatefulWidget {
  final String label;
  final String initial;
  final double width;
  final int digits;
  final ValueChanged<String> onChanged;

  const _NumberField({
    super.key,
    required this.label,
    required this.initial,
    required this.width,
    required this.digits,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.digits),
      ],
      decoration: InputDecoration(hintText: widget.label, isDense: true),
      onChanged: widget.onChanged,
    ),
  );
}

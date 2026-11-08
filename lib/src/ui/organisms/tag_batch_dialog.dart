// lib/src/ui/organisms/tag_batch_dialog.dart
//
// Editar várias faixas de uma vez. Só o que a pessoa mexer é gravado, e o que cada
// faixa tem de seu (título, número, letra) fica de fora.
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/models.dart';
import '../../library/tag_edit/tag_edit.dart';
import '../../library/tag_edit/tag_files.dart';
import '../atoms/changed_mark.dart';
import '../molecules/embedded_cover_editor.dart';
import '../molecules/tag_fields.dart';
import '../player_actions.dart';
import '../templates/editor_template.dart';
import 'tag_editor_dialog.dart';
import 'tag_write_feedback.dart';

Future<void> showBatchTagEditor(
  BuildContext context,
  PlayerActions actions,
  List<Track> tracks,
) => showDialog<void>(
  context: context,
  builder: (_) => TagBatchDialog(actions: actions, tracks: tracks),
);

/// O valor comum de um campo em todas as faixas, ou "" e [varied].
({String value, bool varied}) commonTagValue(
  Iterable<EditableTags> tags,
  TagField field,
) {
  final values = {for (final t in tags) t.values[field] ?? ''};
  return values.length == 1
      ? (value: values.single, varied: false)
      : (value: '', varied: true);
}

const _batchFields = [
  TagField.artist,
  TagField.albumArtist,
  TagField.album,
  TagField.year,
  TagField.discNumber,
  TagField.discTotal,
  TagField.genre,
  TagField.composer,
  TagField.comment,
];

/// O que o lote muda: o que foi digitado e o que foi apagado.
TagEdit batchTagEdit({
  required Map<TagField, String> typed,
  required Map<TagField, String> initial,
  required Set<TagField> erased,
  required CoverChoice cover,
}) => TagEdit(
  fields: {
    for (final field in _batchFields)
      if (erased.contains(field))
        field: null
      else if ((typed[field] ?? '').trim() != (initial[field] ?? ''))
        field: (typed[field] ?? '').trim(),
  },
  coverChanged: cover.changed,
  cover: cover.picture,
);

List<EditableTags> _readAll(List<String> paths) => [
  for (final path in paths) readEditableTags(path, cover: false),
];

// Fora da classe: o que vai para outro isolate só leva dados
Future<List<EditableTags>> _readAllInIsolate(List<String> paths) =>
    Isolate.run(() => _readAll(paths));

enum _Section { details, cover }

class TagBatchDialog extends StatefulWidget {
  final PlayerActions actions;
  final List<Track> tracks;

  const TagBatchDialog({
    super.key,
    required this.actions,
    required this.tracks,
  });

  @override
  State<TagBatchDialog> createState() => _TagBatchDialogState();
}

class _TagBatchDialogState extends State<TagBatchDialog> {
  final _controllers = {
    for (final field in _batchFields) field: TextEditingController(),
  };
  final _initial = <TagField, String>{};
  final _varied = <TagField>{};
  final _erased = <TagField>{};
  List<EditableTags>? _tags;
  _Section _section = _Section.details;
  CoverChoice _cover = const CoverChoice.keep();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final paths = [for (final t in widget.tracks) t.path];
    final tags = await _readAllInIsolate(paths);
    if (!mounted) return;
    setState(() {
      _tags = tags;
      for (final field in _batchFields) {
        final common = commonTagValue(tags, field);
        _initial[field] = common.value;
        _controllers[field]!.text = common.value;
        if (common.varied) _varied.add(field);
      }
    });
  }

  TagEdit get _edit => batchTagEdit(
    typed: {for (final e in _controllers.entries) e.key: e.value.text},
    initial: _initial,
    erased: _erased,
    cover: _cover,
  );

  List<String> get _writablePaths {
    final tags = _tags ?? const <EditableTags>[];
    return [
      for (var i = 0; i < tags.length; i++)
        if (tags[i].writable == Writable.yes) widget.tracks[i].path,
    ];
  }

  bool _isChanged(TagField field) => _edit.fields.containsKey(field);

  bool get _dirty => !_edit.isEmpty;

  void _rebuild([String _ = '']) => setState(() {});

  void _toggleErase(List<TagField> fields) => setState(() {
    final erase = !_erased.contains(fields.first);
    for (final field in fields) {
      erase ? _erased.add(field) : _erased.remove(field);
      _controllers[field]!.text = erase ? '' : _initial[field] ?? '';
    }
  });

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    final edit = _edit;
    unawaited(
      saveTagEdits(context, widget.actions, {
        for (final path in _writablePaths) path: edit,
      }),
    );
    widget.actions.selection?.clear();
    navigator.pop();
  }

  Future<void> _close() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final l = context.l10n;
    final navigator = Navigator.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.tagDiscardBatchTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.tagDiscard),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
    if (discard ?? false) navigator.pop();
  }

  Future<void> _pickCover() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final path = await widget.actions.pickImage?.call(l.tagCoverChoose);
    if (path == null) return;
    final picture = await loadCoverImage(path);
    if (!mounted) return;
    if (picture == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l.coverUnreadable)));
      return;
    }
    setState(() => _cover = CoverChoice.replace(picture));
  }

  Widget? _eraser(List<TagField> fields, String label) {
    final l = context.l10n;
    final count = widget.tracks.length;
    if (_erased.contains(fields.first)) {
      return IconButton(
        tooltip: l.tagKeepField,
        onPressed: () => _toggleErase(fields),
        icon: const Icon(Icons.undo_rounded),
      );
    }
    final hasValue = fields.any(
      (f) => _varied.contains(f) || (_initial[f] ?? '').isNotEmpty,
    );
    if (!hasValue) return null;
    return IconButton(
      tooltip: l.tagEraseField(count, label),
      onPressed: () => _toggleErase(fields),
      icon: const Icon(Icons.backspace_rounded),
    );
  }

  String? _hint(TagField field) {
    final l = context.l10n;
    if (_erased.contains(field)) return l.tagWillErase(widget.tracks.length);
    return _varied.contains(field) ? l.tagVariousValues : null;
  }

  Widget _field(TagField field, {bool number = false}) {
    final label = tagFieldLabel(context.l10n, field);
    return TagTextField(
      label: label,
      controller: _controllers[field]!,
      changed: _isChanged(field),
      readOnly: _erased.contains(field),
      number: number,
      hint: _hint(field),
      trailing: _eraser([field], label),
      onChanged: _rebuild,
    );
  }

  Widget _details() {
    final l = context.l10n;
    final number = TagField.discNumber;
    final total = TagField.discTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TagNote(icon: Icons.info_outline_rounded, text: l.tagBatchNote),
        const SizedBox(height: 16),
        TagFieldGrid(
          fields: [
            (_field(TagField.artist), false),
            (_field(TagField.albumArtist), false),
            (_field(TagField.album), false),
            (_field(TagField.year, number: true), false),
            (
              TagPairField(
                label: l.tagDisc,
                numberLabel: tagFieldLabel(l, number),
                totalLabel: tagFieldLabel(l, total),
                number: _controllers[number]!,
                total: _controllers[total]!,
                changed: _isChanged(number) || _isChanged(total),
                numberHint: _hint(number),
                totalHint: _hint(total),
                readOnly: _erased.contains(number),
                trailing: _eraser([number, total], l.tagDisc),
                onChanged: _rebuild,
              ),
              false,
            ),
            (
              TagGenreField(
                label: l.tagGenre,
                controller: _controllers[TagField.genre]!,
                genres: widget.actions.library.genres,
                changed: _isChanged(TagField.genre),
                hint: _hint(TagField.genre),
                readOnly: _erased.contains(TagField.genre),
                trailing: _eraser([TagField.genre], l.tagGenre),
                onChanged: _rebuild,
              ),
              false,
            ),
            (_field(TagField.composer), false),
            (_field(TagField.comment), false),
          ],
        ),
      ],
    );
  }

  Widget _coverSection() => EmbeddedCoverEditor(
    current: null,
    choice: _cover,
    readOnly: false,
    onPick: widget.actions.pickImage == null
        ? null
        : () => unawaited(_pickCover()),
    onFolder: null,
    onRemove: () => setState(() => _cover = const CoverChoice.remove()),
    onKeep: () => setState(() => _cover = const CoverChoice.keep()),
  );

  Widget _tab(String label, bool changed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(label, maxLines: 1)),
      if (changed) ...[const SizedBox(width: 6), const ChangedMark()],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = _tags;
    final total = widget.tracks.length;
    final writable = _writablePaths.length;
    final skipped = tags == null ? 0 : total - writable;
    final edit = _edit;
    final fieldCount = edit.fields.length + (edit.coverChanged ? 1 : 0);
    final artists = {for (final t in widget.tracks) t.artist}.length;
    final albums = {for (final t in widget.tracks) t.albumId}.length;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: EditorTemplate(
        title: l.trackCount(total),
        subtitle: [
          l.tagEditTitle,
          l.tagArtistCount(artists),
          l.albumCount(albums),
        ].join(' · '),
        tabs: Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<_Section>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _Section.details,
                label: _tab(l.tagDetails, edit.fields.isNotEmpty),
              ),
              ButtonSegment(
                value: _Section.cover,
                label: _tab(l.coverTab, edit.coverChanged),
              ),
            ],
            selected: {_section},
            onSelectionChanged: (value) =>
                setState(() => _section = value.single),
          ),
        ),
        body: tags == null
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _section == _Section.details
                    ? _details()
                    : _coverSection(),
              ),
        footer: skipped == 0
            ? null
            : TagNote(
                icon: Icons.block_rounded,
                text: l.tagBatchSkipped(skipped),
              ),
        status: fieldCount == 0
            ? null
            : l.tagBatchSummary(fieldCount, writable),
        closeLabel: l.cancel,
        onClose: () => unawaited(_close()),
        saveLabel: l.tagSaveIn(writable),
        onSave: _dirty && writable > 0 ? () => unawaited(_save()) : null,
      ),
    );
  }
}

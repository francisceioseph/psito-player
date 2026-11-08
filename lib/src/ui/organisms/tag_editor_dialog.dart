// lib/src/ui/organisms/tag_editor_dialog.dart
//
// Editar as tags de uma faixa: Detalhes, Letra e Capa, com as setas para seguir
// pela lista de onde veio.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/l10n.dart';
import '../../../l10n/player_localizations.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../library/scanner.dart';
import '../../library/tag_edit/tag_edit.dart';
import '../../library/tag_edit/tag_files.dart';
import '../atoms/changed_mark.dart';
import '../format.dart';
import '../molecules/embedded_cover_editor.dart';
import '../molecules/tag_fields.dart';
import '../player_actions.dart';
import '../templates/editor_template.dart';
import 'tag_write_feedback.dart';

/// Abre o editor em [index], podendo andar por [tracks].
Future<void> showTagEditor(
  BuildContext context,
  PlayerActions actions,
  List<Track> tracks,
  int index,
) => showDialog<void>(
  context: context,
  builder: (_) =>
      TagEditorDialog(actions: actions, tracks: tracks, index: index),
);

/// O motivo de só poder ler.
String? tagReadOnlyNote(PlayerLocalizations l, EditableTags tags) =>
    switch (tags.writable) {
      Writable.yes => null,
      Writable.unsupportedFormat => l.tagReadOnlyFormat(tags.format),
      Writable.readOnlyDisk => l.tagReadOnlyDisk,
      Writable.noPermission => l.tagReadOnlyPermission,
      Writable.missing => l.tagReadOnlyMissing,
    };

/// O nome de um campo, para a tela.
String tagFieldLabel(PlayerLocalizations l, TagField field) => switch (field) {
  TagField.title => l.tagTitle,
  TagField.artist => l.tagArtist,
  TagField.album => l.tagAlbum,
  TagField.albumArtist => l.tagAlbumArtist,
  TagField.trackNumber => l.tagTrackNumber,
  TagField.trackTotal => l.tagTrackTotal,
  TagField.discNumber => l.tagDiscNumber,
  TagField.discTotal => l.tagDiscTotal,
  TagField.year => l.tagYear,
  TagField.genre => l.tagGenre,
  TagField.composer => l.tagComposer,
  TagField.comment => l.tagComment,
  TagField.lyrics => l.lyricsTab,
};

/// Uma linha de aviso, com o ícone.
class TagNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const TagNote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Os campos em duas colunas, ou uma se não couber. O `true` ocupa a linha.
class TagFieldGrid extends StatelessWidget {
  static const twoColumnsMinWidth = 460.0;
  static const _gap = 16.0;

  final List<(Widget, bool)> fields;

  /// Quantas colunas, quando couber. Sem isto, duas.
  final int columns;

  const TagFieldGrid({super.key, required this.fields, this.columns = 2});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final count = width >= twoColumnsMinWidth ? columns : 1;
      final half = (width - _gap * (count - 1)) / count;
      return Wrap(
        spacing: _gap,
        runSpacing: 12,
        children: [
          for (final (field, full) in fields)
            SizedBox(width: full ? width : half, child: field),
        ],
      );
    },
  );
}

enum _Section { details, lyrics, cover }

/// O que ler de uma faixa ao abrir: as tags e a capa da pasta.
class _Opened {
  final EditableTags tags;
  final String? folderCover;

  const _Opened(this.tags, this.folderCover);
}

/// A capa que está na pasta de [path], ou nula.
String? folderCoverOf(String path) {
  final dir = p.dirname(path);
  try {
    final name = findCoverFile([
      for (final entity in Directory(dir).listSync()) p.basename(entity.path),
    ]);
    return name == null ? null : p.join(dir, name);
  } on FileSystemException {
    return null;
  }
}

_Opened _open(String path) =>
    _Opened(readEditableTags(path), folderCoverOf(path));

// Fora da classe: o que vai para outro isolate só leva dados
Future<_Opened> _openInIsolate(String path) => Isolate.run(() => _open(path));

enum _Leaving { discard, save }

class TagEditorDialog extends StatefulWidget {
  final PlayerActions actions;
  final List<Track> tracks;
  final int index;

  const TagEditorDialog({
    super.key,
    required this.actions,
    required this.tracks,
    required this.index,
  });

  @override
  State<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<TagEditorDialog> {
  final _controllers = {
    for (final field in TagField.values) field: TextEditingController(),
  };
  late int _index = widget.index;
  _Opened? _opened;
  TrackDetails? _audio;
  _Section _section = _Section.details;
  CoverChoice _cover = const CoverChoice.keep();

  Track get _track => widget.tracks[_index];
  EditableTags? get _tags => _opened?.tags;
  bool get _writable => _tags?.writable == Writable.yes;

  /// O do arquivo: o da lista pode ser de antes de salvar.
  String get _shownTitle => _tags?.values[TagField.title] ?? _track.title;

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
    final path = _track.path;
    final (opened, details) = await (
      _openInIsolate(path),
      widget.actions.library.store.trackDetails(path),
    ).wait;
    if (!mounted || path != _track.path) return;
    setState(() {
      _opened = opened;
      _audio = details;
      _cover = const CoverChoice.keep();
      for (final MapEntry(key: field, value: c) in _controllers.entries) {
        c.text = opened.tags.values[field] ?? '';
      }
    });
  }

  bool _isChanged(TagField field) {
    final tags = _tags;
    if (tags == null) return false;
    final before = (tags.values[field] ?? '').trim();
    return _controllers[field]!.text.trim() != before;
  }

  List<TagField> get _changed =>
      TagField.values.where(_isChanged).toList(growable: false);

  bool get _detailsChanged => _changed.any((field) => field != TagField.lyrics);

  bool get _dirty => _writable && (_changed.isNotEmpty || _cover.changed);

  TagEdit get _edit => TagEdit(
    fields: {
      for (final field in _changed) field: _controllers[field]!.text.trim(),
    },
    coverChanged: _cover.changed,
    cover: _cover.picture,
  );

  void _rebuild([String _ = '']) => setState(() {});

  Future<void> _save() =>
      saveTagEdits(context, widget.actions, {_track.path: _edit});

  Future<void> _saveAndClose() async {
    final navigator = Navigator.of(context);
    unawaited(_save());
    navigator.pop();
  }

  /// Com mudanças, pergunta. Devolve se pode seguir, e já salvou se for o caso.
  Future<bool> _settle(String saveLabel) async {
    if (!_dirty) return true;
    final l = context.l10n;
    final names = [
      for (final field in _changed) tagFieldLabel(l, field),
      if (_cover.changed) l.coverTab,
    ].join(', ');
    final answer = await showDialog<_Leaving>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.tagSaveChangesTitle),
        content: Text(l.tagSaveChangesBody(names, _shownTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Leaving.discard),
            child: Text(l.tagDiscard),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_Leaving.save),
            child: Text(saveLabel),
          ),
        ],
      ),
    );
    if (answer == null) return false;
    if (answer == _Leaving.save) await _save();
    return mounted;
  }

  Future<void> _go(int delta) async {
    final l = context.l10n;
    if (!await _settle(delta > 0 ? l.tagSaveAndNext : l.tagSaveAndPrevious)) {
      return;
    }
    setState(() {
      _index += delta;
      _opened = null;
    });
    await _load();
  }

  Future<void> _close() async {
    final navigator = Navigator.of(context);
    if (await _settle(context.l10n.tagSaveAndClose)) navigator.pop();
  }

  Future<void> _pickCover() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final path = await widget.actions.pickImage?.call(l.tagCoverChoose);
    if (path == null) return;
    await _useCover(path, messenger);
  }

  Future<void> _useCover(String path, ScaffoldMessengerState? messenger) async {
    final l = context.l10n;
    final picture = await loadCoverImage(path);
    if (!mounted) return;
    if (picture == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l.coverUnreadable)));
      return;
    }
    setState(() => _cover = CoverChoice.replace(picture));
  }

  Widget _field(TagField field, {int minLines = 1, bool number = false}) {
    final l = context.l10n;
    return TagTextField(
      label: tagFieldLabel(l, field),
      controller: _controllers[field]!,
      changed: _isChanged(field),
      readOnly: !_writable,
      minLines: minLines,
      number: number,
      onChanged: _rebuild,
    );
  }

  Widget _pair(String label, TagField number, TagField total) {
    final l = context.l10n;
    return TagPairField(
      label: label,
      numberLabel: tagFieldLabel(l, number),
      totalLabel: tagFieldLabel(l, total),
      number: _controllers[number]!,
      total: _controllers[total]!,
      changed: _isChanged(number) || _isChanged(total),
      readOnly: !_writable,
      onChanged: _rebuild,
    );
  }

  Widget _details() {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TagFieldGrid(
        fields: [
          (_field(TagField.title), true),
          (_field(TagField.artist), false),
          (_field(TagField.albumArtist), false),
          (_field(TagField.album), false),
          (_field(TagField.year, number: true), false),
          (_pair(l.tagTrack, TagField.trackNumber, TagField.trackTotal), false),
          (_pair(l.tagDisc, TagField.discNumber, TagField.discTotal), false),
          (
            TagGenreField(
              label: l.tagGenre,
              controller: _controllers[TagField.genre]!,
              genres: widget.actions.library.genres,
              changed: _isChanged(TagField.genre),
              readOnly: !_writable,
              onChanged: _rebuild,
            ),
            false,
          ),
          (_field(TagField.composer), false),
          (_field(TagField.comment), true),
        ],
      ),
    );
  }

  Widget _lyrics() {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        _field(TagField.lyrics, minLines: 12),
        if (_track.lyricsPath != null) ...[
          const SizedBox(height: 8),
          TagNote(icon: Icons.info_outline_rounded, text: l.tagLyricsFileNote),
        ],
      ],
    );
  }

  Widget _coverSection() {
    final folder = _opened?.folderCover;
    return EmbeddedCoverEditor(
      current: _tags?.cover,
      choice: _cover,
      readOnly: !_writable,
      onPick: widget.actions.pickImage == null
          ? null
          : () => unawaited(_pickCover()),
      folderName: folder == null ? null : p.basename(folder),
      onFolder: folder == null
          ? null
          : () => unawaited(
              _useCover(folder, ScaffoldMessenger.maybeOf(context)),
            ),
      onRemove: () => setState(() => _cover = const CoverChoice.remove()),
      onKeep: () => setState(() => _cover = const CoverChoice.keep()),
    );
  }

  Widget _tab(String label, bool changed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(label, maxLines: 1)),
      if (changed) ...[const SizedBox(width: 6), const ChangedMark()],
    ],
  );

  Widget _tabs() {
    final l = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_Section>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: _Section.details,
            label: _tab(l.tagDetails, _detailsChanged),
          ),
          ButtonSegment(
            value: _Section.lyrics,
            label: _tab(l.lyricsTab, _isChanged(TagField.lyrics)),
          ),
          ButtonSegment(
            value: _Section.cover,
            label: _tab(l.coverTab, _cover.changed),
          ),
        ],
        selected: {_section},
        onSelectionChanged: (value) => setState(() => _section = value.single),
      ),
    );
  }

  Widget? _arrows() {
    if (widget.tracks.length < 2) return null;
    final l = context.l10n;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l.tagPreviousTrack,
          onPressed: _index > 0 ? () => unawaited(_go(-1)) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          l.tagPosition(_index + 1, widget.tracks.length),
          style: theme.textTheme.bodySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          tooltip: l.tagNextTrack,
          onPressed: _index < widget.tracks.length - 1
              ? () => unawaited(_go(1))
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _facts() {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final track = _track;
    final rate = _audio?.sampleRate;
    final bitrate = _audio?.bitrate;
    final facts = [
      _tags?.format ?? track.format,
      if (rate != null && rate > 0)
        '${NumberFormat('0.#', locale).format(rate / 1000)} kHz',
      if (bitrate != null && bitrate > 0) '${(bitrate / 1000).round()} kbps',
    ].where((f) => f.isNotEmpty).join(' · ');
    return Text(
      '$facts\n${track.path}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tags = _tags;
    final note = tags == null ? null : tagReadOnlyNote(l, tags);
    final changedCount = _changed.length + (_cover.changed ? 1 : 0);
    final body = tags == null
        ? const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note != null) ...[
                TagNote(icon: Icons.lock_outline_rounded, text: note),
                const SizedBox(height: 12),
              ],
              switch (_section) {
                _Section.details => _details(),
                _Section.lyrics => _lyrics(),
                _Section.cover => _coverSection(),
              },
            ],
          );
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: EditorTemplate(
        title: note == null ? l.tagEditTitle : l.tagsReadOnlyTitle,
        subtitle:
            '$_shownTitle · '
            '${artistName(_tags?.values[TagField.artist] ?? _track.artist, context)}',
        headerAction: _arrows(),
        tabs: _tabs(),
        body: body,
        footer: _facts(),
        status: changedCount == 0 ? null : l.tagChangedCount(changedCount),
        closeLabel: l.cancel,
        onClose: () => unawaited(_close()),
        saveLabel: note == null ? l.save : null,
        onSave: _dirty ? () => unawaited(_saveAndClose()) : null,
      ),
    );
  }
}

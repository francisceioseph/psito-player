// lib/src/ui/organisms/album_tag_editor.dart
//
// Editar um álbum: os campos dele valem para todas as faixas, e a tabela arruma
// número, título e artista de cada uma.
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../library/tag_edit/tag_edit.dart';
import '../../library/tag_edit/tag_files.dart';
import '../format.dart';
import '../molecules/embedded_cover_editor.dart';
import '../molecules/tag_fields.dart';
import '../player_actions.dart';
import '../templates/editor_template.dart';
import 'tag_batch_dialog.dart' show commonTagValue;
import 'tag_editor_dialog.dart';
import 'tag_write_feedback.dart';

Future<void> showAlbumTagEditor(
  BuildContext context,
  PlayerActions actions,
  Album album,
) async {
  final all = await actions.library.store.albumTracks(album.id);
  if (!context.mounted || all.isEmpty) return;
  // As faixas de uma cue sheet moram num texto, e ficam como estão
  final tracks = all.where((t) => !t.isCue).toList();
  if (tracks.isEmpty) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(context.l10n.tagCueReadOnly)));
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) =>
        AlbumTagEditor(actions: actions, album: album, tracks: tracks),
  );
}

/// O título que o nome do arquivo sugere: sem a extensão e sem o número da frente.
String titleFromFileName(String path) {
  final name = p.basenameWithoutExtension(path);
  final title = name.replaceFirst(RegExp(r'^\s*\d+\s*[-._)]*\s*'), '').trim();
  return title.isEmpty ? name : title;
}

const _albumFields = [
  TagField.album,
  TagField.albumArtist,
  TagField.year,
  TagField.genre,
  TagField.discTotal,
];

class _Row {
  final key = UniqueKey();
  final Track track;
  final EditableTags tags;
  final TextEditingController number;
  final TextEditingController title;
  final TextEditingController artist;

  _Row(this.track, this.tags)
    : number = TextEditingController(
        text: tags.values[TagField.trackNumber] ?? '',
      ),
      title = TextEditingController(text: tags.values[TagField.title] ?? ''),
      artist = TextEditingController(text: tags.values[TagField.artist] ?? '');

  bool get writable => tags.writable == Writable.yes;
  int get disc => int.tryParse(tags.values[TagField.discNumber] ?? '') ?? 1;

  void dispose() {
    number.dispose();
    title.dispose();
    artist.dispose();
  }
}

typedef _AlbumFiles = (List<EditableTags>, TagPicture?, String?);

_AlbumFiles _readAlbum(List<String> paths) {
  final tags = [for (final path in paths) readEditableTags(path, cover: false)];
  return (
    tags,
    readEditableTags(paths.first).cover,
    folderCoverOf(paths.first),
  );
}

// Fora da classe: o que vai para outro isolate só leva dados
Future<_AlbumFiles> _readAlbumInIsolate(List<String> paths) =>
    Isolate.run(() => _readAlbum(paths));

class AlbumTagEditor extends StatefulWidget {
  final PlayerActions actions;
  final Album album;
  final List<Track> tracks;

  const AlbumTagEditor({
    super.key,
    required this.actions,
    required this.album,
    required this.tracks,
  });

  @override
  State<AlbumTagEditor> createState() => _AlbumTagEditorState();
}

class _AlbumTagEditorState extends State<AlbumTagEditor> {
  final _controllers = {
    for (final field in _albumFields) field: TextEditingController(),
  };
  final _initial = <TagField, String>{};
  final _varied = <TagField>{};
  List<_Row>? _rows;
  TagPicture? _currentCover;
  String? _folderCover;
  CoverChoice _cover = const CoverChoice.keep();
  bool _numbered = false;

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
    for (final row in _rows ?? const <_Row>[]) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final paths = [for (final t in widget.tracks) t.path];
    final (tags, cover, folder) = await _readAlbumInIsolate(paths);
    if (!mounted) return;
    setState(() {
      _rows = [
        for (var i = 0; i < tags.length; i++) _Row(widget.tracks[i], tags[i]),
      ];
      _currentCover = cover;
      _folderCover = folder;
      for (final field in _albumFields) {
        final common = commonTagValue(tags, field);
        _initial[field] = common.value;
        _controllers[field]!.text = common.value;
        if (common.varied) _varied.add(field);
      }
    });
  }

  void _rebuild([String _ = '']) => setState(() {});

  bool _fieldChanged(TagField field) =>
      _controllers[field]!.text.trim() != (_initial[field] ?? '');

  bool _rowChanged(_Row row, TagField field, TextEditingController c) =>
      c.text.trim() != (row.tags.values[field] ?? '');

  /// A mudança de cada arquivo que dá para gravar.
  Map<String, TagEdit> get _edits {
    final rows = _rows ?? const <_Row>[];
    final common = {
      for (final field in _albumFields)
        if (_fieldChanged(field)) field: _controllers[field]!.text.trim(),
    };
    final out = <String, TagEdit>{};
    final perDisc = <int, int>{};
    for (final row in rows) {
      perDisc[row.disc] = (perDisc[row.disc] ?? 0) + 1;
    }
    for (final row in rows.where((r) => r.writable)) {
      final fields = <TagField, String?>{...common};
      for (final (field, controller) in [
        (TagField.trackNumber, row.number),
        (TagField.title, row.title),
        (TagField.artist, row.artist),
      ]) {
        if (_rowChanged(row, field, controller)) {
          fields[field] = controller.text.trim();
        }
      }
      // Quem já dizia o total continua certo depois de numerar
      final total = row.tags.values[TagField.trackTotal];
      if (_numbered && total != null && total != '${perDisc[row.disc]}') {
        fields[TagField.trackTotal] = '${perDisc[row.disc]}';
      }
      if (fields.isEmpty && !_cover.changed) continue;
      out[row.track.path] = TagEdit(
        fields: fields,
        coverChanged: _cover.changed,
        cover: _cover.picture,
      );
    }
    return out;
  }

  bool get _dirty => _edits.isNotEmpty;

  void _numberInOrder() => setState(() {
    final next = <int, int>{};
    for (final row in _rows ?? const <_Row>[]) {
      if (!row.writable) continue;
      final n = next[row.disc] = (next[row.disc] ?? 0) + 1;
      row.number.text = '$n';
    }
    _numbered = true;
  });

  void _titlesFromFiles() => setState(() {
    for (final row in _rows ?? const <_Row>[]) {
      if (row.writable) row.title.text = titleFromFileName(row.track.path);
    }
  });

  void _move(int from, int to) {
    final rows = _rows;
    if (rows == null) return;
    setState(() {
      final row = rows.removeAt(from);
      rows.insert(to.clamp(0, rows.length), row);
    });
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    unawaited(saveTagEdits(context, widget.actions, _edits));
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
    final path = await widget.actions.pickImage?.call(l.tagCoverChoose);
    if (path != null) await _useCover(path);
  }

  Future<void> _useCover(String path) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final picture = await loadCoverImage(path);
    if (!mounted) return;
    if (picture == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l.coverUnreadable)));
      return;
    }
    setState(() => _cover = CoverChoice.replace(picture));
  }

  String? _hint(TagField field) =>
      _varied.contains(field) ? context.l10n.tagVariousValues : null;

  Widget _albumField(TagField field, {bool number = false}) => TagTextField(
    label: tagFieldLabel(context.l10n, field),
    controller: _controllers[field]!,
    changed: _fieldChanged(field),
    number: number,
    hint: _hint(field),
    onChanged: _rebuild,
  );

  Widget _head() {
    final l = context.l10n;
    final fields = TagFieldGrid(
      columns: 3,
      fields: [
        (_albumField(TagField.album), false),
        (_albumField(TagField.albumArtist), false),
        (_albumField(TagField.year, number: true), false),
        (
          TagGenreField(
            label: l.tagGenre,
            controller: _controllers[TagField.genre]!,
            genres: widget.actions.library.genres,
            changed: _fieldChanged(TagField.genre),
            hint: _hint(TagField.genre),
            onChanged: _rebuild,
          ),
          false,
        ),
        (_albumField(TagField.discTotal, number: true), false),
      ],
    );
    final cover = EmbeddedCoverEditor(
      compact: true,
      current: _currentCover,
      choice: _cover,
      readOnly: false,
      onPick: widget.actions.pickImage == null
          ? null
          : () => unawaited(_pickCover()),
      folderName: _folderCover == null ? null : p.basename(_folderCover!),
      onFolder: _folderCover == null
          ? null
          : () => unawaited(_useCover(_folderCover!)),
      onRemove: () => setState(() => _cover = const CoverChoice.remove()),
      onKeep: () => setState(() => _cover = const CoverChoice.keep()),
    );
    final size = MediaQuery.sizeOf(context);
    if (size.width >= EditorTemplate.fullScreenMaxWidth) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cover,
            const SizedBox(width: 24),
            Expanded(child: fields),
          ],
        ),
      );
    }
    return ExpansionTile(
      initiallyExpanded: size.height >= 640,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6, bottom: 8),
      title: Text(l.tagAlbumFields),
      children: [cover, const SizedBox(height: 12), fields],
    );
  }

  /// Com o cabeçalho da tabela, o rótulo fica só para o leitor de tela.
  InputDecoration _cell(String label, bool wide) => wide
      ? const InputDecoration(isDense: true)
      : InputDecoration(labelText: label, isDense: true);

  Widget _tableHeader() {
    final l = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          const SizedBox(width: 56),
          SizedBox(width: 80, child: Text(l.tagColumnNumber, style: style)),
          Expanded(flex: 3, child: Text(l.tagTitle, style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(l.tagArtist, style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(l.tagColumnFile, style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final rows = _rows!;
    final row = rows[i];
    final readOnly = !row.writable;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    Widget text(TextEditingController c, String label) => Semantics(
      label: label,
      child: TextField(
        controller: c,
        readOnly: readOnly,
        onChanged: _rebuild,
        decoration: _cell(label, wide),
      ),
    );
    return Padding(
      key: row.key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: i,
            child: Tooltip(
              message: l.dragToReorder,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle_rounded),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Semantics(
              label: l.tagTrackNumber,
              child: TextField(
                controller: row.number,
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _rebuild,
                decoration: _cell(l.tagColumnNumber, wide),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: wide
                ? text(row.title, l.tagTitle)
                : Column(
                    children: [
                      text(row.title, l.tagTitle),
                      const SizedBox(height: 4),
                      text(row.artist, l.tagArtist),
                    ],
                  ),
          ),
          if (wide) ...[
            const SizedBox(width: 8),
            Expanded(flex: 2, child: text(row.artist, l.tagArtist)),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                p.basename(row.track.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (readOnly)
            Tooltip(
              message: tagReadOnlyNote(l, row.tags) ?? '',
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.lock_outline_rounded, size: 18),
              ),
            ),
          PopupMenuButton<VoidCallback>(
            tooltip: l.moreOptions,
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              if (i > 0)
                PopupMenuItem(
                  value: () => _move(i, i - 1),
                  child: Text(l.moveUp),
                ),
              if (i < rows.length - 1)
                PopupMenuItem(
                  value: () => _move(i, i + 1),
                  child: Text(l.moveDown),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _table() {
    final l = context.l10n;
    final rows = _rows!;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: rows.length,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _head(),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.songs, style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _numberInOrder,
                icon: const Icon(Icons.format_list_numbered_rounded),
                label: Text(l.tagNumberInOrder),
              ),
              TextButton.icon(
                onPressed: _titlesFromFiles,
                icon: const Icon(Icons.title_rounded),
                label: Text(l.tagTitleFromFile),
              ),
            ],
          ),
          TagNote(icon: Icons.info_outline_rounded, text: l.tagAlbumDragHint),
          const SizedBox(height: 8),
          if (MediaQuery.sizeOf(context).width >= 720) _tableHeader(),
        ],
      ),
      onReorderItem: _move,
      itemBuilder: _row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final album = widget.album;
    final edits = _edits;
    final rows = _rows;
    return PopScope(
      canPop: edits.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: EditorTemplate(
        title: l.tagEditAlbumTitle,
        subtitle: [
          album.title,
          artistName(album.artist, context),
          l.trackCount(widget.tracks.length),
        ].join(' · '),
        width: 1040,
        fill: true,
        body: rows == null
            ? const Center(child: CircularProgressIndicator())
            : _table(),
        status: edits.isEmpty ? null : l.tagFilesToWrite(edits.length),
        closeLabel: l.cancel,
        onClose: () => unawaited(_close()),
        saveLabel: l.save,
        onSave: edits.isEmpty ? null : () => unawaited(_save()),
      ),
    );
  }
}

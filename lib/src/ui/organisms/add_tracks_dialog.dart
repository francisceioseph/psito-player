// lib/src/ui/organisms/add_tracks_dialog.dart
//
// Escolher músicas da biblioteca para uma playlist, sem sair dela: uma a uma, todas
// as da busca ou por pasta. A playlist nova nasce aqui, com o nome em cima.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/library_store.dart';
import '../../library/models.dart';
import '../../library/pick_folders.dart';
import '../atoms/cover_art.dart';
import '../format.dart';
import '../atoms/search_field.dart';

typedef NewPlaylist = ({String name, List<String> paths});

/// Os caminhos marcados, ou null se cancelaram.
Future<List<String>?> showAddTracks(
  BuildContext context,
  LibraryController library, {
  Set<String> existing = const {},
}) async {
  final picked = await showDialog<NewPlaylist>(
    context: context,
    builder: (_) => _AddTracksDialog(
      store: library.store,
      roots: [for (final folder in library.folders) folder.path],
      existing: existing,
      creating: false,
    ),
  );
  return picked?.paths;
}

/// O nome e o que marcaram, que pode ser nada. Null se cancelaram.
Future<NewPlaylist?> showNewPlaylist(
  BuildContext context,
  LibraryController library,
) => showDialog<NewPlaylist>(
  context: context,
  builder: (_) => _AddTracksDialog(
    store: library.store,
    roots: [for (final folder in library.folders) folder.path],
    existing: const {},
    creating: true,
  ),
);

enum _PickTab { songs, folders }

class _AddTracksDialog extends StatefulWidget {
  final LibraryStore store;
  final List<String> roots;
  final Set<String> existing;
  final bool creating;

  const _AddTracksDialog({
    required this.store,
    required this.roots,
    required this.existing,
    required this.creating,
  });

  @override
  State<_AddTracksDialog> createState() => _AddTracksDialogState();
}

class _AddTracksDialogState extends State<_AddTracksDialog> {
  static const _debounce = Duration(milliseconds: 150);
  static const _rowHeight = 60.0;

  /// Abaixo desta altura, a lista não tem como dividir o espaço: tudo rola junto.
  static const _scrollBelow = 480.0;
  static const _maxIndent = 4;

  final _selected = <String>{};
  final _name = TextEditingController();
  var _all = const <Track>[];
  var _tracks = const <Track>[];
  var _folders = const <PickFolder>[];
  var _tab = _PickTab.songs;
  var _query = '';

  /// O nome que veio de uma pasta: a pessoa digitar outro vale mais.
  var _suggested = '';
  Timer? _timer;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    unawaited(_loadAll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final all = await widget.store.tracks(const TrackQuery());
    if (!mounted) return;
    setState(() {
      _all = all;
      _folders = pickFolders(all, widget.roots);
      if (_query.trim().isEmpty) _tracks = all;
    });
  }

  Future<void> _load(String query) async {
    final request = ++_request;
    final found = query.trim().isEmpty
        ? _all
        : await widget.store.searchTracks(query);
    if (mounted && request == _request) setState(() => _tracks = found);
  }

  void _onQuery(String query) {
    setState(() => _query = query);
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_load(query)));
  }

  List<String> _addable(Iterable<String> paths) => [
    for (final path in paths)
      if (!widget.existing.contains(path)) path,
  ];

  /// Marcada, em parte (null) ou não.
  bool? _state(List<String> paths) {
    final marked = paths.where(_selected.contains).length;
    if (marked == 0) return false;
    return marked == paths.length ? true : null;
  }

  void _afterChange() {
    if (_selected.isEmpty && _name.text == _suggested) {
      _name.clear();
      _suggested = '';
    }
  }

  void _toggle(String path, bool? on) => setState(() {
    if (on ?? false) {
      _selected.add(path);
    } else {
      _selected.remove(path);
    }
    _afterChange();
  });

  void _toggleAll(List<String> paths) => setState(() {
    if (_state(paths) ?? false) {
      _selected.removeAll(paths);
    } else {
      _selected.addAll(paths);
    }
    _afterChange();
  });

  void _toggleFolder(PickFolder folder, List<String> paths) {
    _toggleAll(paths);
    if (!widget.creating || _selected.isEmpty) return;
    if (_state(paths) == true && _name.text.trim() == _suggested) {
      _suggested = folder.name;
      _name.text = folder.name;
    }
  }

  void _clear() => setState(() {
    _selected.clear();
    _afterChange();
  });

  bool get _canConfirm =>
      widget.creating ? _name.text.trim().isNotEmpty : _selected.isNotEmpty;

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context)
        .pop((name: _name.text.trim(), paths: _selected.toList()));
  }

  List<PickFolder> get _shownFolders {
    final words = foldedText(_query).split(' ').where((w) => w.isNotEmpty);
    return [
      for (final folder in _folders)
        if (words.every(foldedText(folder.name).contains)) folder,
    ];
  }

  Widget _trackRow(BuildContext context, int i) {
    final l = context.l10n;
    final track = _tracks[i];
    final artist = artistName(track.artist, context);
    final there = widget.existing.contains(track.path);
    return CheckboxListTile(
      mouseCursor: WidgetStateMouseCursor.clickable,
      value: _selected.contains(track.path),
      onChanged: (on) => _toggle(track.path, on),
      controlAffinity: ListTileControlAffinity.leading,
      secondary: CoverArt(
        path: track.coverPath,
        seed: '${track.album}|${track.artist}',
        size: 40,
        radius: 8,
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        there ? l.alreadyInPlaylist : '$artist · ${track.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _folderRow(BuildContext context, PickFolder folder) {
    final l = context.l10n;
    final paths = _addable(folder.paths);
    final count = l.trackCount(folder.paths.length);
    // Na busca, a pasta aparece fora da árvore: diz de onde ela vem
    final searching = _query.trim().isNotEmpty;
    final depth = searching ? 0 : folder.depth.clamp(0, _maxIndent);
    return CheckboxListTile(
      mouseCursor: WidgetStateMouseCursor.clickable,
      tristate: true,
      value: paths.isEmpty ? false : _state(paths),
      onChanged: paths.isEmpty ? null : (_) => _toggleFolder(folder, paths),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsetsDirectional.only(
        start: 16.0 + 16 * depth,
        end: 16,
      ),
      secondary: const Icon(Icons.folder_rounded),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        paths.isEmpty
            ? l.alreadyInPlaylist
            : searching && folder.location.isNotEmpty
            ? '${folder.location} · $count'
            : count,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _list(BuildContext context) {
    final l = context.l10n;
    if (_tab == _PickTab.folders) {
      final folders = _shownFolders;
      if (folders.isEmpty) return Center(child: Text(l.nothingHere));
      return ListView.builder(
        itemExtent: _rowHeight,
        itemCount: folders.length,
        itemBuilder: (context, i) => _folderRow(context, folders[i]),
      );
    }
    if (_tracks.isEmpty) return Center(child: Text(l.nothingHere));
    return ListView.builder(
      itemExtent: _rowHeight,
      itemCount: _tracks.length,
      itemBuilder: _trackRow,
    );
  }

  Widget? _markAll(BuildContext context) {
    if (_tab != _PickTab.songs) return null;
    final paths = _addable(_tracks.map((track) => track.path));
    if (paths.isEmpty) return null;
    return CheckboxListTile(
      mouseCursor: WidgetStateMouseCursor.clickable,
      tristate: true,
      dense: true,
      value: _state(paths),
      onChanged: (_) => _toggleAll(paths),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        context.l10n.markAll(paths.length),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _content(BuildContext context, {required bool scrolls}) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final markAll = _markAll(context);
    final list = _list(context);
    final n = _selected.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: scrolls ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Text(
          widget.creating ? l.newPlaylist : l.addTracks,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (widget.creating) ...[
          TextField(
            autofocus: true,
            controller: _name,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(labelText: l.playlistName),
          ),
          const SizedBox(height: 8),
        ],
        SearchField(
          autofocus: !widget.creating,
          onChanged: _onQuery,
          hint: _tab == _PickTab.songs
              ? l.searchTracksHint
              : l.searchFoldersHint,
        ),
        const SizedBox(height: 8),
        SegmentedButton<_PickTab>(
          segments: [
            ButtonSegment(
              value: _PickTab.songs,
              label: Text(
                l.songs,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ButtonSegment(
              value: _PickTab.folders,
              label: Text(
                l.folders,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          selected: {_tab},
          onSelectionChanged: (tab) => setState(() => _tab = tab.first),
        ),
        ?markAll,
        const SizedBox(height: 4),
        if (scrolls)
          SizedBox(height: _rowHeight * 3, child: list)
        else
          Expanded(child: list),
        const SizedBox(height: 8),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          children: [
            if (n > 0)
              TextButton(onPressed: _clear, child: Text(l.clearSelection)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: _canConfirm ? _confirm : null,
              child: Text(switch ((widget.creating, n)) {
                (true, 0) => l.create,
                (true, _) => l.createWithTracks(n),
                (false, _) => l.addTracksConfirm(n),
              }),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).height < _scrollBelow + 48;
    return Dialog(
      insetPadding: small
          ? const EdgeInsets.all(8)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scrolls = constraints.maxHeight < _scrollBelow;
            final padding = EdgeInsets.all(small ? 8 : 24);
            return scrolls
                ? SingleChildScrollView(
                    padding: padding,
                    child: _content(context, scrolls: true),
                  )
                : Padding(
                    padding: padding,
                    child: _content(context, scrolls: false),
                  );
          },
        ),
      ),
    );
  }
}

// lib/src/ui/organisms/add_tracks_dialog.dart
//
// Escolher músicas da biblioteca para uma playlist, sem sair dela: a busca em cima
// e quantas quiser marcadas na lista.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/library_store.dart';
import '../../library/models.dart';
import '../atoms/cover_art.dart';
import '../format.dart';

/// Os caminhos marcados, ou null se cancelaram.
Future<List<String>?> showAddTracks(
  BuildContext context,
  LibraryController library, {
  Set<String> existing = const {},
}) => showDialog<List<String>>(
  context: context,
  builder: (_) => _AddTracksDialog(store: library.store, existing: existing),
);

class _AddTracksDialog extends StatefulWidget {
  final LibraryStore store;
  final Set<String> existing;

  const _AddTracksDialog({required this.store, required this.existing});

  @override
  State<_AddTracksDialog> createState() => _AddTracksDialogState();
}

class _AddTracksDialogState extends State<_AddTracksDialog> {
  static const _debounce = Duration(milliseconds: 150);
  static const _rowHeight = 60.0;

  final _selected = <String>{};
  var _tracks = const <Track>[];
  Timer? _timer;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load(''));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load(String query) async {
    final request = ++_request;
    final found = query.trim().isEmpty
        ? await widget.store.tracks(const TrackQuery())
        : (await widget.store.search(query)).tracks;
    if (mounted && request == _request) setState(() => _tracks = found);
  }

  void _onQuery(String query) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_load(query)));
  }

  void _toggle(String path, bool? on) => setState(() {
    if (on ?? false) {
      _selected.add(path);
    } else {
      _selected.remove(path);
    }
  });

  Widget _row(BuildContext context, int i) {
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.addTracks, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                onChanged: _onQuery,
                decoration: InputDecoration(
                  labelText: l.searchTracksHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _tracks.isEmpty
                    ? Center(child: Text(l.nothingHere))
                    : ListView.builder(
                        itemExtent: _rowHeight,
                        itemCount: _tracks.length,
                        itemBuilder: _row,
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selected.toList()),
                    child: Text(l.addTracksConfirm(_selected.length)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/src/ui/organisms/organize_dialog.dart
//
// Organizar os arquivos pelas tags, ou copiar para outra pasta. Nada acontece antes
// de a pessoa ver a lista do que muda.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/player_localizations.dart';
import '../../library/library_controller.dart';
import '../../library/models.dart';
import '../../library/organize/file_organizer.dart';
import '../atoms/tag_chip.dart';
import '../format.dart';
import '../player_actions.dart';
import '../templates/editor_template.dart';
import 'tag_editor_dialog.dart' show TagNote;
import 'tag_write_feedback.dart';

const _patternKey = 'organizePattern';

/// Organiza as faixas de [tracks], ou as da pasta [folder].
Future<void> showOrganize(
  BuildContext context,
  PlayerActions actions, {
  List<Track>? tracks,
  MusicFolder? folder,
}) => _show(context, actions, tracks: tracks, folder: folder, copy: false);

/// Copia as faixas para uma pasta que a pessoa escolhe.
Future<void> showCopyFiles(
  BuildContext context,
  PlayerActions actions, {
  List<Track>? tracks,
  MusicFolder? folder,
}) => _show(context, actions, tracks: tracks, folder: folder, copy: true);

Future<void> _show(
  BuildContext context,
  PlayerActions actions, {
  List<Track>? tracks,
  MusicFolder? folder,
  required bool copy,
}) async {
  final items = await actions.library.store.organizeItems(
    paths: tracks == null
        ? null
        : [
            for (final t in tracks)
              if (t.id != 0) t.path,
          ],
    folderId: folder?.id,
  );
  final saved = await actions.library.store.setting(_patternKey);
  if (!context.mounted || items.isEmpty) return;
  await showDialog<void>(
    context: context,
    builder: (_) => OrganizeDialog(
      actions: actions,
      items: items,
      copy: copy,
      pattern: saved ?? defaultOrganizePattern,
    ),
  );
}

String moveProblemText(PlayerLocalizations l, MoveProblem problem) =>
    switch (problem) {
      MoveProblem.sameTarget => l.organizeSameTarget,
      MoveProblem.targetExists => l.organizeTargetExists,
      MoveProblem.playing => l.organizePlaying,
      MoveProblem.noSpace => l.organizeNoSpace,
    };

String _tokenLabel(PlayerLocalizations l, OrganizeToken token) =>
    switch (token) {
      OrganizeToken.albumArtist => l.tagAlbumArtist,
      OrganizeToken.artist => l.tagArtist,
      OrganizeToken.album => l.tagAlbum,
      OrganizeToken.year => l.tagYear,
      OrganizeToken.disc => l.tagDisc,
      OrganizeToken.track => l.tagTrack,
      OrganizeToken.title => l.tagTitle,
      OrganizeToken.genre => l.tagGenre,
    };

class OrganizeDialog extends StatefulWidget {
  final PlayerActions actions;
  final List<OrganizeItem> items;
  final bool copy;
  final String pattern;

  const OrganizeDialog({
    super.key,
    required this.actions,
    required this.items,
    required this.copy,
    required this.pattern,
  });

  @override
  State<OrganizeDialog> createState() => _OrganizeDialogState();
}

class _OrganizeDialogState extends State<OrganizeDialog> {
  static const _debounce = Duration(milliseconds: 300);

  late final _pattern = TextEditingController(text: widget.pattern);
  OrganizePlan? _plan;
  String? _destination;
  Timer? _timer;
  int _asked = 0;

  LibraryController get _library => widget.actions.library;
  bool get _valid => organizePatternValid(_pattern.text);

  @override
  void initState() {
    super.initState();
    if (!widget.copy) {
      // O texto de "Desconhecido" pede o idioma, que o initState ainda não tem
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_refresh()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pattern.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    setState(() {});
    _timer = Timer(_debounce, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (!_valid || (widget.copy && _destination == null)) {
      setState(() => _plan = null);
      return;
    }
    final asked = ++_asked;
    final plan = await planOrganizeInIsolate(
      OrganizeRequest(
        items: widget.items,
        pattern: _pattern.text.trim(),
        unknown: context.l10n.organizeUnknown,
        copyTo: widget.copy ? _destination : null,
        playing: widget.actions.playback.current?.path,
      ),
    );
    if (mounted && asked == _asked) setState(() => _plan = plan);
  }

  void _insert(OrganizeToken token) {
    final text = _pattern.text;
    final selection = _pattern.selection;
    final at = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final piece = '{${token.name}}';
    _pattern.value = TextEditingValue(
      text: text.replaceRange(at, end, piece),
      selection: TextSelection.collapsed(offset: at + piece.length),
    );
    _schedule();
  }

  Future<void> _chooseDestination() async {
    final l = context.l10n;
    final path = await widget.actions.pickFolder?.call(l.organizeChooseFolder);
    if (path == null || !mounted) return;
    setState(() => _destination = path);
    await _refresh();
  }

  void _start() {
    final plan = _plan!;
    final navigator = Navigator.of(context);
    unawaited(_library.store.setSetting(_patternKey, _pattern.text.trim()));
    unawaited(runOrganizeFeedback(context, widget.actions, plan));
    navigator.pop();
  }

  String _relative(String path) =>
      prettyPath(path, Platform.environment['HOME']);

  Widget _row(BuildContext context, int i) {
    final theme = Theme.of(context);
    final move = _plan!.moves[i];
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _relative(move.from),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
                Text(
                  _relative(move.to),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (move.problem != null) ...[
            const SizedBox(width: 8),
            TagChip(
              label: moveProblemText(context.l10n, move.problem!),
              icon: Icons.warning_rounded,
              warning: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Numa janela estreita, em uma linha que rola: não sobra altura para várias.
  Widget _chips() {
    final l = context.l10n;
    final chips = [
      for (final token in OrganizeToken.values)
        ActionChip(
          label: Text(_tokenLabel(l, token)),
          onPressed: () => _insert(token),
        ),
    ];
    if (MediaQuery.sizeOf(context).width >= EditorTemplate.fullScreenMaxWidth) {
      return Wrap(spacing: 8, runSpacing: 4, children: chips);
    }
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

  Widget _destinationRow() {
    final l = context.l10n;
    final theme = Theme.of(context);
    final plan = _plan;
    final free = plan?.freeBytes;
    final locale = Localizations.localeOf(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _destination == null
                    ? l.organizeNoFolder
                    : prettyPath(_destination!, Platform.environment['HOME']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (free != null)
                Text(
                  l.organizeFreeSpace(
                    formatSize(free, locale),
                    formatSize(plan!.bytes, locale),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () => unawaited(_chooseDestination()),
          child: Text(l.organizeChooseFolder),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final plan = _plan;
    final ready = plan?.ready.length ?? 0;
    final problems = plan?.problems ?? 0;
    final busy = !_library.canOrganize;
    final moves = plan?.moves ?? const <FileMove>[];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        if (widget.copy) ...[_destinationRow(), const SizedBox(height: 12)],
        TextField(
          controller: _pattern,
          onChanged: (_) => _schedule(),
          decoration: InputDecoration(
            labelText: l.organizePattern,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: _valid ? null : l.organizePatternInvalid,
          ),
        ),
        const SizedBox(height: 8),
        _chips(),
        const SizedBox(height: 8),
        if (busy) ...[
          TagNote(icon: Icons.hourglass_top_rounded, text: l.organizeBusy),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: plan == null
              ? Center(
                  child: widget.copy && _destination == null
                      ? Text(l.organizeNoFolder)
                      : _valid
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                )
              : moves.isEmpty
              ? Center(child: Text(l.organizeNothing))
              : ListView.builder(itemCount: moves.length, itemBuilder: _row),
        ),
      ],
    );
    return EditorTemplate(
      title: widget.copy ? l.organizeCopyTitle : l.organizeTitle,
      subtitle: l.trackCount(widget.items.length),
      width: 1040,
      fill: true,
      body: body,
      status: plan == null
          ? null
          : [
              widget.copy
                  ? l.organizeWillCopy(ready)
                  : l.organizeWillMove(ready),
              if (plan.unchanged > 0) l.organizeUnchanged(plan.unchanged),
              if (problems > 0) l.organizeProblems(problems),
            ].join(' · '),
      closeLabel: l.cancel,
      onClose: () => Navigator.of(context).pop(),
      saveLabel: widget.copy ? l.organizeCopyAction : l.organizeAction,
      onSave: ready > 0 && !busy ? _start : null,
    );
  }
}

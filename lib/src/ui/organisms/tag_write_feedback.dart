// lib/src/ui/organisms/tag_write_feedback.dart
//
// Gravar as tags sem prender a tela: o cartão do progresso, o aviso com Desfazer e
// a lista do que não deu certo.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../l10n/l10n.dart';
import '../../library/library_controller.dart';
import '../../library/organize/file_organizer.dart';
import '../../library/tag_edit/tag_edit.dart';
import '../../library/tag_edit/tag_undo.dart';
import '../../../l10n/player_localizations.dart';
import '../player_actions.dart';

const _resultTime = Duration(seconds: 8);

/// Grava [edits] e avisa como foi.
Future<void> saveTagEdits(
  BuildContext context,
  PlayerActions actions,
  Map<String, TagEdit> edits,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final report = await actions.library.writeTags(
    edits,
    rewrite: _playing(actions),
  );
  if (messenger != null && messenger.mounted) {
    _showResult(messenger, l, actions, report);
  }
}

Set<String> _playing(PlayerActions actions) => {
  ?actions.playback.current?.path,
};

void _showResult(
  ScaffoldMessengerState messenger,
  PlayerLocalizations l,
  PlayerActions actions,
  TagWriteReport report,
) {
  final written = report.written.length;
  final failed = report.failed;
  final undoId = report.undoId;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: _resultTime,
        persist: false,
        content: Builder(
          builder: (context) => Row(
            children: [
              Expanded(
                child: Text(
                  failed.isEmpty
                      ? l.tagsWritten(written)
                      : l.tagsPartly(written, failed.length),
                ),
              ),
              if (failed.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .inversePrimary,
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    unawaited(_showFailures(context, l, failed));
                  },
                  child: Text(l.tagFailuresDetails),
                ),
            ],
          ),
        ),
        action: undoId == null
            ? null
            : SnackBarAction(
                label: l.undo,
                onPressed: () =>
                    unawaited(_undo(messenger, l, actions, undoId)),
              ),
      ),
    );
}

Future<void> _undo(
  ScaffoldMessengerState messenger,
  PlayerLocalizations l,
  PlayerActions actions,
  String id,
) async {
  final report = await actions.library.undoTags(id, rewrite: _playing(actions));
  if (!messenger.mounted) return;
  final failed = report.failed.length;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? l.tagsRestored(report.written.length)
              : l.tagsPartlyRestored(report.written.length, failed),
        ),
      ),
    );
}

/// O motivo de uma falha, para quem usa.
String tagFailureText(
  PlayerLocalizations l,
  TagWriteFailure reason,
  String path,
) => switch (reason) {
  TagWriteFailure.unsupportedFormat => l.tagFailureFormat(
    p.extension(path).replaceFirst('.', '').toUpperCase(),
  ),
  TagWriteFailure.readOnlyDisk => l.tagFailureReadOnly,
  TagWriteFailure.noPermission => l.tagFailurePermission,
  TagWriteFailure.missing => l.tagFailureMissing,
  TagWriteFailure.noSpace => l.tagFailureNoSpace,
  TagWriteFailure.inUse => l.tagFailureInUse,
  TagWriteFailure.changedMeanwhile => l.tagFailureChanged,
  TagWriteFailure.verifyFailed ||
  TagWriteFailure.malformed => l.tagFailureDamaged,
  TagWriteFailure.targetExists => l.organizeTargetExists,
};

/// Move ou copia o que [plan] tem de pronto e avisa como foi.
Future<void> runOrganizeFeedback(
  BuildContext context,
  PlayerActions actions,
  OrganizePlan plan,
) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final report = await actions.library.runOrganize(plan);
  if (messenger == null || !messenger.mounted) return;
  final failed = report.failed;
  final undoId = report.undoId;
  final done = plan.copying
      ? l.organizeCopied(report.done)
      : l.organizeMoved(report.done);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: _resultTime,
        persist: false,
        content: Builder(
          builder: (context) => Row(
            children: [
              Expanded(
                child: Text(
                  failed.isEmpty
                      ? done
                      : '$done · ${l.organizeProblems(failed.length)}',
                ),
              ),
              if (failed.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .inversePrimary,
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    unawaited(_showFailures(context, l, failed));
                  },
                  child: Text(l.tagFailuresDetails),
                ),
            ],
          ),
        ),
        action: undoId == null
            ? null
            : SnackBarAction(
                label: l.undo,
                onPressed: () => unawaited(() async {
                  final undone = await actions.library.undoOrganize(undoId);
                  if (!messenger.mounted) return;
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(l.organizeRestored(undone.done))),
                    );
                }()),
              ),
      ),
    );
}

Future<void> _showFailures(
  BuildContext context,
  PlayerLocalizations l,
  List<TagFileFailed> failed,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l.tagFailuresTitle(failed.length)),
      content: SizedBox(
        width: 520,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final failure in failed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.basename(failure.path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tagFailureText(l, failure.reason, failure.path),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  },
);

/// O progresso de mover ou copiar, que dá para cancelar entre um arquivo e outro.
class FileJobCard extends StatelessWidget {
  final LibraryController library;

  const FileJobCard({super.key, required this.library});

  @override
  Widget build(BuildContext context) {
    final job = library.fileJob;
    if (job == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final at = (job.done + 1).clamp(1, job.total);
    final path = job.path;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.copying
                              ? l.organizeCopying(at, job.total)
                              : l.organizeMoving(at, job.total),
                        ),
                        if (path != null)
                          Text(
                            p.basename(path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: library.cancelFileJob,
                    child: Text(l.cancel),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LinearProgressIndicator(value: job.done / job.total),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O progresso de uma gravação de vários arquivos. Esconder não para a gravação.
class TagWriteCard extends StatefulWidget {
  final LibraryController library;

  const TagWriteCard({super.key, required this.library});

  @override
  State<TagWriteCard> createState() => _TagWriteCardState();
}

class _TagWriteCardState extends State<TagWriteCard> {
  bool _hidden = false;

  @override
  void didUpdateWidget(TagWriteCard old) {
    super.didUpdateWidget(old);
    if (widget.library.tagWrite == null) _hidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final write = widget.library.tagWrite;
    if (write == null || write.$2 < 2 || _hidden) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final theme = Theme.of(context);
    final (done, total) = write;
    final path = widget.library.tagWritePath;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.tagsWriting((done + 1).clamp(1, total), total)),
                        if (path != null)
                          Text(
                            p.basename(path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.tagsHideProgress,
                    onPressed: () => setState(() => _hidden = true),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LinearProgressIndicator(value: done / total),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

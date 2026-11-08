// lib/src/ui/molecules/embedded_cover_editor.dart
//
// A capa embutida: a de agora, a nova ao lado, e trocar, usar a da pasta ou tirar.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../library/tag_edit/tag_edit.dart';

/// O que a pessoa fez com a capa. Sem [changed], fica a que está no arquivo.
class CoverChoice {
  final bool changed;
  final TagPicture? picture;

  const CoverChoice.keep() : changed = false, picture = null;
  const CoverChoice.remove() : changed = true, picture = null;
  const CoverChoice.replace(TagPicture this.picture) : changed = true;
}

class EmbeddedCoverEditor extends StatelessWidget {
  static const artSize = 200.0;
  static const compactArtSize = 136.0;

  /// Só a arte e os botões em ícone, como no editor do álbum.
  final bool compact;

  final TagPicture? current;
  final CoverChoice choice;
  final bool readOnly;
  final VoidCallback? onPick;

  /// Usa a capa da pasta, ou null sem nenhuma lá.
  final VoidCallback? onFolder;
  final String? folderName;
  final VoidCallback onRemove;
  final VoidCallback onKeep;

  const EmbeddedCoverEditor({
    super.key,
    required this.current,
    required this.choice,
    required this.readOnly,
    required this.onPick,
    required this.onFolder,
    this.folderName,
    required this.onRemove,
    required this.onKeep,
    this.compact = false,
  });

  TagPicture? get _shown => choice.changed ? choice.picture : current;

  Widget _compact(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final picture = _shown;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compactArtSize,
          height: compactArtSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: picture == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.hide_image_rounded,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Image.memory(
                    picture.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    semanticLabel: l.coverTab,
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPick != null)
              IconButton(
                tooltip: l.tagCoverChange,
                onPressed: onPick,
                icon: const Icon(Icons.image_rounded),
              ),
            if (onFolder != null)
              IconButton(
                tooltip: l.tagCoverFromFolder(folderName ?? ''),
                onPressed: onFolder,
                icon: const Icon(Icons.folder_rounded),
              ),
            if (picture != null)
              IconButton(
                tooltip: l.tagCoverRemove,
                onPressed: onRemove,
                icon: const Icon(Icons.hide_image_rounded),
              ),
            if (choice.changed)
              IconButton(
                tooltip: l.tagCoverKeep,
                onPressed: onKeep,
                icon: const Icon(Icons.undo_rounded),
              ),
          ],
        ),
      ],
    );
  }

  Widget _art(BuildContext context, TagPicture? picture, String caption) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: artSize,
          height: artSize,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: picture == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.hide_image_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Image.memory(
                    picture.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    semanticLabel: caption,
                    errorBuilder: (_, _, _) =>
                        const Center(child: Icon(Icons.broken_image_rounded)),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(caption, style: theme.textTheme.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact(context);
    final l = context.l10n;
    final hasCover = choice.changed ? choice.picture != null : current != null;
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        if (choice.changed) ...[
          _art(context, choice.picture, l.tagCoverNew),
          _art(context, current, l.tagCoverBefore),
        ] else
          _art(context, current, l.tagCoverCurrent),
        if (!readOnly)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onPick != null)
                  TextButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.image_rounded),
                    label: Text(l.tagCoverChange),
                  ),
                if (onFolder != null)
                  TextButton.icon(
                    onPressed: onFolder,
                    icon: const Icon(Icons.folder_rounded),
                    label: Text(l.tagCoverFromFolder(folderName ?? '')),
                  ),
                if (hasCover)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.hide_image_rounded),
                    label: Text(l.tagCoverRemove),
                  ),
                if (choice.changed)
                  TextButton.icon(
                    onPressed: onKeep,
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(l.tagCoverKeep),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

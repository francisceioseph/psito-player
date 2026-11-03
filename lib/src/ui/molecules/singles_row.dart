// lib/src/ui/molecules/singles_row.dart
//
// A entrada das faixas sozinhas no álbum, acima da grade de álbuns: elas enchiam a
// grade de cartões de uma música só.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class SinglesRow extends StatelessWidget {
  final int count;
  final VoidCallback onOpen;

  const SinglesRow({super.key, required this.count, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: '${l.singles}, ${l.trackCount(count)}',
          excludeSemantics: true,
          child: InkWell(
            mouseCursor: WidgetStateMouseCursor.clickable,
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                spacing: 12,
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    child: const Icon(Icons.music_note_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.singles,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l.singlesHint(l.trackCount(count)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

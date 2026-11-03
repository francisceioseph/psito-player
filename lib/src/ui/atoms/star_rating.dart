// lib/src/ui/atoms/star_rating.dart
//
// A nota de uma faixa: cinco estrelas para clicar, e a marca pequena nas listas.
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;

  /// Clicar na estrela que já é a nota tira a nota.
  final ValueChanged<int> onChanged;

  const StarRating({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: star == rating ? l.clearRating : l.ratingStars(star),
            isSelected: star <= rating,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: size + 4,
              height: size + 12,
            ),
            iconSize: size,
            color: star <= rating ? primary : null,
            icon: Icon(
              star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            onPressed: () => onChanged(star == rating ? 0 : star),
          ),
      ],
    );
  }
}

/// A nota numa linha de lista, só para ler.
class StarBadge extends StatelessWidget {
  final int rating;

  const StarBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: context.l10n.ratingStars(rating),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            Text('$rating', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

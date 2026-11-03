// lib/src/ui/atoms/favorite_button.dart
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class FavoriteButton extends StatelessWidget {
  final bool favorite;
  final ValueChanged<bool> onChanged;
  final double size;

  const FavoriteButton({
    super.key,
    required this.favorite,
    required this.onChanged,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IconButton(
      tooltip: favorite ? l.removeFavorite : l.addFavorite,
      isSelected: favorite,
      color: favorite ? Theme.of(context).colorScheme.primary : null,
      icon: Icon(
        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size,
      ),
      onPressed: () => onChanged(!favorite),
    );
  }
}

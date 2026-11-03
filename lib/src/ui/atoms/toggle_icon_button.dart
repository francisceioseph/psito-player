// lib/src/ui/atoms/toggle_icon_button.dart
//
// Um botão de ícone que liga e desliga, ou marca onde se está: ligado, ganha o
// fundo tonal.
import 'package:flutter/material.dart';

class ToggleIconButton extends StatelessWidget {
  final bool on;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const ToggleIconButton({
    super.key,
    required this.on,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => on
      ? IconButton.filledTonal(
          tooltip: tooltip,
          isSelected: true,
          icon: Icon(icon),
          onPressed: onPressed,
        )
      : IconButton(
          tooltip: tooltip,
          isSelected: false,
          icon: Icon(icon),
          onPressed: onPressed,
        );
}

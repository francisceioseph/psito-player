// lib/src/ui/molecules/settings_rows.dart
//
// As linhas dos Ajustes: uma opção com título e apoio, um título de grupo e uma
// nota.
import 'package:flutter/material.dart';

class SettingsSwitch extends StatelessWidget {
  final String title;
  final String? hint;
  final bool value;

  /// Null é uma opção que ainda não dá para usar.
  final ValueChanged<bool>? onChanged;

  const SettingsSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    mouseCursor: onChanged == null
        ? SystemMouseCursors.basic
        : SystemMouseCursors.click,
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: hint == null ? null : Text(hint!),
    value: value,
    onChanged: onChanged,
  );
}

/// O título de um controle que fica embaixo dele, como os segmentos.
class SettingsLabel extends StatelessWidget {
  final String text;

  const SettingsLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class SettingsNote extends StatelessWidget {
  final String text;

  const SettingsNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Uma linha que leva a outro lugar ou faz uma ação.
class SettingsAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final VoidCallback onTap;

  const SettingsAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    mouseCursor: SystemMouseCursors.click,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: hint == null ? null : Text(hint!),
    onTap: onTap,
  );
}

// lib/src/ui/molecules/settings_rows.dart
//
// As linhas dos Ajustes: uma opção com título e apoio, um título de grupo, uma
// nota, um aviso em cartão e as linhas em tabela.
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

/// Um aviso curto, destacado do texto em volta.
class SettingsCallout extends StatelessWidget {
  final IconData icon;
  final String text;

  const SettingsCallout({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

/// Linhas num bloco só, separadas por um fio que começa depois da margem.
class SettingsTable extends StatelessWidget {
  final List<Widget> children;

  const SettingsTable({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: SettingsTableRow.padding,
                color: theme.colorScheme.outlineVariant,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// Uma linha de [SettingsTable]: o nome à esquerda e o valor à direita. Com
/// [onTap], ela leva a outro lugar, e mostra a seta no fim.
class SettingsTableRow extends StatelessWidget {
  static const padding = 16.0;
  static const minHeight = 44.0;
  static const valueMaxWidth = 160.0;

  final String title;
  final String? value;
  final VoidCallback? onTap;

  const SettingsTableRow({
    super.key,
    required this.title,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            if (value != null) ...[
              const SizedBox(width: 16),
              // Sem o Flexible, que dividiria a linha ao meio: fica junto da margem
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: valueMaxWidth),
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            ],
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: muted),
          ],
        ),
      ),
    );
    return MergeSemantics(
      child: onTap == null
          ? row
          : InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: onTap,
              child: row,
            ),
    );
  }
}

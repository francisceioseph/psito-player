// lib/src/ui/molecules/shortcut_row.dart
//
// Um atalho nos Ajustes, e o diálogo que escuta a tecla nova.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/player_localizations.dart';
import '../../player/player_shortcuts.dart';

String commandName(PlayerCommand command, PlayerLocalizations l) =>
    switch (command) {
      PlayerCommand.playPause => l.commandPlayPause,
      PlayerCommand.seekBack => l.commandSeekBack,
      PlayerCommand.seekForward => l.commandSeekForward,
      PlayerCommand.previous => l.commandPrevious,
      PlayerCommand.next => l.commandNext,
      PlayerCommand.mute => l.commandMute,
      PlayerCommand.search => l.commandSearch,
      PlayerCommand.lyrics => l.commandLyrics,
      PlayerCommand.queue => l.commandQueue,
    };

/// `Ctrl + ←`.
String comboLabel(KeyCombo combo, PlayerLocalizations l) {
  final key = switch (combo.key) {
    LogicalKeyboardKey.space => l.keySpace,
    LogicalKeyboardKey.arrowLeft => '←',
    LogicalKeyboardKey.arrowRight => '→',
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.arrowDown => '↓',
    final other => other.keyLabel.isEmpty ? '?' : other.keyLabel,
  };
  return [
    if (combo.control) 'Ctrl',
    if (combo.alt) 'Alt',
    if (combo.shift) 'Shift',
    key,
  ].join(' + ');
}

class ShortcutRow extends StatelessWidget {
  final PlayerCommand command;
  final KeyCombo combo;
  final VoidCallback onEdit;

  const ShortcutRow({
    super.key,
    required this.command,
    required this.combo,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final name = commandName(command, l);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                comboLabel(combo, l),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: l.changeShortcut(name),
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Espera as teclas novas. Devolve a combinação, ou null se cancelaram. O
/// [conflict] diz quem já usa uma combinação, e ela não é aceita.
Future<KeyCombo?> askShortcut(
  BuildContext context, {
  required PlayerCommand command,
  required PlayerCommand? Function(KeyCombo) conflict,
}) => showDialog<KeyCombo>(
  context: context,
  builder: (_) => _ShortcutDialog(command: command, conflict: conflict),
);

class _ShortcutDialog extends StatefulWidget {
  final PlayerCommand command;
  final PlayerCommand? Function(KeyCombo) conflict;

  const _ShortcutDialog({required this.command, required this.conflict});

  @override
  State<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<_ShortcutDialog> {
  static final _modifiers = {
    ...LogicalKeyboardKey.collapseSynonyms({
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.meta,
    }),
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  String? _problem;

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    final key = event.logicalKey;
    if (_modifiers.contains(key)) return KeyEventResult.handled;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    final combo = KeyCombo.of(event);
    final other = widget.conflict(combo);
    if (other == null) {
      Navigator.of(context).pop(combo);
    } else {
      final l = context.l10n;
      setState(() => _problem = l.shortcutInUse(commandName(other, l)));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: Text(commandName(widget.command, l)),
        content: Text(_problem ?? l.pressKeys),
        actions: [
          TextButton(
            // Sem isto, o Espaço e o Enter aqui apertariam o botão
            focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }
}

// lib/src/player/player_shortcuts.dart
//
// Os atalhos do player. Valem na janela toda, a não ser quando o controle em foco
// usa a mesma tecla: o Espaço aciona o botão em foco, e nada vale durante a
// digitação. O Slider em foco fica com as setas antes de chegarem aqui.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'playback_controller.dart';

/// O que um atalho faz, na ordem dos Ajustes.
enum PlayerCommand {
  playPause,
  seekBack,
  seekForward,
  previous,
  next,
  mute,
  search,
  lyrics,
  queue,
}

/// Uma tecla com os modificadores.
@immutable
class KeyCombo {
  final LogicalKeyboardKey key;
  final bool control;
  final bool shift;
  final bool alt;

  const KeyCombo(
    this.key, {
    this.control = false,
    this.shift = false,
    this.alt = false,
  });

  bool get _pressed {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed == control &&
        keyboard.isShiftPressed == shift &&
        keyboard.isAltPressed == alt &&
        !keyboard.isMetaPressed;
  }

  /// A combinação do [event], com o que está apertado agora.
  factory KeyCombo.of(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    return KeyCombo(
      event.logicalKey,
      control: keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
    );
  }

  Map<String, Object> toJson() => {
    'key': key.keyId,
    if (control) 'control': true,
    if (shift) 'shift': true,
    if (alt) 'alt': true,
  };

  /// Null se o JSON não é de uma combinação.
  static KeyCombo? fromJson(Object? json) {
    if (json is! Map || json['key'] is! int) return null;
    return KeyCombo(
      LogicalKeyboardKey(json['key'] as int),
      control: json['control'] == true,
      shift: json['shift'] == true,
      alt: json['alt'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeyCombo &&
      other.key == key &&
      other.control == control &&
      other.shift == shift &&
      other.alt == alt;

  @override
  int get hashCode => Object.hash(key, control, shift, alt);
}

const defaultShortcuts = <PlayerCommand, KeyCombo>{
  PlayerCommand.playPause: KeyCombo(LogicalKeyboardKey.space),
  PlayerCommand.seekBack: KeyCombo(LogicalKeyboardKey.arrowLeft),
  PlayerCommand.seekForward: KeyCombo(LogicalKeyboardKey.arrowRight),
  PlayerCommand.previous: KeyCombo(LogicalKeyboardKey.arrowLeft, control: true),
  PlayerCommand.next: KeyCombo(LogicalKeyboardKey.arrowRight, control: true),
  PlayerCommand.mute: KeyCombo(LogicalKeyboardKey.keyM),
  PlayerCommand.search: KeyCombo(LogicalKeyboardKey.keyK, control: true),
  PlayerCommand.lyrics: KeyCombo(LogicalKeyboardKey.keyL),
  PlayerCommand.queue: KeyCombo(LogicalKeyboardKey.keyQ),
};

bool _typing(BuildContext? context) =>
    context != null &&
    (context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null);

KeyEventResult handlePlayerKey(
  KeyEvent event,
  PlaybackController playback, {
  Map<PlayerCommand, KeyCombo> shortcuts = defaultShortcuts,
  VoidCallback? onSearch,
  VoidCallback? onLyrics,
  VoidCallback? onQueue,
}) {
  if (event is KeyUpEvent) return KeyEventResult.ignored;
  PlayerCommand? command;
  for (final entry in shortcuts.entries) {
    if (entry.value.key == event.logicalKey && entry.value._pressed) {
      command = entry.key;
      break;
    }
  }
  if (command == null) return KeyEventResult.ignored;
  final repeats =
      command == PlayerCommand.seekBack || command == PlayerCommand.seekForward;
  if (event is! KeyDownEvent && !repeats) return KeyEventResult.ignored;

  final focused = FocusManager.instance.primaryFocus?.context;
  // A busca é a única que vale digitando: é o caminho de volta para ela
  if (command != PlayerCommand.search && _typing(focused)) {
    return KeyEventResult.ignored;
  }
  if (event.logicalKey == LogicalKeyboardKey.space &&
      focused != null &&
      Actions.maybeFind<ActivateIntent>(focused) != null) {
    return KeyEventResult.ignored;
  }
  VoidCallback? action = switch (command) {
    PlayerCommand.search => onSearch,
    PlayerCommand.lyrics => onLyrics,
    PlayerCommand.queue => onQueue,
    PlayerCommand.playPause when playback.state.queue.isNotEmpty =>
      () => unawaited(playback.togglePlay()),
    PlayerCommand.previous when playback.state.queue.isNotEmpty =>
      () => unawaited(playback.previous()),
    PlayerCommand.next when playback.state.queue.isNotEmpty => () => unawaited(
      playback.next(),
    ),
    PlayerCommand.mute => () => unawaited(playback.toggleMute()),
    PlayerCommand.seekBack => () => unawaited(playback.seekBy(-seekStep)),
    PlayerCommand.seekForward => () => unawaited(playback.seekBy(seekStep)),
    _ => null,
  };
  if (action == null) return KeyEventResult.ignored;
  action();
  return KeyEventResult.handled;
}

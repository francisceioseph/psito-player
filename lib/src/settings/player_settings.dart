// lib/src/settings/player_settings.dart
//
// Os Ajustes do player, guardados no banco da biblioteca. Valem só dentro do
// player, que pode ficar diferente do sistema.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../library/library_controller.dart';
import '../library/library_store.dart';
import '../player/player_shortcuts.dart';

/// As cores que os Ajustes oferecem além da que quem abriu o player trouxe.
enum AccentChoice {
  coral(Color(0xFFFF6B4A)),
  amber(Color(0xFFE8A33D)),
  green(Color(0xFF8DB255)),
  teal(Color(0xFF3FB8AF)),
  blue(Color(0xFF5B8DEF)),
  purple(Color(0xFF9C7BEA));

  final Color color;

  const AccentChoice(this.color);
}

class PlayerSettings extends ChangeNotifier {
  static const _key = 'settings';

  /// Até onde o tamanho do texto vai.
  static const minTextScale = 0.85;
  static const maxTextScale = 1.3;

  LibraryStore? _store;

  ThemeMode _themeMode = ThemeMode.dark;
  AccentChoice? _accent;
  bool _compact = false;
  double _textScale = 1;
  bool _reduceMotion = false;
  bool _rememberSession = true;
  bool _playWholeList = true;
  bool _lyricsFiles = true;
  bool _lyricsEmbedded = true;
  bool _refreshOnOpen = true;
  Map<PlayerCommand, KeyCombo> _shortcuts = defaultShortcuts;

  ThemeMode get themeMode => _themeMode;

  /// Null é a cor de quem abriu o player.
  AccentChoice? get accent => _accent;
  bool get compact => _compact;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;
  bool get rememberSession => _rememberSession;
  bool get playWholeList => _playWholeList;
  bool get lyricsFiles => _lyricsFiles;
  bool get lyricsEmbedded => _lyricsEmbedded;
  bool get refreshOnOpen => _refreshOnOpen;
  Map<PlayerCommand, KeyCombo> get shortcuts => _shortcuts;

  set themeMode(ThemeMode value) => _change(() => _themeMode = value);
  set accent(AccentChoice? value) => _change(() => _accent = value);
  set compact(bool value) => _change(() => _compact = value);
  set textScale(double value) => _change(
    () => _textScale = value.clamp(minTextScale, maxTextScale).toDouble(),
  );
  set reduceMotion(bool value) => _change(() => _reduceMotion = value);
  set rememberSession(bool value) => _change(() => _rememberSession = value);
  set playWholeList(bool value) => _change(() => _playWholeList = value);
  set lyricsFiles(bool value) => _change(() => _lyricsFiles = value);
  set lyricsEmbedded(bool value) => _change(() => _lyricsEmbedded = value);
  set refreshOnOpen(bool value) => _change(() => _refreshOnOpen = value);

  /// O comando que já usa [combo], além de [command].
  PlayerCommand? conflict(PlayerCommand command, KeyCombo combo) {
    for (final entry in _shortcuts.entries) {
      if (entry.key != command && entry.value == combo) return entry.key;
    }
    return null;
  }

  void setShortcut(PlayerCommand command, KeyCombo combo) =>
      _change(() => _shortcuts = {..._shortcuts, command: combo});

  void resetShortcuts() => _change(() => _shortcuts = defaultShortcuts);

  void _change(VoidCallback apply) {
    apply();
    notifyListeners();
    final store = _store;
    if (store != null) {
      unawaited(store.setSetting(_key, jsonEncode(_toJson())));
    }
  }

  Map<String, Object?> _toJson() => {
    'themeMode': _themeMode.name,
    'accent': _accent?.name,
    'compact': _compact,
    'textScale': _textScale,
    'reduceMotion': _reduceMotion,
    'rememberSession': _rememberSession,
    'playWholeList': _playWholeList,
    'lyricsFiles': _lyricsFiles,
    'lyricsEmbedded': _lyricsEmbedded,
    'refreshOnOpen': _refreshOnOpen,
    'shortcuts': {
      for (final entry in _shortcuts.entries)
        if (entry.value != defaultShortcuts[entry.key])
          entry.key.name: entry.value.toJson(),
    },
  };

  /// Traz o que estava guardado. O que falta ou não dá para ler fica no padrão.
  Future<void> load(LibraryStore store) async {
    _store = store;
    final saved = await store.setting(_key);
    if (saved == null) return;
    final Object? json;
    try {
      json = jsonDecode(saved);
    } on FormatException catch (e) {
      debugPrint('🎵 ajustes ilegíveis: $e');
      return;
    }
    if (json is! Map) return;
    bool flag(String key, bool fallback) =>
        json is Map && json[key] is bool ? json[key] as bool : fallback;
    _themeMode = ThemeMode.values.asNameMap()[json['themeMode']] ?? _themeMode;
    _accent = AccentChoice.values.asNameMap()[json['accent']];
    _compact = flag('compact', _compact);
    final scale = json['textScale'];
    if (scale is num) {
      _textScale = scale.toDouble().clamp(minTextScale, maxTextScale);
    }
    _reduceMotion = flag('reduceMotion', _reduceMotion);
    _rememberSession = flag('rememberSession', _rememberSession);
    _playWholeList = flag('playWholeList', _playWholeList);
    _lyricsFiles = flag('lyricsFiles', _lyricsFiles);
    _lyricsEmbedded = flag('lyricsEmbedded', _lyricsEmbedded);
    _refreshOnOpen = flag('refreshOnOpen', _refreshOnOpen);
    final shortcuts = json['shortcuts'];
    if (shortcuts is Map) {
      _shortcuts = {
        ...defaultShortcuts,
        for (final command in PlayerCommand.values)
          command:
              KeyCombo.fromJson(shortcuts[command.name]) ??
              defaultShortcuts[command]!,
      };
    }
    notifyListeners();
  }
}

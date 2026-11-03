// lib/src/settings/player_settings.dart
//
// Os Ajustes do player, guardados no banco da biblioteca. Valem só dentro do
// player, que pode ficar diferente do sistema.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../library/library_controller.dart';
import '../library/library_store.dart';
import '../player/engine.dart';
import '../player/equalizer.dart';
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

/// Como o player ocupa a tela.
enum PlayerMode { full, compact, mini }

class PlayerSettings extends ChangeNotifier {
  static const _key = 'settings';

  /// Até onde o tamanho do texto vai.
  static const minTextScale = 0.85;
  static const maxTextScale = 1.3;

  LibraryStore? _store;

  ThemeMode _themeMode = ThemeMode.dark;
  AccentChoice? _accent;
  bool _compact = false;
  bool _railExpanded = true;
  PlayerMode _mode = PlayerMode.full;
  PlayerMode _modeBeforeMini = PlayerMode.full;
  Size? _fullSize;
  double _textScale = 1;
  bool _reduceMotion = false;
  bool _rememberSession = true;
  bool _playWholeList = true;
  bool _gapless = true;
  int _crossfadeSeconds = 0;
  bool _fadeOnPause = false;
  bool _keepAwake = false;
  bool _notifyTrack = false;
  bool _useRatings = false;
  bool _logs = false;
  PlayerReplayGain _replayGain = PlayerReplayGain.off;
  bool _equalizerOn = false;
  List<double> _equalizerGains = flatEqualizer;
  bool _lyricsFiles = true;
  bool _lyricsEmbedded = true;
  bool _refreshOnOpen = true;
  Map<PlayerCommand, KeyCombo> _shortcuts = defaultShortcuts;

  ThemeMode get themeMode => _themeMode;

  /// Null é a cor de quem abriu o player.
  AccentChoice? get accent => _accent;
  bool get compact => _compact;
  bool get railExpanded => _railExpanded;
  PlayerMode get mode => _mode;

  /// O modo para o qual sair do mini volta.
  PlayerMode get modeBeforeMini => _modeBeforeMini;

  /// O tamanho da janela antes de sair do modo completo.
  Size? get fullSize => _fullSize;
  double get textScale => _textScale;
  bool get reduceMotion => _reduceMotion;
  bool get rememberSession => _rememberSession;
  bool get playWholeList => _playWholeList;
  bool get gapless => _gapless;
  int get crossfadeSeconds => _crossfadeSeconds;
  bool get fadeOnPause => _fadeOnPause;
  bool get keepAwake => _keepAwake;
  bool get notifyTrack => _notifyTrack;

  /// Mostra as estrelas. As notas já dadas continuam guardadas e valendo nos mixes.
  bool get useRatings => _useRatings;
  bool get logs => _logs;
  PlayerReplayGain get replayGain => _replayGain;
  bool get equalizerOn => _equalizerOn;
  List<double> get equalizerGains => _equalizerGains;
  bool get lyricsFiles => _lyricsFiles;
  bool get lyricsEmbedded => _lyricsEmbedded;
  bool get refreshOnOpen => _refreshOnOpen;
  Map<PlayerCommand, KeyCombo> get shortcuts => _shortcuts;

  set themeMode(ThemeMode value) => _change(() => _themeMode = value);
  set accent(AccentChoice? value) => _change(() => _accent = value);
  set compact(bool value) => _change(() => _compact = value);
  set railExpanded(bool value) => _change(() => _railExpanded = value);

  /// Troca o modo, lembrando de onde veio. [windowSize] é o tamanho de agora.
  void setMode(PlayerMode value, Size windowSize) => _change(() {
    if (_mode == PlayerMode.full && value != PlayerMode.full) {
      _fullSize = windowSize;
    }
    if (value == PlayerMode.mini && _mode != PlayerMode.mini) {
      _modeBeforeMini = _mode;
    }
    _mode = value;
  });
  set textScale(double value) => _change(
    () => _textScale = value.clamp(minTextScale, maxTextScale).toDouble(),
  );
  set reduceMotion(bool value) => _change(() => _reduceMotion = value);
  set rememberSession(bool value) => _change(() => _rememberSession = value);
  set playWholeList(bool value) => _change(() => _playWholeList = value);
  set gapless(bool value) => _change(() => _gapless = value);
  set crossfadeSeconds(int value) => _change(() => _crossfadeSeconds = value);
  set fadeOnPause(bool value) => _change(() => _fadeOnPause = value);
  set keepAwake(bool value) => _change(() => _keepAwake = value);
  set notifyTrack(bool value) => _change(() => _notifyTrack = value);
  set useRatings(bool value) => _change(() => _useRatings = value);
  set logs(bool value) => _change(() => _logs = value);
  set replayGain(PlayerReplayGain value) => _change(() => _replayGain = value);
  set equalizerOn(bool value) => _change(() => _equalizerOn = value);
  set equalizerGains(List<double> value) =>
      _change(() => _equalizerGains = List.unmodifiable(value));

  void setEqualizerBand(int band, double gain) => equalizerGains = [
    for (var i = 0; i < _equalizerGains.length; i++)
      i == band ? gain : _equalizerGains[i],
  ];

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
    'railExpanded': _railExpanded,
    'mode': _mode.name,
    'modeBeforeMini': _modeBeforeMini.name,
    if (_fullSize case final size?) 'fullSize': [size.width, size.height],
    'textScale': _textScale,
    'reduceMotion': _reduceMotion,
    'rememberSession': _rememberSession,
    'playWholeList': _playWholeList,
    'gapless': _gapless,
    'crossfadeSeconds': _crossfadeSeconds,
    'fadeOnPause': _fadeOnPause,
    'keepAwake': _keepAwake,
    'notifyTrack': _notifyTrack,
    'useRatings': _useRatings,
    'logs': _logs,
    'replayGain': _replayGain.name,
    'equalizerOn': _equalizerOn,
    'equalizerGains': _equalizerGains,
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
    _railExpanded = flag('railExpanded', _railExpanded);
    _mode = PlayerMode.values.asNameMap()[json['mode']] ?? _mode;
    _modeBeforeMini =
        PlayerMode.values.asNameMap()[json['modeBeforeMini']] ??
        _modeBeforeMini;
    if (json['fullSize'] case [final num width, final num height]) {
      _fullSize = Size(width.toDouble(), height.toDouble());
    }
    final scale = json['textScale'];
    if (scale is num) {
      _textScale = scale.toDouble().clamp(minTextScale, maxTextScale);
    }
    _reduceMotion = flag('reduceMotion', _reduceMotion);
    _rememberSession = flag('rememberSession', _rememberSession);
    _playWholeList = flag('playWholeList', _playWholeList);
    _gapless = flag('gapless', _gapless);
    _fadeOnPause = flag('fadeOnPause', _fadeOnPause);
    final crossfade = json['crossfadeSeconds'];
    if (crossfade is int && crossfade >= 0) _crossfadeSeconds = crossfade;
    _keepAwake = flag('keepAwake', _keepAwake);
    _notifyTrack = flag('notifyTrack', _notifyTrack);
    _useRatings = flag('useRatings', _useRatings);
    _logs = flag('logs', _logs);
    _replayGain =
        PlayerReplayGain.values.asNameMap()[json['replayGain']] ?? _replayGain;
    _equalizerOn = flag('equalizerOn', _equalizerOn);
    final gains = json['equalizerGains'];
    if (gains is List &&
        gains.length == equalizerBands.length &&
        gains.every((g) => g is num)) {
      _equalizerGains = List.unmodifiable([
        for (final num gain in gains.cast<num>())
          gain.toDouble().clamp(-equalizerMaxGain, equalizerMaxGain),
      ]);
    }
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

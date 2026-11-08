// lib/src/platform/windows_session.dart
//
// A ligação do player com o Windows: a faixa nos controles de mídia, as teclas de
// volta para o player e não deixar a tela apagar.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../library/models.dart';
import '../player/engine.dart';
import '../player/playback_controller.dart';
import '../settings/player_settings.dart';
import 'desktop_platform.dart';

enum MediaButton { play, pause, next, previous, stop }

/// Os controles de mídia do sistema.
abstract interface class MediaTransport {
  Stream<MediaButton> get buttons;
  Future<void> show({
    required String title,
    required String artist,
    required String album,
    String? cover,
  });
  Future<void> clear();
  Future<void> setPlaying({required bool playing});
  Future<void> setTimeline(Duration position, Duration duration);
  Future<void> close();
}

class WindowsSession implements DesktopSession {
  /// O relógio do Windows anda sozinho: só precisa de acerto de vez em quando.
  @visibleForTesting
  static const timelineStep = Duration(seconds: 5);

  final PlaybackController _playback;
  final PlayerSettings _settings;
  final MediaTransport _transport;
  final void Function(bool on) keepAwake;
  late final StreamSubscription<MediaButton> _buttons;

  Future<void> _pending = Future.value();
  ({String path, String? title})? _shown;
  bool? _playing;
  bool _awake = false;
  Duration _sentPosition = Duration.zero;
  Duration _sentDuration = Duration.zero;

  WindowsSession({
    required PlaybackController playback,
    required PlayerSettings settings,
    required MediaTransport transport,
    required this.keepAwake,
  }) : _playback = playback,
       _settings = settings,
       _transport = transport {
    _buttons = transport.buttons.listen(_onButton);
    playback.engine.state.addListener(_onChange);
    playback.addListener(_onChange);
    settings.addListener(_onChange);
    _onChange();
  }

  /// Um de cada vez, e um erro do Windows não pode parar a música.
  void _send(Future<void> Function() call) {
    _pending = _pending.then((_) async {
      try {
        await call();
      } catch (e) {
        debugPrint('🎵 controles de mídia: $e');
      }
    });
  }

  void _onChange() {
    final s = _playback.state;
    _syncAwake(s);
    final track = _playback.current;
    final title = track == null ? null : _titleOf(track, s);
    final shown = track == null ? null : (path: track.path, title: title);
    if (shown != _shown) {
      _shown = shown;
      _sentDuration = Duration.zero;
      _send(() {
        if (track == null) return _transport.clear();
        return _transport.show(
          title: title!,
          artist: track.artist,
          album: track.album,
          cover: track.coverPath,
        );
      });
    }
    if (s.playing != _playing) {
      _playing = s.playing;
      _send(() => _transport.setPlaying(playing: s.playing));
    }
    _syncTimeline(s);
  }

  /// Fora da biblioteca, quem leu as tags foi o motor.
  String _titleOf(Track track, PlayerState s) =>
      track.id == 0 ? (s.title ?? track.title) : track.title;

  void _syncAwake(PlayerState s) {
    final want = _settings.keepAwake && s.playing;
    if (want == _awake) return;
    _awake = want;
    keepAwake(want);
  }

  void _syncTimeline(PlayerState s) {
    final drift = (s.position - _sentPosition).abs();
    if (s.duration == _sentDuration && drift < timelineStep) return;
    _sentPosition = s.position;
    _sentDuration = s.duration;
    _send(() => _transport.setTimeline(s.position, s.duration));
  }

  void _onButton(MediaButton button) {
    final s = _playback.state;
    final hasTrack = _playback.current != null;
    if (!hasTrack) return;
    _send(() async {
      switch (button) {
        case MediaButton.play when !s.playing:
        case MediaButton.pause when s.playing:
          await _playback.togglePlay();
        case MediaButton.next:
          await _playback.next();
        case MediaButton.previous:
          await _playback.previous();
        case MediaButton.stop:
          if (s.playing) await _playback.togglePlay();
          await _playback.engine.seek(Duration.zero);
        case MediaButton.play || MediaButton.pause:
          break;
      }
    });
  }

  @override
  Future<void> close() async {
    _playback.engine.state.removeListener(_onChange);
    _playback.removeListener(_onChange);
    _settings.removeListener(_onChange);
    await _buttons.cancel();
    if (_awake) keepAwake(false);
    await _pending;
    await _transport.close();
  }
}

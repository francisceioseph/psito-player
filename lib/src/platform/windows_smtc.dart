// lib/src/platform/windows_smtc.dart
//
// Os controles de mídia do Windows, pelo smtc_windows: o painel de volume, as
// teclas de mídia e os fones.
import 'package:smtc_windows/smtc_windows.dart';

import 'windows_session.dart';

class SmtcTransport implements MediaTransport {
  final SMTCWindows _smtc;

  SmtcTransport._(this._smtc);

  /// Lança se a biblioteca nativa não abrir.
  static Future<SmtcTransport> open() async {
    await SMTCWindows.initialize();
    return SmtcTransport._(
      SMTCWindows(
        config: const SMTCConfig(
          playEnabled: true,
          pauseEnabled: true,
          nextEnabled: true,
          prevEnabled: true,
          stopEnabled: true,
          fastForwardEnabled: false,
          rewindEnabled: false,
        ),
      ),
    );
  }

  @override
  Stream<MediaButton> get buttons => _smtc.buttonPressStream
      .map(
        (button) => switch (button) {
          PressedButton.play => MediaButton.play,
          PressedButton.pause => MediaButton.pause,
          PressedButton.next => MediaButton.next,
          PressedButton.previous => MediaButton.previous,
          PressedButton.stop => MediaButton.stop,
          _ => null,
        },
      )
      .where((button) => button != null)
      .cast<MediaButton>();

  @override
  Future<void> show({
    required String title,
    required String artist,
    required String album,
    String? cover,
  }) => _smtc.updateMetadata(
    MusicMetadata(
      title: title,
      artist: artist,
      album: album,
      thumbnail: cover == null
          ? null
          : Uri.file(cover, windows: true).toString(),
    ),
  );

  @override
  Future<void> clear() => _smtc.clearMetadata();

  @override
  Future<void> setPlaying({required bool playing}) => _smtc.setPlaybackStatus(
    playing ? PlaybackStatus.playing : PlaybackStatus.paused,
  );

  @override
  Future<void> setTimeline(Duration position, Duration duration) =>
      _smtc.updateTimeline(
        PlaybackTimeline(
          startTimeMs: 0,
          endTimeMs: duration.inMilliseconds,
          positionMs: position.inMilliseconds,
          minSeekTimeMs: 0,
          maxSeekTimeMs: duration.inMilliseconds,
        ),
      );

  @override
  Future<void> close() => _smtc.dispose();
}

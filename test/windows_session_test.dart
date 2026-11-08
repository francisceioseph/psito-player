// A sessão com o Windows, com controles de mídia falsos.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/platform/windows_session.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/settings/player_settings.dart';

import 'helpers.dart';

class _Transport implements MediaTransport {
  final pressed = StreamController<MediaButton>();
  final shown = <String>[];
  final playing = <bool>[];
  final timeline = <Duration>[];
  var cleared = 0;
  var closed = false;
  Object? failure;

  @override
  Stream<MediaButton> get buttons => pressed.stream;

  @override
  Future<void> show({
    required String title,
    required String artist,
    required String album,
    String? cover,
  }) async {
    if (failure != null) throw failure!;
    shown.add(title);
  }

  @override
  Future<void> clear() async => cleared++;

  @override
  Future<void> setPlaying({required bool playing}) async =>
      this.playing.add(playing);

  @override
  Future<void> setTimeline(Duration position, Duration duration) async =>
      timeline.add(position);

  @override
  Future<void> close() async => closed = true;
}

void main() {
  late FakeEngine engine;
  late PlaybackController playback;
  late PlayerSettings settings;
  late _Transport transport;
  late List<bool> awake;
  late WindowsSession session;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void at(Duration position) =>
      engine.set(engine.state.value.copyWith(position: position));

  setUp(() {
    engine = FakeEngine();
    playback = PlaybackController(
      engine: engine,
      store: DirectStore(LibraryDb.memory()),
    );
    settings = PlayerSettings();
    transport = _Transport();
    awake = [];
    session = WindowsSession(
      playback: playback,
      settings: settings,
      transport: transport,
      keepAwake: awake.add,
    );
  });

  tearDown(() async {
    await session.close();
    settings.dispose();
    playback.dispose();
  });

  test('mostra a faixa e o estado, uma vez cada', () async {
    await engine.open(['/m/a.flac']);
    await settle();
    at(const Duration(milliseconds: 100));
    await settle();
    expect(transport.shown, ['a.flac']);
    expect(transport.playing.last, isTrue);
  });

  test('a posição só vai de tempos em tempos', () async {
    await engine.open(['/m/a.flac']);
    await settle();
    final sent = transport.timeline.length;
    at(const Duration(seconds: 1));
    await settle();
    expect(transport.timeline.length, sent);
    at(WindowsSession.timelineStep);
    await settle();
    expect(transport.timeline.length, sent + 1);
  });

  test('as teclas mandam no player', () async {
    await engine.open(['/m/a.flac', '/m/b.flac']);
    await settle();
    transport.pressed.add(MediaButton.next);
    await settle();
    await settle();
    expect(engine.state.value.index, 1);
    transport.pressed.add(MediaButton.pause);
    await settle();
    await settle();
    expect(engine.state.value.playing, isFalse);
    transport.pressed.add(MediaButton.pause);
    await settle();
    await settle();
    expect(engine.state.value.playing, isFalse);
  });

  test('segura a tela só tocando e com o ajuste ligado', () async {
    await engine.open(['/m/a.flac']);
    await settle();
    expect(awake, isEmpty);
    settings.keepAwake = true;
    expect(awake, [true]);
    await engine.playOrPause();
    expect(awake, [true, false]);
  });

  test('um erro do Windows não atrapalha o que vem depois', () async {
    transport.failure = StateError('recusado');
    await engine.open(['/m/a.flac']);
    await settle();
    transport.failure = null;
    await engine.open(['/m/b.flac']);
    await settle();
    expect(transport.shown, ['b.flac']);
  });

  test('fechar solta a tela e os controles', () async {
    settings.keepAwake = true;
    await engine.open(['/m/a.flac']);
    await settle();
    await session.close();
    expect(awake.last, isFalse);
    expect(transport.closed, isTrue);
  });
}

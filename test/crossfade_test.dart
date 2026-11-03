// test/crossfade_test.dart
//
// O cruzamento de faixas: as contas, quem pode cruzar e o motor de verdade, com a
// libmpv numa saída que não faz som, mas respeita o relógio.
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/player/crossfade.dart';
import 'package:psito_player/src/player/engine.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';
import 'package:psito_player/src/player/playback_controller.dart';

import 'helpers.dart';

const _s = Duration(seconds: 1);

void _tone(String path, Duration length) {
  const rate = 44100;
  final frames = rate * length.inMilliseconds ~/ 1000;
  final data = ByteData(44 + frames * 2);
  void tag(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final value = (sin(2 * pi * 440 * i / rate) * 8000).round();
    data.setInt16(44 + i * 2, value, Endian.little);
  }
  File(path).writeAsBytesSync(data.buffer.asUint8List());
}

Future<void> _until(
  bool Function() done, {
  Duration limit = const Duration(seconds: 10),
}) async {
  final clock = Stopwatch()..start();
  while (!done()) {
    if (clock.elapsed > limit) throw TestFailure('passou de $limit');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  group('o plano', () {
    CrossfadePlan? plan(int position, int duration, int length) =>
        planCrossfade(
          position: _s * position,
          duration: _s * duration,
          length: _s * length,
        );

    test('termina junto com a faixa', () {
      final found = plan(0, 200, 6)!;
      expect(found.fade, _s * 6);
      expect(found.start + found.fade + crossfadeHandover, _s * 200);
    });

    test('numa faixa curta, ocupa no máximo um terço', () {
      expect(plan(0, 9, 6)!.fade, _s * 3);
    });

    test('depois de um salto, usa o que sobrou', () {
      final found = plan(197, 200, 6)!;
      expect(found.start, greaterThan(_s * 197));
      expect(found.fade, lessThan(_s * 3));
    });

    test('sem tempo, ou desligado, não cruza', () {
      expect(plan(199, 200, 6), isNull);
      expect(plan(0, 2, 6), isNull);
      expect(plan(0, 200, 0), isNull);
      expect(plan(0, 0, 6), isNull);
    });
  });

  group('as curvas', () {
    test('a potência somada não afunda no meio', () {
      for (var t = 0.0; t <= 1; t += 0.1) {
        final power = pow(fadeIn(t), 2) + pow(fadeOut(t), 2);
        expect(power, closeTo(1, 1e-9));
      }
    });

    test('o volume do mpv desfaz a curva cúbica dele', () {
      expect(mpvVolume(0.5, 1), 50);
      expect(mpvVolume(1, 0), 0);
      expect(pow(mpvVolume(1, 0.5) / 100, 3), closeTo(0.5, 1e-9));
    });
  });

  group('quem pode cruzar', () {
    late LibraryDb db;
    late PlaybackController playback;

    setUp(() {
      db = LibraryDb.memory();
      playback = PlaybackController(
        engine: FakeEngine(),
        store: DirectStore(db),
      );
    });
    tearDown(() {
      playback.dispose();
      db.close();
    });

    Track track(String path, int album, String title) => Track(
      id: 1,
      path: path,
      title: path,
      format: 'FLAC',
      album: title,
      albumId: album,
    );

    test('o controlador avisa o motor da regra', () {
      final engine = playback.engine as FakeEngine;
      expect(engine.crossfadeRule, isNotNull);
    });

    test('o mesmo álbum fica emendado, e outros cruzam', () async {
      await playback.playTracks([
        track('/a', 1, 'Disco'),
        track('/b', 1, 'Disco'),
        track('/c', 2, 'Outro'),
      ]);
      expect(playback.shouldCrossfade('/a', '/b'), isFalse);
      expect(playback.shouldCrossfade('/b', '/c'), isTrue);
    });

    test('sem álbum, ou de fora da biblioteca, cruza', () async {
      await playback.playTracks([track('/a', 1, ''), track('/b', 1, '')]);
      expect(playback.shouldCrossfade('/a', '/b'), isTrue);
      expect(playback.shouldCrossfade('/nunca', '/vi'), isTrue);
    });
  });

  group('o motor', () {
    late Directory dir;
    late MediaKitEngine engine;
    late List<String> paths;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('cruza');
      paths = [
        for (final name in ['a', 'b']) '${dir.path}/$name.wav',
      ];
      for (final path in paths) {
        _tone(path, const Duration(seconds: 4));
      }
      engine = MediaKitEngine(options: {'ao': 'null'});
    });
    tearDown(() async {
      await engine.dispose();
      dir.deleteSync(recursive: true);
    });

    ValueListenable<PlayerState> state() => engine.state;

    test('desligado, troca só no fim', () async {
      final clock = Stopwatch();
      await engine.open(paths);
      await _until(() => state().value.duration > Duration.zero);
      clock.start();
      await _until(() => state().value.index == 1);
      expect(clock.elapsed, greaterThan(const Duration(seconds: 3)));
    });

    test('ligado, a seguinte entra antes do fim', () async {
      await engine.setCrossfade(_s);
      await engine.open(paths);
      final clock = Stopwatch()..start();
      await _until(() => state().value.index == 1);
      expect(clock.elapsed, lessThan(const Duration(milliseconds: 3400)));
      expect(clock.elapsed, greaterThan(const Duration(seconds: 2)));
      // O volume da pessoa não muda por causa do fade
      expect(state().value.volume, 1);
      await _until(() => state().value.position > const Duration(seconds: 2));
      expect(state().value.volume, 1);
      expect(state().value.playing, isTrue);
    });

    test('a regra segura o par que deve ficar emendado', () async {
      engine.crossfadeRule = (_, _) => false;
      await engine.setCrossfade(_s);
      final clock = Stopwatch();
      await engine.open(paths);
      await _until(() => state().value.duration > Duration.zero);
      clock.start();
      await _until(() => state().value.index == 1);
      expect(clock.elapsed, greaterThan(const Duration(milliseconds: 3400)));
    });

    test('parar depois desta faixa não cruza', () async {
      await engine.setCrossfade(_s);
      await engine.open(paths);
      await engine.setStopAfter(true);
      final clock = Stopwatch()..start();
      await _until(() => !state().value.playing || clock.elapsed > _s * 6);
      expect(clock.elapsed, greaterThan(const Duration(milliseconds: 3400)));
    });

    test('pausar no meio volta ao normal', () async {
      await engine.setCrossfade(_s * 2);
      await engine.open(paths);
      await _until(() => state().value.index == 1);
      await engine.playOrPause();
      await _until(() => !state().value.playing);
      expect(state().value.index, 1);
      expect(state().value.volume, 1);
      await engine.playOrPause();
      await _until(() => state().value.playing);
    });

    test(
      'o fade ao pausar leva o tempo dele e continua de onde parou',
      () async {
        await engine.setFadeOnPause(true);
        await engine.open(paths);
        await _until(() => state().value.position > Duration.zero);
        await engine.playOrPause();
        // A tela já mostra pausado, e o som ainda está baixando
        expect(state().value.playing, isFalse);
        await Future<void>.delayed(pauseFade * 2);
        final stopped = state().value.position;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(state().value.position, stopped);
        await engine.playOrPause();
        await _until(() => state().value.position > stopped);
        expect(state().value.playing, isTrue);
        expect(state().value.volume, 1);
      },
    );
  });
}

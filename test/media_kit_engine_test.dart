// O motor de verdade: a libmpv grava num arquivo o que iria para a saída de som,
// sem barulho e mais rápido que o tempo real. Sem a libmpv, os testes não rodam.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/player/engine.dart';
import 'package:psito_player/src/player/equalizer.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';

const _rate = 44100;
const _peak = 16000;

/// Um quadro TXXX do ID3v2.3, que é onde o ReplayGain mora num WAV.
List<int> _txxx(String name, String value) {
  final body = [0, ...latin1.encode(name), 0, ...latin1.encode(value)];
  final size = ByteData(4)..setUint32(0, body.length);
  return [...ascii.encode('TXXX'), ...size.buffer.asUint8List(), 0, 0, ...body];
}

List<int> _id3(Map<String, String> tags) {
  final frames = [for (final e in tags.entries) ..._txxx(e.key, e.value)];
  final n = frames.length;
  return [
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    (n >> 21) & 0x7f,
    (n >> 14) & 0x7f,
    (n >> 7) & 0x7f,
    n & 0x7f,
    ...frames,
  ];
}

/// Um seno de 440 Hz em WAV mono de 16 bits.
void _writeWav(
  File file,
  int frames, {
  Map<String, String> tags = const {},
  int rate = _rate,
}) {
  final pcm = ByteData(frames * 2);
  for (var i = 0; i < frames; i++) {
    final v = sin(2 * pi * 440 * i / rate) * _peak;
    pcm.setInt16(i * 2, v.round(), Endian.little);
  }
  final id3 = tags.isEmpty ? const <int>[] : _id3(tags);
  final pad = id3.length.isOdd ? 1 : 0;
  final tail = id3.isEmpty ? 0 : 8 + id3.length + pad;
  final head = ByteData(44);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      head.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  head.setUint32(4, 36 + frames * 2 + tail, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  head.setUint32(16, 16, Endian.little);
  head.setUint16(20, 1, Endian.little);
  head.setUint16(22, 1, Endian.little);
  head.setUint32(24, rate, Endian.little);
  head.setUint32(28, rate * 2, Endian.little);
  head.setUint16(32, 2, Endian.little);
  head.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  head.setUint32(40, frames * 2, Endian.little);
  final bytes = BytesBuilder()
    ..add(head.buffer.asUint8List())
    ..add(pcm.buffer.asUint8List());
  if (id3.isNotEmpty) {
    final size = ByteData(4)..setUint32(0, id3.length, Endian.little);
    bytes
      ..add(ascii.encode('id3 '))
      ..add(size.buffer.asUint8List())
      ..add(id3)
      ..add(List.filled(pad, 0));
  }
  file.writeAsBytesSync(bytes.takeBytes());
}

/// O que saiu: as amostras de 16 bits, por canal misturado no primeiro.
class _Output {
  final List<int> samples;

  _Output(this.samples);

  int get peak => samples.fold(0, (m, s) => max(m, s.abs()));

  /// O pico da segunda metade: o começo tem o que o filtro ainda não pegou e o
  /// transitório dele.
  int get settledPeak =>
      samples.skip(samples.length ~/ 2).fold(0, (m, s) => max(m, s.abs()));
}

_Output _read(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  var at = 12;
  var channels = 1;
  var float = false;
  while (at + 8 <= bytes.length) {
    final id = ascii.decode(bytes.sublist(at, at + 4));
    final size = data.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') {
      // O mpv grava o cabeçalho estendido, em que a etiqueta não diz o formato
      float = data.getUint16(at + 22, Endian.little) == 32;
      channels = data.getUint16(at + 10, Endian.little);
    }
    if (id == 'data') {
      at += 8;
      break;
    }
    at += 8 + size;
  }
  return _Output([
    if (float)
      for (var i = at; i + 4 <= bytes.length; i += 4 * channels)
        (data.getFloat32(i, Endian.little) * 32768).round()
    else
      for (var i = at; i + 2 <= bytes.length; i += 2 * channels)
        data.getInt16(i, Endian.little),
  ]);
}

Future<_Output> _play(
  Directory dir,
  List<String> paths, {
  bool? gapless,
  PlayerReplayGain? replayGain,
  List<double>? equalizer,
  bool equalizerAfterOpen = false,
  String format = 's16',
}) async {
  final out = File('${dir.path}/out.wav');
  if (out.existsSync()) out.deleteSync();
  final engine = MediaKitEngine(
    options: {
      'ao': 'pcm',
      'ao-pcm-file': out.path,
      'audio-format': format,
      'audio-samplerate': '$_rate',
      'audio-channels': 'mono',
    },
  );
  if (gapless != null) await engine.setGapless(gapless);
  if (replayGain != null) await engine.setReplayGain(replayGain);
  if (equalizer != null && !equalizerAfterOpen) {
    await engine.setEqualizer(equalizer);
  }
  await engine.open(paths, play: !equalizerAfterOpen);
  if (equalizerAfterOpen) {
    await engine.state.firstLoaded();
    await engine.setEqualizer(equalizer!);
    await engine.playOrPause();
  }
  // Sem relógio, a saída grava tudo de uma vez: o fim é o arquivo parar de crescer
  var last = -1;
  var still = 0;
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (still < 5 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final size = out.existsSync() ? out.lengthSync() : 0;
    still = size == last && size > 44 ? still + 1 : 0;
    last = size;
  }
  await engine.dispose();
  return _read(out);
}

extension on ValueListenable<PlayerState> {
  /// Espera o arquivo abrir.
  Future<void> firstLoaded() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (value.duration == Duration.zero &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}

void main() {
  late Directory dir;
  const second = _rate;

  setUp(() => dir = Directory.systemTemp.createTempSync('psito-engine'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('sem pausa', () {
    late List<String> pair;

    setUp(() {
      pair = [
        for (final n in ['a', 'b']) '${dir.path}/$n.wav',
      ];
      for (final path in pair) {
        _writeWav(File(path), second);
      }
    });

    test('ligado, as duas faixas saem emendadas, sem amostra a mais', () async {
      final out = await _play(dir, pair, gapless: true);
      // A última faixa pode trazer o resto do bloco final do mpv
      expect(
        out.samples.length,
        inInclusiveRange(2 * second, 2 * second + 4096),
      );
      expect(out.peak, closeTo(_peak, 200));
    });

    test('desligado, a saída fecha e reabre entre elas', () async {
      final out = await _play(dir, pair, gapless: false);
      // A saída em arquivo recomeça ao reabrir: só sobra a última faixa
      expect(out.samples.length, lessThan(2 * second));
    });
  });

  group('abrir', () {
    test('a mesma fila de novo continua mostrando a faixa', () async {
      final path = '${dir.path}/a.wav';
      _writeWav(File(path), second * 4);
      final out = File('${dir.path}/out.wav');
      final engine = MediaKitEngine(
        options: {'ao': 'pcm', 'ao-pcm-file': out.path},
      );
      addTearDown(engine.dispose);
      await engine.open([path]);
      await engine.state.firstLoaded();
      await engine.open([path]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(engine.state.value.queue, [path]);
      expect(engine.state.value.index, 0);
    });
  });

  group('parar depois desta faixa', () {
    test('toca só a faixa atual e fica na seguinte, parado', () async {
      final pair = [
        for (final n in ['a', 'b']) '${dir.path}/$n.wav',
      ];
      for (final path in pair) {
        _writeWav(File(path), second);
      }
      final out = File('${dir.path}/out.wav');
      final engine = MediaKitEngine(
        options: {
          'ao': 'pcm',
          'ao-pcm-file': out.path,
          'audio-format': 's16',
          'audio-samplerate': '$_rate',
          'audio-channels': 'mono',
        },
      );
      await engine.open(pair);
      await engine.setStopAfter(true);
      expect(engine.state.value.stopAfter, isTrue);
      var waited = 0;
      while (engine.state.value.stopAfter && waited++ < 100) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final state = engine.state.value;
      expect(state.stopAfter, isFalse);
      expect(state.playing, isFalse);
      expect(state.index, 1);
      await engine.dispose();
      final samples = _read(out).samples.length;
      expect(samples, inInclusiveRange(second, second + 4096));
    });

    test('com repetir a faixa, para do mesmo jeito', () async {
      final path = '${dir.path}/a.wav';
      _writeWav(File(path), second);
      final engine = MediaKitEngine(
        options: {'ao': 'pcm', 'ao-pcm-file': '${dir.path}/out.wav'},
      );
      await engine.setRepeat(PlayerRepeat.one);
      await engine.open([path]);
      await engine.setStopAfter(true);
      var waited = 0;
      while (engine.state.value.stopAfter && waited++ < 100) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(engine.state.value.stopAfter, isFalse);
      expect(engine.state.value.playing, isFalse);
      expect(engine.state.value.repeat, PlayerRepeat.one);
      await engine.dispose();
    });
  });

  group('equalizador', () {
    late String tone;

    /// 500 Hz é a banda mais perto do seno, e 16 kHz, a mais longe.
    List<double> only(int hz, double gain) => [
      for (final band in equalizerBands) band == hz ? gain : 0,
    ];

    setUp(() {
      tone = '${dir.path}/tone.wav';
      _writeWav(File(tone), second);
    });

    test('tudo em zero não muda nada', () async {
      final out = await _play(dir, [tone], equalizer: flatEqualizer);
      expect(out.peak, closeTo(_peak, 200));
    });

    test('baixar a banda do som baixa o som', () async {
      final out = await _play(dir, [tone], equalizer: only(500, -12));
      expect(out.settledPeak, lessThan(_peak * 0.45));
    });

    test('subir outra banda abre espaço, e o som baixa junto', () async {
      final out = await _play(dir, [tone], equalizer: only(16000, 12));
      expect(out.peak, closeTo(_peak / 4, 300));
    });

    test('tudo no máximo não passa do volume original', () async {
      // A folga vem depois dos filtros, no volume: numa saída de inteiros, o
      // sinal já teria sido cortado
      final out = await _play(
        dir,
        [tone],
        equalizer: List.filled(equalizerBands.length, equalizerMaxGain),
        format: 'float',
      );
      expect(out.peak, lessThanOrEqualTo(_peak * 1.02));
      expect(out.peak, greaterThan(_peak / 2));
    });

    test('vale para o arquivo já aberto', () async {
      final long = '${dir.path}/long.wav';
      _writeWav(File(long), 6 * second);
      final out = await _play(
        dir,
        [long],
        equalizer: only(500, -12),
        equalizerAfterOpen: true,
      );
      expect(out.settledPeak, lessThan(_peak * 0.45));
    });

    test(
      'toca arquivo com taxa menor que o dobro da banda mais alta',
      () async {
        final low = '${dir.path}/low.wav';
        _writeWav(File(low), 22050, rate: 22050);
        final out = await _play(dir, [low], equalizer: only(16000, 6));
        expect(out.samples.length, greaterThan(second ~/ 2));
        expect(out.settledPeak, closeTo(_peak / 2, 300));
      },
    );

    test('não atrapalha o tocar sem pausa', () async {
      final pair = ['${dir.path}/tone.wav', '${dir.path}/tone.wav'];
      final out = await _play(
        dir,
        pair,
        gapless: true,
        equalizer: only(500, 3),
      );
      // O filtro pode reter um resto no fim do último arquivo: no CI, já faltaram
      // 170 amostras (4 ms). Uma pausa entre as faixas somaria, em vez de faltar.
      expect(
        out.samples.length,
        inInclusiveRange(2 * second - 512, 2 * second + 4096),
      );
    });
  });

  group('ReplayGain', () {
    late String tagged;

    setUp(() {
      tagged = '${dir.path}/rg.wav';
      _writeWav(
        File(tagged),
        second,
        tags: const {
          'REPLAYGAIN_TRACK_GAIN': '-6.02 dB',
          'REPLAYGAIN_TRACK_PEAK': '0.5',
          'REPLAYGAIN_ALBUM_GAIN': '-12.04 dB',
          'REPLAYGAIN_ALBUM_PEAK': '0.5',
        },
      );
    });

    test('desligado, não muda o volume', () async {
      final out = await _play(dir, [tagged], replayGain: PlayerReplayGain.off);
      expect(out.peak, closeTo(_peak, 200));
    });

    test('na faixa, usa o valor da faixa', () async {
      final out = await _play(dir, [
        tagged,
      ], replayGain: PlayerReplayGain.track);
      expect(out.peak, closeTo(_peak / 2, 200));
    });

    test('no álbum, usa o valor do álbum', () async {
      final out = await _play(dir, [
        tagged,
      ], replayGain: PlayerReplayGain.album);
      expect(out.peak, closeTo(_peak / 4, 200));
    });

    test('um arquivo sem os valores toca como está', () async {
      final plain = '${dir.path}/plain.wav';
      _writeWav(File(plain), second);
      final out = await _play(dir, [plain], replayGain: PlayerReplayGain.track);
      expect(out.peak, closeTo(_peak, 200));
    });
  });
}

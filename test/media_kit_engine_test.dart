// O motor de verdade: a libmpv grava num arquivo o que iria para a saída de som,
// sem barulho e mais rápido que o tempo real. Sem a libmpv, os testes não rodam.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/player/engine.dart';
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
void _writeWav(File file, int frames, {Map<String, String> tags = const {}}) {
  final pcm = ByteData(frames * 2);
  for (var i = 0; i < frames; i++) {
    final v = sin(2 * pi * 440 * i / _rate) * _peak;
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
  head.setUint32(24, _rate, Endian.little);
  head.setUint32(28, _rate * 2, Endian.little);
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
}

_Output _read(File file) {
  final bytes = file.readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  var at = 12;
  var channels = 1;
  while (at + 8 <= bytes.length) {
    final id = ascii.decode(bytes.sublist(at, at + 4));
    final size = data.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') channels = data.getUint16(at + 10, Endian.little);
    if (id == 'data') {
      at += 8;
      break;
    }
    at += 8 + size;
  }
  return _Output([
    for (var i = at; i + 2 <= bytes.length; i += 2 * channels)
      data.getInt16(i, Endian.little),
  ]);
}

Future<_Output> _play(
  Directory dir,
  List<String> paths, {
  bool? gapless,
  PlayerReplayGain? replayGain,
}) async {
  final out = File('${dir.path}/out.wav');
  if (out.existsSync()) out.deleteSync();
  final engine = MediaKitEngine(
    options: {
      'ao': 'pcm',
      'ao-pcm-file': out.path,
      'audio-format': 's16',
      'audio-samplerate': '$_rate',
      'audio-channels': 'mono',
    },
  );
  if (gapless != null) await engine.setGapless(gapless);
  if (replayGain != null) await engine.setReplayGain(replayGain);
  await engine.open(paths);
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

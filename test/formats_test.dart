// Os formatos que o leitor de tags não cobre sozinho, com arquivos de verdade em
// test/fixtures, gravados por encoders de verdade. O APE não tem encoder livre à
// mão: o teste monta o cabeçalho, e tocar fica de fora.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/format_probes.dart';
import 'package:psito_player/src/library/scanner.dart';
import 'package:psito_player/src/library/tags.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';

/// Os arquivos têm 44 blocos de 1024 amostras, a 44100 Hz.
const _lengthMs = 44 * 1024 * 1000 ~/ 44100;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('psito-formats'));
  tearDown(() => dir.deleteSync(recursive: true));

  File fixture(String name) => File('test/fixtures/$name');

  void expectLength(FileTags tags) {
    expect(tags.durationMs, closeTo(_lengthMs, 60));
    expect(tags.sampleRate, 44100);
  }

  test('a biblioteca aceita os formatos novos', () {
    expect(
      audioExtensions,
      containsAll(['.aac', '.wma', '.ape', '.wv', '.aiff', '.aif']),
    );
  });

  test('WMA: tags e duração do cabeçalho ASF', () {
    final tags = readFileTags(fixture('tone.wma'));
    expect(tags.title, 'Tom');
    expect(tags.artist, 'Artista');
    expect(tags.album, 'Disco');
    expect(tags.genre, 'Teste');
    expect(tags.trackNumber, 3);
    expectLength(tags);
  });

  test('um .wma que não é ASF lança, e o scanner fica com o nome', () {
    final fake = File('${dir.path}/x.wma')..writeAsStringSync('nada aqui');
    expect(() => readFileTags(fake), throwsFormatException);
  });

  test('WavPack: tags APE no fim e duração no primeiro bloco', () {
    final tags = readFileTags(fixture('tone.wv'));
    expect(tags.title, 'Tom');
    expect(tags.album, 'Disco');
    expect(tags.trackNumber, 3);
    expect(tags.year, 2019);
    expectLength(tags);
  });

  test('WavPack sem total de amostras fica sem duração', () {
    final bytes = fixture('tone.wv').readAsBytesSync();
    ByteData.sublistView(bytes).setUint32(12, 0xFFFFFFFF, Endian.little);
    final file = File('${dir.path}/x.wv')..writeAsBytesSync(bytes);
    expect(readWavPackInfo(file), isNull);
  });

  test('AAC cru: sem tags, a duração vem de contar os quadros', () {
    final tags = readFileTags(fixture('tone.aac'));
    expect(tags.title, isNull);
    expect(tags.sampleRate, 44100);
    // O encoder soma quadros de atraso
    expect(tags.durationMs, inInclusiveRange(_lengthMs, _lengthMs + 100));
  });

  test('AAC com ID3v2 no começo e lixo no fim', () {
    final frame = utf8.encode('TIT2');
    final title = [...frame, 0, 0, 0, 4, 0, 0, 3, ...ascii.encode('Tom')];
    final id3 = [
      ...ascii.encode('ID3'),
      3,
      0,
      0,
      0,
      0,
      0,
      title.length,
      ...title,
    ];
    final audio = fixture('tone.aac').readAsBytesSync();
    final file = File('${dir.path}/x.aac')
      ..writeAsBytesSync([...id3, ...audio, ...ascii.encode('TAG nada')]);
    final info = readAdtsInfo(file)!;
    expect(info.durationMs, readAdtsInfo(fixture('tone.aac'))!.durationMs);
    expect(readFileTags(file).durationMs, info.durationMs);
  });

  test('AIFF: tags no ID3 e duração do leitor', () {
    final tags = readFileTags(fixture('tone.aiff'));
    expect(tags.title, 'Tom');
    expect(tags.artist, 'Artista');
    expect(tags.album, 'Disco');
    expectLength(tags);
  });

  group('Monkey\'s Audio', () {
    test('o cabeçalho de 3.98 em diante', () {
      final head = ByteData(52 + 24);
      head.buffer.asUint8List().setRange(0, 4, ascii.encode('MAC '));
      head.setUint16(4, 3990, Endian.little);
      head.setUint32(8, 52, Endian.little);
      head.setUint32(52 + 4, 73728, Endian.little);
      head.setUint32(52 + 8, 44100, Endian.little);
      head.setUint32(52 + 12, 3, Endian.little);
      head.setUint32(52 + 20, 44100, Endian.little);
      final file = File('${dir.path}/x.ape')
        ..writeAsBytesSync(head.buffer.asUint8List());
      // Sem tags no arquivo, vale o nome: a duração ainda vem
      final tags = readFileTags(file);
      expect(tags.title, isNull);
      expect(tags.durationMs, (2 * 73728 + 44100) * 1000 ~/ 44100);
      expect(tags.sampleRate, 44100);
    });

    test('o cabeçalho antigo', () {
      final head = ByteData(32);
      head.buffer.asUint8List().setRange(0, 4, ascii.encode('MAC '));
      head.setUint16(4, 3970, Endian.little);
      head.setUint16(6, 2000, Endian.little);
      head.setUint32(12, 44100, Endian.little);
      head.setUint32(24, 2, Endian.little);
      head.setUint32(28, 44100, Endian.little);
      final file = File('${dir.path}/y.ape')
        ..writeAsBytesSync(head.buffer.asUint8List());
      expect(
        readMonkeysInfo(file)!.durationMs,
        (73728 * 4 + 44100) * 1000 ~/ 44100,
      );
    });

    test('outro arquivo com a extensão fica sem duração', () {
      final file = File('${dir.path}/z.ape')
        ..writeAsBytesSync(List.filled(64, 0));
      expect(readMonkeysInfo(file), isNull);
    });
  });

  // A libmpv de verdade toca cada um, até o fim, numa saída para arquivo
  group('tocam', () {
    for (final name in ['tone.aac', 'tone.wma', 'tone.wv', 'tone.aiff']) {
      test(name, () async {
        final out = File('${dir.path}/out.wav');
        final engine = MediaKitEngine(
          options: {
            'ao': 'pcm',
            'ao-pcm-file': out.path,
            'audio-format': 's16',
            'audio-samplerate': '44100',
            'audio-channels': 'mono',
          },
        );
        await engine.open([fixture(name).absolute.path]);
        var last = -1;
        var still = 0;
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (still < 5 && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final size = out.existsSync() ? out.lengthSync() : 0;
          still = size == last && size > 44 ? still + 1 : 0;
          last = size;
        }
        await engine.dispose();
        final samples = (out.lengthSync() - 44) ~/ 2;
        final bytes = ByteData.sublistView(out.readAsBytesSync());
        var peak = 0;
        for (var i = 44; i + 1 < bytes.lengthInBytes; i += 2) {
          final v = bytes.getInt16(i, Endian.little).abs();
          if (v > peak) peak = v;
        }
        expect(samples, closeTo(44 * 1024, 44100 * 0.2));
        expect(peak, greaterThan(1000), reason: 'saiu silêncio');
      });
    }
  });
}

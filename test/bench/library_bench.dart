// Quanto custa uma biblioteca grande, com o banco num arquivo, no isolate de
// verdade e a libmpv de verdade. Não entra no `flutter test`, por não ser um
// *_test.dart: rode com
//
//   flutter test test/bench/library_bench.dart
//
// PSITO_BENCH_TRACKS muda o tamanho (50 mil), e PSITO_BENCH_DB deixa o banco
// nesse caminho, para abrir o app com ele.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/library_search.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';

import '../helpers.dart';

const _tracksPerAlbum = 10;
const _albumsPerArtist = 10;

final _words = [
  'maré',
  'vento',
  'coral',
  'sol',
  'noite',
  'rio',
  'pedra',
  'luz',
  'mar',
  'céu',
  'tempo',
  'fogo',
  'chuva',
  'lua',
  'areia',
  'serra',
  'ilha',
  'folha',
  'nuvem',
  'onda',
];

String _name(int n) {
  final a = _words[n % _words.length];
  final b = _words[(n ~/ _words.length) % _words.length];
  return '$a $b $n';
}

/// O tempo total e a maior parada da thread da tela enquanto isso rodava.
Future<T> _time<T>(String label, Future<T> Function() run) async {
  final clock = Stopwatch()..start();
  final gap = Stopwatch()..start();
  var worst = 0;
  final ticker = Timer.periodic(const Duration(milliseconds: 1), (_) {
    if (gap.elapsedMilliseconds > worst) worst = gap.elapsedMilliseconds;
    gap.reset();
  });
  final value = await run();
  // O que travou até agora só aparece no próximo tique
  await Future<void>.delayed(const Duration(milliseconds: 2));
  ticker.cancel();
  final total = clock.elapsedMilliseconds.toString().padLeft(7);
  // ignore: avoid_print
  print(
    '${label.padRight(40)} $total ms   tela parada ${worst.toString().padLeft(5)} ms',
  );
  return value;
}

/// Um segundo de silêncio, para o mpv ter o que abrir.
void _writeSilence(File file) {
  const frames = 44100;
  final head = ByteData(44);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      head.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  head.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  head.setUint32(16, 16, Endian.little);
  head.setUint16(20, 1, Endian.little);
  head.setUint16(22, 1, Endian.little);
  head.setUint32(24, frames, Endian.little);
  head.setUint32(28, frames * 2, Endian.little);
  head.setUint16(32, 2, Endian.little);
  head.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  head.setUint32(40, frames * 2, Endian.little);
  file.writeAsBytesSync([
    ...head.buffer.asUint8List(),
    ...List.filled(frames * 2, 0),
  ]);
}

void main() {
  test('biblioteca grande', () async {
    final total =
        int.tryParse(Platform.environment['PSITO_BENCH_TRACKS'] ?? '') ?? 50000;
    final dir = Directory.systemTemp.createTempSync('psito-bench');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = Platform.environment['PSITO_BENCH_DB'] ?? '${dir.path}/l.db';
    final musicDir = Directory('${dir.path}/m')..createSync();

    await _time('gravar $total faixas', () async {
      final db = LibraryDb.open(path);
      final folder = db.addFolder(musicDir.path);
      db.begin();
      for (var i = 0; i < total; i++) {
        final albumN = i ~/ _tracksPerAlbum;
        final artist = _name(albumN ~/ _albumsPerArtist);
        final album = _name(albumN);
        db.upsertTrack(
          ScannedTrack(
            path: '${musicDir.path}/$artist/$album/$i.flac',
            title: _name(i),
            artist: artist,
            albumArtist: artist,
            album: album,
            trackNumber: i % _tracksPerAlbum + 1,
            year: 1970 + albumN % 55,
            genre: _words[albumN % _words.length],
            durationMs: 180000 + i % 120000,
            size: 30000000,
            mtime: 1,
          ),
          folder,
          i,
        );
      }
      db.commit();
      db.markScanned(folder, 1);
      db.close();
    });

    final store = await _time('abrir o banco', () => IsolateStore.open(path));
    final library = LibraryController(store: store, scanner: FakeScanner());
    await _time('reload (abrir o app)', library.reload);
    await _time('segundo reload', library.reload);
    await _time('reload na lista de músicas', () async {
      library.setSection(LibrarySection.tracks);
      await library.reload();
    });
    final tracks = await _time(
      'todas as faixas',
      () => store.tracks(const TrackQuery()),
    );

    final search = LibrarySearch(store);
    for (final query in ['m', 'ma', 'mar', 'maré vento', 'chuva 4']) {
      await _time('buscar "$query"', () => store.search(query));
    }
    search.dispose();

    final engine = MediaKitEngine(options: const {'ao': 'null'});
    final real = [for (var i = 0; i < 4; i++) File('${dir.path}/real$i.wav')];
    real.forEach(_writeSilence);
    final paths = [
      for (final f in real) f.path,
      for (final t in tracks) t.path,
    ];
    await _time('abrir a fila inteira no motor', () async {
      await engine.open(paths, play: false);
      while (engine.state.value.queue.length < paths.length) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await _time('avançar uma faixa', () async {
      final before = engine.state.value.index;
      await engine.next();
      while (engine.state.value.index == before) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await _time('voltar uma faixa', () async {
      final before = engine.state.value.index;
      await engine.previous();
      while (engine.state.value.index == before) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await _time('tracksAt da fila inteira', () => store.tracksAt(paths));
    await engine.dispose();

    library.dispose();
    await store.close();
    // ignore: avoid_print
    print('banco: ${File(path).lengthSync() ~/ 1024 ~/ 1024} MB');
    // ignore: avoid_print
    print('memória: ${ProcessInfo.currentRss ~/ 1024 ~/ 1024} MB');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

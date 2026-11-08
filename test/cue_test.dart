// As cue sheets: o texto, a biblioteca, tocar pela libmpv de verdade, e o
// organizador levando o par junto. O `tone.ape` tem 5 s de um tom.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psito_player/src/library/cue.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/organize/file_organizer.dart';
import 'package:psito_player/src/library/scanner.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';
import 'package:psito_player/src/player/playback_controller.dart';

import 'helpers.dart';

const _sheet = '''
﻿REM GENRE "Rock"
REM DATE 1997
PERFORMER "Banda"
TITLE "Ao Vivo"
FILE "tone.ape" WAVE
  TRACK 01 AUDIO
    TITLE "Primeira"
    INDEX 00 00:00:00
    INDEX 01 00:00:00
  TRACK 02 AUDIO
    TITLE "Segunda"
    PERFORMER "Convidada"
    INDEX 00 00:02:00
    INDEX 01 00:02:37
''';

void main() {
  group('o texto', () {
    final sheet = parseCueSheet(_sheet);

    test('lê o álbum e as faixas', () {
      expect(sheet.title, 'Ao Vivo');
      expect(sheet.performer, 'Banda');
      expect(sheet.genre, 'Rock');
      expect(sheet.year, 1997);
      expect(sheet.tracks.map((t) => t.title), ['Primeira', 'Segunda']);
      expect(sheet.tracks[1].performer, 'Convidada');
    });

    test('o INDEX 01 conta, em quadros de 1/75 s', () {
      expect(sheet.tracks[0].startMs, 0);
      expect(sheet.tracks[1].startMs, 2493);
    });

    test('precisa de um arquivo, mais de uma faixa e ordem', () {
      expect(sheet.usable, isTrue);
      expect(parseCueSheet('FILE "a" WAVE\nFILE "b" WAVE').usable, isFalse);
      expect(
        parseCueSheet('''
FILE "a" WAVE
TRACK 01 AUDIO
INDEX 01 00:05:00
TRACK 02 AUDIO
INDEX 01 00:01:00
''').usable,
        isFalse,
      );
    });

    test('acha pelos dois nomes, sem diferenciar maiúsculas', () {
      final cues = {'/m/disco.cue': '/m/Disco.CUE'};
      expect(findCueFile('/m/disco.flac', cues), '/m/Disco.CUE');
      expect(findCueFile('/m/outro.flac', cues), isNull);
      expect(
        findCueFile('/m/a.flac', {'/m/a.flac.cue': '/m/a.flac.cue'}),
        '/m/a.flac.cue',
      );
    });
  });

  group('o caminho', () {
    test('vai e volta', () {
      const ref = CueRef('/m/a#b.flac', 2, 1000, 500);
      final back = CueRef.parse(ref.path)!;
      expect(back.file, '/m/a#b.flac');
      expect((back.number, back.startMs, back.lengthMs), (2, 1000, 500));
      expect(filePathOf(ref.path), '/m/a#b.flac');
      expect(filePathOf('/m/a.flac'), '/m/a.flac');
      expect(Track.formatOf(ref.path), 'FLAC');
    });

    test('o endereço conta os bytes do caminho', () {
      expect(
        cueEdlAddress(const CueRef('/m/ç,a.flac', 1, 1500, 2000)),
        'edl://%12%/m/ç,a.flac,1.500,2.000',
      );
    });
  });

  group('com arquivos', () {
    late Directory dir;
    late String root;
    late String audio;
    late String cue;
    late LibraryDb db;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('psito-cue');
      root = p.join(dir.path, 'Musica');
      Directory(p.join(root, 'show')).createSync(recursive: true);
      Directory(p.join(dir.path, 'covers')).createSync();
      audio = p.join(root, 'show', 'tone.ape');
      cue = p.join(root, 'show', 'tone.cue');
      File('test/fixtures/tone.ape').copySync(audio);
      File(cue).writeAsStringSync(_sheet);
      db = LibraryDb.memory();
      db.addFolder(root);
    });

    tearDown(() {
      db.close();
      dir.deleteSync(recursive: true);
    });

    Future<void> scan() => scanFolders(
      db: db,
      folders: db.folders(),
      coverDir: p.join(dir.path, 'covers'),
      control: ScanControl(),
      onProgress: (_) {},
    );

    test('um arquivo vira as faixas, e ele mesmo não aparece', () async {
      await scan();
      final tracks = db.tracks()..sort((a, b) => a.path.compareTo(b.path));
      expect(tracks.map((t) => t.title), ['Primeira', 'Segunda']);
      expect(tracks.map((t) => t.artist), ['Banda', 'Convidada']);
      expect(tracks.every((t) => t.album == 'Ao Vivo'), isTrue);
      expect(tracks.every((t) => t.format == 'APE'), isTrue);
      expect(tracks.every((t) => t.year == 1997), isTrue);
      expect(tracks.first.duration.inMilliseconds, 2493);
      expect(tracks.last.duration.inMilliseconds, closeTo(5000 - 2493, 60));
      // O arquivo conta uma vez
      expect(db.totals().size, File(audio).lengthSync());
    });

    test('nada mudou, nada a ler', () async {
      await scan();
      final check = await checkFolder(db, db.folders().single);
      expect(check.changes, 0);
      final ids = db.tracks().map((t) => t.id).toSet();
      await scan();
      expect(db.tracks().map((t) => t.id).toSet(), ids);
    });

    test('mudar o texto relê, sem perder as faixas iguais', () async {
      await scan();
      final first = db.tracks().firstWhere((t) => t.title == 'Primeira');
      db.setRating(first.id, 5);
      File(cue).writeAsStringSync(_sheet.replaceAll('Segunda', 'Outra'));
      File(cue)
          .setLastModifiedSync(DateTime.now().add(const Duration(hours: 1)));
      expect((await checkFolder(db, db.folders().single)).changes, 1);
      await scan();
      expect(db.tracks().map((t) => t.title).toSet(), {'Primeira', 'Outra'});
      expect(db.tracks().firstWhere((t) => t.title == 'Primeira').rating, 5);
    });

    test('tirar o texto volta o arquivo inteiro', () async {
      await scan();
      File(cue).deleteSync();
      File(audio)
          .setLastModifiedSync(DateTime.now().add(const Duration(hours: 1)));
      await scan();
      expect(db.tracks().single.path, audio);
    });

    test(
      'um arquivo já na biblioteca vira as faixas quando o texto chega',
      () async {
        File(cue).deleteSync();
        await scan();
        expect(db.tracks().single.path, audio);
        File(cue).writeAsStringSync(_sheet);
        await scan();
        expect(db.tracks(), hasLength(2));
      },
    );

    test('a cue sheet dentro do FLAC também vale', () async {
      final python = Process.runSync('python3', ['-c', 'import mutagen']);
      if (python.exitCode != 0) return;
      File(cue).deleteSync();
      File(audio).deleteSync();
      final flac = p.join(root, 'show', 'tone.flac');
      File('test/fixtures/tone.flac').copySync(flac);
      const text = '''
FILE "tone.flac" WAVE
TRACK 01 AUDIO
TITLE "Um"
INDEX 01 00:00:00
TRACK 02 AUDIO
TITLE "Dois"
INDEX 01 00:00:08
''';
      final result = Process.runSync('python3', [
        '-c',
        'import sys, mutagen\nf = mutagen.File(sys.argv[1])\n'
            'f["CUESHEET"] = sys.argv[2]\nf.save()',
        flac,
        text,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      await scan();
      expect(db.tracks().map((t) => t.title).toSet(), {'Um', 'Dois'});
    });

    test('o organizador leva o par, e todas as faixas andam', () async {
      await scan();
      final library = LibraryController(
        store: DirectStore(db),
        scanner: FakeScanner(),
        tagUndoDir: p.join(dir.path, 'tag-undo'),
      );
      addTearDown(library.dispose);
      await library.reload();
      final first = db.tracks().firstWhere((t) => t.title == 'Primeira');
      db.setRating(first.id, 4);
      db.createPlaylist('P', 1, [first.path]);
      final plan = planOrganize(
        OrganizeRequest(
          items: db.organizeItems(folderId: db.folders().single.id),
          pattern: '{albumArtist}/{album}/{track} {title}',
          unknown: 'X',
        ),
      );
      expect(plan.moves.map((m) => p.basename(m.to)).toSet(), {
        'tone.ape',
        'tone.cue',
      });
      final report = await library.runOrganize(plan);
      expect(report.failed, isEmpty);
      final moved = p.join(root, 'Banda', 'Ao Vivo', 'tone.ape');
      expect(File(moved).existsSync(), isTrue);
      expect(File(p.setExtension(moved, '.cue')).existsSync(), isTrue);
      final tracks = db.tracks();
      expect(tracks.every((t) => t.filePath == moved), isTrue);
      final again = tracks.firstWhere((t) => t.title == 'Primeira');
      expect(again.id, first.id);
      expect(again.rating, 4);
      expect(
        db.playlistTracks(db.playlists().single.id).single.path,
        again.path,
      );
      await scan();
      expect(db.tracks().map((t) => t.id).toSet(), contains(first.id));

      await library.undoOrganize(report.undoId!);
      expect(File(audio).existsSync(), isTrue);
      expect(db.tracks().every((t) => t.filePath == audio), isTrue);
    });

    test('a fila vai junto', () async {
      await scan();
      final engine = FakeEngine();
      final playback = PlaybackController(
        engine: engine,
        store: DirectStore(db),
      );
      final paths = db.tracks().map((t) => t.path).toList()..sort();
      await engine.open(['/outra.flac', ...paths]);
      await playback.relocate({audio: '/novo/tone.ape'});
      final queue = engine.state.value.queue;
      expect(queue[1], startsWith('/novo/tone.ape#cue:'));
      expect(queue[2], startsWith('/novo/tone.ape#cue:'));
    });

    test('a playlist exportada leva o arquivo, uma vez', () async {
      await scan();
      final library = LibraryController(
        store: DirectStore(db),
        scanner: FakeScanner(),
      );
      addTearDown(library.dispose);
      final out = p.join(dir.path, 'lista.m3u');
      await library.exportPlaylistFile(db.tracks(), out);
      final text = File(out).readAsStringSync();
      expect(audio.allMatches(text).length, 1);
      expect(text.contains('#cue:'), isFalse);
    });

    test('toca cada pedaço, um emendado no outro', () async {
      await scan();
      final paths = db.tracks().map((t) => t.path).toList()..sort();
      final out = File(p.join(dir.path, 'out.wav'));
      final engine = MediaKitEngine(
        options: {
          'ao': 'pcm',
          'ao-pcm-file': out.path,
          'audio-format': 's16',
          'audio-samplerate': '44100',
          'audio-channels': 'mono',
        },
      );
      await engine.open(paths);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(engine.state.value.queue, paths);
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
      final bytes = ByteData.sublistView(out.readAsBytesSync());
      final samples = (bytes.lengthInBytes - 44) ~/ 2;
      expect(samples, closeTo(5 * 44100, 44100 * 0.1));
      // Sem buraco de silêncio na emenda, em 2,493 s
      final seam = (2.493 * 44100).round();
      var peak = 0;
      for (var i = seam - 2205; i < seam + 2205; i++) {
        final v = bytes.getInt16(44 + i * 2, Endian.little).abs();
        if (v > peak) peak = v;
      }
      expect(peak, greaterThan(1000), reason: 'silêncio na emenda');
    });
  });
}

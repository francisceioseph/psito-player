// test/skip_duplicates_test.dart
//
// Pular faixas e mostrar as duplicadas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/player/playback_controller.dart';

import 'helpers.dart';

Track _track(String title, int seconds, {String artist = 'Ana', int id = 1}) =>
    Track(
      id: id,
      path: '/m/$title-$seconds-$artist.flac',
      title: title,
      artist: artist,
      format: 'FLAC',
      duration: Duration(seconds: seconds),
    );

void main() {
  group('as duplicadas', () {
    test('o mesmo título e artista, sem ligar para caixa e acento', () {
      final found = duplicateTracks([
        _track('Canção', 200),
        _track('Outra', 100),
        _track('CANCAO', 201),
      ]);
      expect(found.map((t) => t.title), ['Canção', 'CANCAO']);
    });

    test('a versão ao vivo, com outra duração, não é duplicada', () {
      expect(
        duplicateTracks([_track('Canção', 200), _track('Canção', 260)]),
        isEmpty,
      );
    });

    test('outro artista não é duplicada', () {
      expect(
        duplicateTracks([
          _track('Canção', 200),
          _track('Canção', 200, artist: 'Bia'),
        ]),
        isEmpty,
      );
    });

    test('cada grupo fica junto, na ordem de quem veio primeiro', () {
      final found = duplicateTracks([
        _track('A', 100),
        _track('B', 100),
        _track('A', 101),
        _track('B', 102),
      ]);
      expect(found.map((t) => t.title), ['A', 'A', 'B', 'B']);
    });

    test('duas versões, cada uma com a cópia dela, são dois grupos', () {
      final found = duplicateTracks([
        _track('A', 100),
        _track('A', 101),
        _track('A', 300),
        _track('A', 301),
        _track('A', 500),
      ]);
      expect(found.map((t) => t.duration.inSeconds), [100, 101, 300, 301]);
    });
  });

  group('o banco', () {
    late LibraryDb db;

    setUp(() {
      db = LibraryDb.memory();
      final folder = db.addFolder('/m');
      for (final (i, title) in ['Um', 'Dois', 'Dois'].indexed) {
        db.upsertTrack(
          ScannedTrack(
            path: '/m/$i.flac',
            title: title,
            artist: 'Ana',
            album: 'Disco',
            genre: 'Rock',
            durationMs: 60000,
            size: 1,
            mtime: 1,
          ),
          folder,
          i + 1,
        );
      }
    });
    tearDown(() => db.close());

    test('a marca sobrevive a reler o arquivo', () {
      final track = db.tracks().first;
      db.setSkip(track.id, true);
      db.upsertTrack(
        ScannedTrack(
          path: track.path,
          title: 'Novo nome',
          album: 'Disco',
          size: 2,
          mtime: 2,
        ),
        db.folders().single.id,
        9,
      );
      expect(db.tracks().firstWhere((t) => t.id == track.id).skip, isTrue);
    });

    test('os filtros acham as puladas e as duplicadas', () {
      final track = db.tracks().firstWhere((t) => t.title == 'Um');
      db.setSkip(track.id, true);
      expect(db.tracks(const TrackQuery(skipped: true)).map((t) => t.title), [
        'Um',
      ]);
      expect(
        db.tracks(const TrackQuery(duplicates: true)).map((t) => t.title),
        ['Dois', 'Dois'],
      );
    });

    test('o aleatório e os mixes deixam as puladas de fora', () {
      for (final track in db.tracks()) {
        db.setSkip(track.id, true);
      }
      expect(db.randomTracks(10), isEmpty);
      expect(db.dailyMix(1), isEmpty);
      expect(db.genreMix('Rock', 1), isEmpty);
      expect(db.dynamicMixBatch(10), isEmpty);
    });
  });

  group('tocando', () {
    late LibraryDb db;
    late FakeEngine engine;
    late PlaybackController playback;
    final a = _track('A', 100);
    final b = _track('B', 100).withMarks(skip: true);
    final c = _track('C', 100, id: 3);

    setUp(() {
      db = LibraryDb.memory();
      engine = FakeEngine();
      playback = PlaybackController(engine: engine, store: DirectStore(db));
    });
    tearDown(() {
      playback.dispose();
      db.close();
    });

    test('a lista pula a marcada', () async {
      await playback.playTracks([a, b, c]);
      expect(engine.state.value.queue, [a.path, c.path]);
    });

    test('escolhida, ela toca, e as outras marcadas continuam fora', () async {
      final d = _track('D', 100).withMarks(skip: true);
      await playback.playChosen([a, b, c, d], 1);
      expect(engine.state.value.queue, [a.path, b.path, c.path]);
      expect(engine.state.value.index, 1);
    });

    test('tudo marcado avisa que não há o que tocar', () async {
      var warned = false;
      final warning = PlaybackController(
        engine: FakeEngine(),
        store: DirectStore(db),
        onNothingAvailable: () => warned = true,
      );
      await warning.playTracks([b]);
      expect(warned, isTrue);
      warning.dispose();
    });

    test('marcar tira da fila o que ainda não tocou, e a atual fica', () async {
      final plain = _track('B', 100);
      await playback.playTracks([a, plain, c, plain], index: 0);
      await playback.setSkip(plain, true);
      expect(engine.state.value.queue, [a.path, c.path]);
      await playback.setSkip(a, true);
      expect(engine.state.value.queue, [a.path, c.path]);
      expect(engine.state.value.index, 0);
    });

    test('quem está fora da biblioteca não tem a marca', () async {
      await playback.setSkip(Track.fromPath('/fora.mp3'), true);
      expect(playback.state.queue, isEmpty);
    });
  });

  group('a tela', () {
    late LibraryDb db;

    setUp(() {
      db = LibraryDb.memory();
      seedAlbum(db, tracks: 2);
    });
    tearDown(() => db.close());

    testWidgets('marca pelo menu, e o filtro mostra', (tester) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester, db: db);
      await tester.tap(find.byIcon(Icons.library_music_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Músicas').first);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.not_interested_rounded), findsNothing);
      await tester.tap(find.byTooltip('Mais opções').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pular nas listas'));
      await tester.pumpAndSettle();
      expect(db.tracks().where((t) => t.skip), hasLength(1));
      expect(find.byIcon(Icons.not_interested_rounded), findsOneWidget);

      await tester.tap(find.text('Puladas'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Mais opções'), findsWidgets);
      expect(find.byIcon(Icons.not_interested_rounded), findsOneWidget);
    });
  });
}

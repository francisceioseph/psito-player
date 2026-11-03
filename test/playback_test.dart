import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/player/engine.dart';
import 'package:psito_player/src/player/playback_controller.dart';

import 'helpers.dart';

void main() {
  late LibraryDb db;
  late FakeEngine engine;
  late PlaybackController playback;
  late int albumId;

  setUp(() {
    db = LibraryDb.memory();
    albumId = seedAlbum(db);
    engine = FakeEngine();
    playback = PlaybackController(engine: engine, store: DirectStore(db));
    addTearDown(playback.dispose);
    addTearDown(db.close);
  });

  List<String> titles() => playback.queue.map((t) => t.title).toList();

  test('tocar o álbum abre a fila na ordem, a partir da faixa', () async {
    await playback.playAlbum(albumId, index: 1);
    expect(titles(), ['Maré Alta 1', 'Maré Alta 2', 'Maré Alta 3']);
    expect(playback.current!.title, 'Maré Alta 2');
  });

  test('tocar a seguir entra logo depois da atual', () async {
    await playback.playAlbum(albumId);
    await playback.playNext(
      const Track(path: '/x.flac', title: 'X', format: 'FLAC'),
    );
    expect(titles(), ['Maré Alta 1', 'X', 'Maré Alta 2', 'Maré Alta 3']);
  });

  test('adicionar à fila entra no fim, e numa fila vazia já toca', () async {
    await playback.addToQueue(
      const Track(path: '/x.flac', title: 'X', format: 'FLAC'),
    );
    expect(engine.opened, hasLength(1));
    expect(playback.current!.title, 'X');
    await playback.addToQueue(
      const Track(path: '/y.flac', title: 'Y', format: 'FLAC'),
    );
    expect(titles(), ['X', 'Y']);
    expect(engine.opened, hasLength(1));
  });

  test('tirar da fila e pular para uma faixa', () async {
    await playback.playAlbum(albumId);
    await playback.removeAt(1);
    expect(titles(), ['Maré Alta 1', 'Maré Alta 3']);
    await playback.jump(1);
    expect(playback.current!.title, 'Maré Alta 3');
  });

  test('voltar: no começo da faixa vai à anterior, depois reinicia', () async {
    await playback.playAlbum(albumId, index: 1);
    engine.set(
      engine.state.value.copyWith(position: const Duration(seconds: 10)),
    );
    await playback.previous();
    expect(playback.current!.title, 'Maré Alta 2');
    expect(engine.seeks.single, Duration.zero);
    engine.set(
      engine.state.value.copyWith(position: const Duration(seconds: 1)),
    );
    await playback.previous();
    expect(playback.current!.title, 'Maré Alta 1');
  });

  test('as setas andam sem passar do começo nem do fim', () async {
    await playback.playAlbum(albumId);
    await playback.seekBy(-seekStep);
    expect(engine.seeks.last, Duration.zero);
    await playback.seekBy(seekStep);
    expect(engine.seeks.last, seekStep);
    engine.set(
      engine.state.value.copyWith(
        position: const Duration(minutes: 3, seconds: 6),
      ),
    );
    await playback.seekBy(seekStep);
    expect(engine.seeks.last, const Duration(minutes: 3, seconds: 7));
  });

  test('o aleatório mantém a atual e desfaz para a ordem de antes', () async {
    await playback.playAlbum(albumId, index: 1);
    await playback.toggleShuffle();
    expect(playback.current!.title, 'Maré Alta 2');
    expect(titles(), ['Maré Alta 2', 'Maré Alta 3', 'Maré Alta 1']);
    await playback.toggleShuffle();
    expect(titles(), ['Maré Alta 1', 'Maré Alta 2', 'Maré Alta 3']);
    expect(playback.current!.title, 'Maré Alta 2');
  });

  test('repetir passa por desligado, tudo e esta faixa', () async {
    await playback.cycleRepeat();
    expect(playback.state.repeat, PlayerRepeat.all);
    await playback.cycleRepeat();
    expect(playback.state.repeat, PlayerRepeat.one);
    await playback.cycleRepeat();
    expect(playback.state.repeat, PlayerRepeat.off);
  });

  test('tudo em aleatório leva faixas da biblioteca toda', () async {
    seedAlbum(db, album: 'Outro');
    await playback.shuffleAll();
    expect(playback.queue, hasLength(6));
  });

  test('um arquivo de fora toca, e o da biblioteca vem com as tags', () async {
    await playback.playPaths(['/fora/a.mp3', '/m/Maré Alta/1.flac']);
    expect(playback.queue[0].title, 'a');
    expect(playback.queue[0].id, 0);
    expect(playback.queue[1].title, 'Maré Alta 1');
  });

  group('a reprodução conta', () {
    Future<int> count() async => db.albumTracks(albumId).first.playCount;

    test('ao passar da metade, uma vez só', () async {
      await playback.playAlbum(albumId);
      engine.set(
        engine.state.value.copyWith(position: const Duration(seconds: 10)),
      );
      await pumpEventQueue();
      expect(await count(), 0);
      engine.set(
        engine.state.value.copyWith(position: const Duration(minutes: 2)),
      );
      engine.set(
        engine.state.value.copyWith(position: const Duration(minutes: 3)),
      );
      await pumpEventQueue();
      expect(await count(), 1);
    });

    test('e avisa as telas', () async {
      var recorded = 0;
      final other = PlaybackController(
        engine: engine,
        store: DirectStore(db),
        onLibraryChanged: () => recorded++,
      );
      addTearDown(other.dispose);
      await other.playAlbum(albumId);
      engine.set(
        engine.state.value.copyWith(position: const Duration(minutes: 2)),
      );
      await pumpEventQueue();
      expect(recorded, 1);
    });

    test('um arquivo de fora da biblioteca não conta', () async {
      await playback.playPaths(['/fora/a.mp3']);
      engine.set(
        engine.state.value.copyWith(position: const Duration(minutes: 2)),
      );
      await pumpEventQueue();
      expect(db.mostPlayed(5), isEmpty);
    });
  });

  group('a sessão', () {
    Future<PlaybackController> reopen(
      FakeEngine next, {
      List<String> open = const [],
    }) async {
      final again = PlaybackController(engine: next, store: DirectStore(db));
      addTearDown(again.dispose);
      await again.restore(open: open);
      return again;
    }

    test('uma faixa num disco desligado não abre, e a sessão fica', () async {
      await playback.playAlbum(albumId, index: 1);
      await playback.saveSession();
      final saved = db.setting('session');
      final next = FakeEngine();
      final again = PlaybackController(
        engine: next,
        store: DirectStore(db),
        isAvailable: (_) => false,
      );
      addTearDown(again.dispose);
      await again.restore();
      expect(next.opened, isEmpty);
      expect(again.resumable, isFalse);
      await again.saveSession();
      expect(db.setting('session'), saved);
    });

    test('o que falta na fila sai, e a faixa continua sendo a mesma', () async {
      await playback.playAlbum(albumId, index: 2);
      await playback.saveSession();
      final next = FakeEngine();
      final again = PlaybackController(
        engine: next,
        store: DirectStore(db),
        isAvailable: (path) => !path.endsWith('/1.flac'),
      );
      addTearDown(again.dispose);
      await again.restore();
      expect(next.opened.single, hasLength(2));
      expect(
        next.state.value.queue[next.state.value.index],
        endsWith('/3.flac'),
      );
    });

    test('o motor que não abre a sessão não derruba a abertura', () async {
      await playback.playAlbum(albumId);
      await playback.saveSession();
      final again = PlaybackController(
        engine: _StuckEngine(),
        store: DirectStore(db),
      );
      addTearDown(again.dispose);
      await again.restore();
      expect(again.resumable, isFalse);
    });

    test('volta parada na faixa e no ponto, com volume e repetir', () async {
      await playback.playAlbum(albumId, index: 2);
      await engine.setVolume(0.4);
      await engine.setRepeat(PlayerRepeat.all);
      engine.set(
        engine.state.value.copyWith(position: const Duration(seconds: 42)),
      );
      await playback.saveSession();

      final next = FakeEngine();
      final again = await reopen(next);
      expect(again.current!.title, 'Maré Alta 3');
      expect(again.state.position, const Duration(seconds: 42));
      expect(again.state.playing, isFalse);
      expect(again.state.volume, 0.4);
      expect(again.state.repeat, PlayerRepeat.all);
      expect(again.resumable, isTrue);
      await next.playOrPause();
      expect(again.resumable, isFalse);
    });

    test(
      'um arquivo aberto de fora passa na frente da fila guardada',
      () async {
        await playback.playAlbum(albumId);
        await playback.saveSession();
        final next = FakeEngine();
        await reopen(next, open: ['/fora/a.mp3']);
        expect(next.opened.single, ['/fora/a.mp3']);
        expect(next.state.value.playing, isTrue);
      },
    );

    test('sem sessão, não abre nada', () async {
      final next = FakeEngine();
      await reopen(next);
      expect(next.opened, isEmpty);
    });

    test('uma sessão ilegível é ignorada', () async {
      await DirectStore(db).setSetting('session', 'lixo');
      final next = FakeEngine();
      await reopen(next);
      expect(next.opened, isEmpty);
    });
  });

  group('nota', () {
    test('sobrevive a reler o arquivo, e 0 tira', () async {
      final track = db.tracks().first;
      await playback.setRating(track, 4);
      expect(db.tracks().firstWhere((t) => t.id == track.id).rating, 4);
      db.upsertTrack(
        ScannedTrack(
          path: track.path,
          title: 'Outro título',
          artist: track.artist,
          albumArtist: track.artist,
          album: track.album,
          durationMs: 1000,
          size: 1,
          mtime: 2,
        ),
        db.folders().single.id,
        2000,
      );
      expect(db.tracks().firstWhere((t) => t.id == track.id).rating, 4);
      await playback.setRating(track, 0);
      expect(db.tracks().firstWhere((t) => t.id == track.id).rating, 0);
    });

    test('quem está na fila já aparece com a nota', () async {
      await playback.playAlbum(albumId);
      await playback.setRating(playback.current!, 5);
      expect(playback.current!.rating, 5);
    });

    test('a automática leva 4 e 5, as melhores primeiro', () {
      final tracks = db.tracks();
      db.setRating(tracks[0].id, 4);
      db.setRating(tracks[1].id, 5);
      db.setRating(tracks[2].id, 3);
      expect(db.topRated(10).map((t) => t.id), [tracks[1].id, tracks[0].id]);
      expect(
        db
            .autoPlaylists()
            .firstWhere((p) => p.kind == PlaylistKind.topRated)
            .trackCount,
        2,
      );
    });

    test('ordenar por nota', () {
      final tracks = db.tracks();
      db.setRating(tracks[1].id, 5);
      final sorted = db.tracks(
        const TrackQuery(sort: TrackSort.rating, ascending: false),
      );
      expect(sorted.first.id, tracks[1].id);
    });
  });

  group('mix dinâmico', () {
    setUp(() => seedAlbum(db, album: 'Longo', tracks: 40));

    test('com a fila vazia, ligar já toca', () async {
      await playback.setDynamicMix(true);
      expect(engine.opened, hasLength(1));
      expect(playback.queue, hasLength(PlaybackController.mixBatch));
      expect(playback.current, isNotNull);
    });

    test('soma faixas quando faltam poucas, sem repetir', () async {
      await playback.setDynamicMix(true);
      await engine.jump(PlaybackController.mixBatch - 2);
      await pumpEventQueue();
      expect(playback.queue, hasLength(PlaybackController.mixBatch * 2));
      final paths = playback.queue.map((t) => t.path).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('desligado, a fila para de crescer e fica como está', () async {
      await playback.setDynamicMix(true);
      await playback.setDynamicMix(false);
      await engine.jump(PlaybackController.mixBatch - 1);
      await pumpEventQueue();
      expect(playback.queue, hasLength(PlaybackController.mixBatch));
    });

    test('escolher outra coisa encerra o mix', () async {
      await playback.setDynamicMix(true);
      await playback.playAlbum(albumId);
      expect(playback.dynamicMix, isFalse);
      await engine.jump(2);
      await pumpEventQueue();
      expect(playback.queue, hasLength(3));
    });

    test('uma estrela fica de fora', () {
      for (final track in db.tracks()) {
        db.setRating(track.id, 1);
      }
      expect(db.dynamicMixBatch(10), isEmpty);
    });

    test('numa biblioteca pequena, volta a repetir em vez de parar', () {
      final all = [for (final t in db.tracks()) t.path];
      expect(db.dynamicMixBatch(5, exclude: all), hasLength(5));
    });

    test('a sessão guarda o mix ligado', () async {
      await playback.setDynamicMix(true);
      await playback.saveSession();
      final again = PlaybackController(
        engine: FakeEngine(),
        store: DirectStore(db),
      );
      addTearDown(again.dispose);
      await again.restore();
      expect(again.dynamicMix, isTrue);
    });
  });
}

class _StuckEngine extends FakeEngine {
  @override
  Future<void> open(
    List<String> paths, {
    int index = 0,
    Duration start = Duration.zero,
    bool play = true,
  }) => Future.error(TimeoutException('não abriu'));
}

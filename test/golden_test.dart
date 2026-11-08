// As telas como elas ficam, com a fonte de verdade: os testes de widget usam uma
// fonte de blocos, e aqui entram a Roboto e os ícones que vêm com o Flutter.
//
//   flutter test --update-goldens test/golden_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/tag_edit/tag_edit.dart';
import 'package:psito_player/src/library/tag_edit/tag_files.dart';
import 'package:psito_player/src/ui/organisms/album_tag_editor.dart';
import 'package:psito_player/src/ui/organisms/organize_dialog.dart';
import 'package:psito_player/src/ui/organisms/tag_batch_dialog.dart';
import 'package:psito_player/src/ui/organisms/tag_editor_dialog.dart';
import 'package:psito_player/src/ui/player_actions.dart';
import 'package:psito_player/src/ui/templates/shell_template.dart';

import 'helpers.dart';

/// Uma diferença de antialias entre máquinas não é uma tela diferente.
class _TolerantComparator extends LocalFileComparator {
  static const _tolerance = 0.005;

  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Os mixes mudam com o dia: sem um dia fixo, as imagens não valeriam amanhã.
int _clock() => DateTime(2026, 11, 2, 12).millisecondsSinceEpoch;

const _albums = [
  ('Maré Alta', 'Coral Vento', 'Indie'),
  ('Serra Azul', 'Ana Rio', 'MPB'),
  ('Noite Clara', 'Os Faróis', 'Rock'),
  ('Areia Fina', 'Ana Rio', 'MPB'),
  ('Ilha de Vidro', 'Lua Nova', 'Eletrônica'),
  ('Folha Seca', 'Coral Vento', 'Indie'),
  ('Tempo Bom', 'Os Faróis', 'Rock'),
  ('Céu Aberto', 'Lua Nova', 'Eletrônica'),
];

void _seed(LibraryDb db) {
  final folder = db.addFolder('/musica');
  var added = 1000;
  for (final (album, artist, genre) in _albums) {
    for (var i = 1; i <= 9; i++) {
      final id = db.upsertTrack(
        ScannedTrack(
          path: '/musica/$album/$i.flac',
          title: '$album, parte $i',
          artist: artist,
          albumArtist: artist,
          album: album,
          genre: genre,
          trackNumber: i,
          year: 2020 + i,
          durationMs: 180000 + i * 7000,
          size: 30000000,
          mtime: 1,
        ),
        folder,
        added++,
      );
      assert(id > 0);
    }
  }
  db.markScanned(folder, 1000);
  final tracks = db.tracks(const TrackQuery());
  for (final (i, track) in tracks.take(6).indexed) {
    for (var n = 0; n <= 6 - i; n++) {
      db.recordPlay(track.id, 5000 + n);
    }
  }
  db.createPlaylist('Para correr', 2000, [
    for (final t in tracks.take(12)) t.path,
  ]);
  db.createPlaylist('Domingo', 2000, [for (final t in tracks.skip(20)) t.path]);
}

void main() {
  late LibraryDb db;
  late FakeEngine engine;

  setUpAll(() async {
    await loadRealFonts();
    goldenFileComparator = _TolerantComparator(
      Uri.file('${Directory.current.path}/test/golden_test.dart'),
    );
  });

  setUp(() {
    db = LibraryDb.memory();
    engine = FakeEngine();
    _seed(db);
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, {String theme = 'dark'}) async {
    setWindow(tester, 1280, 800);
    db.setSetting('settings', '{"themeMode":"$theme"}');
    await pumpPlayer(
      tester,
      engine: engine,
      db: db,
      now: _clock,
      initialPaths: [for (var i = 1; i <= 6; i++) '/musica/Maré Alta/$i.flac'],
    );
    await tester.pump();
    engine.set(
      engine.state.value.copyWith(position: const Duration(seconds: 41)),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  testWidgets('Início', (tester) async {
    await open(tester);
    await settle(tester);
    await shot(tester, 'home');
  });

  testWidgets('Início, no tema claro', (tester) async {
    await open(tester, theme: 'light');
    await settle(tester);
    await shot(tester, 'home_light');
  });

  testWidgets('Biblioteca', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.library_music_rounded).first);
    await settle(tester);
    await shot(tester, 'library');
  });

  testWidgets('Álbum', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.library_music_rounded).first);
    await settle(tester);
    await tester.tap(find.text('Maré Alta').first);
    await settle(tester);
    await shot(tester, 'album');
  });

  testWidgets('Playlist', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.playlist_play_rounded).first);
    await settle(tester);
    await tester.tap(find.text('Para correr').first);
    await settle(tester);
    await shot(tester, 'playlist');
  });

  testWidgets('Biblioteca com o ponteiro numa playlist', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Playlists').first);
    await settle(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Para correr').first));
    await settle(tester);
    await shot(tester, 'playlists');
  });

  testWidgets('O menu do botão direito num álbum', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Biblioteca').first);
    await settle(tester);
    await tester.tap(find.text('Céu Aberto').first, buttons: kSecondaryButton);
    await settle(tester);
    await shot(tester, 'album_menu');
  });

  testWidgets('Adicionar músicas', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Playlists').first);
    await settle(tester);
    await tester.tap(find.text('Para correr').first);
    await settle(tester);
    await tester.tap(find.text('Adicionar músicas'));
    await settle(tester);
    await shot(tester, 'add_tracks');
  });

  testWidgets('Playlist inteligente', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.playlist_play_rounded).first);
    await settle(tester);
    await tester.tap(find.text('Playlist inteligente'));
    await settle(tester);
    await tester.tap(find.text('Adicionar regra'));
    await settle(tester);
    await shot(tester, 'smart_playlist');
  });

  testWidgets('Nova playlist, por pastas', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Playlists').first);
    await settle(tester);
    await tester.tap(find.text('Nova playlist'));
    await settle(tester);
    await tester.tap(find.text('Pastas').last);
    await settle(tester);
    await tester.tap(find.text('Maré Alta').last);
    await settle(tester);
    await shot(tester, 'new_playlist');
  });

  testWidgets('Ajustes', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ajustes').first);
    await settle(tester);
    await shot(tester, 'settings');
  });

  group('editor de tags', () {
    const root = '/tmp/psito-golden-tags';
    late List<Track> tracks;

    setUp(() {
      final dir = Directory(root);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      final folder = db.addFolder(root);
      final fields = [
        ('Correnteza', 'Coral Vento'),
        ('Linha do Horizonte', 'Coral Vento'),
        ('Farol', 'Ana Rio'),
      ];
      for (final (i, (title, artist)) in fields.indexed) {
        final path = '$root/0${i + 1} $title.flac';
        File('test/fixtures/tone.flac').copySync(path);
        writeTags(
          path,
          TagEdit(
            fields: {
              TagField.title: title,
              TagField.artist: artist,
              TagField.albumArtist: 'Coral Vento',
              TagField.album: 'Maré Baixa',
              TagField.year: '2021',
              TagField.trackNumber: '${i + 1}',
              TagField.trackTotal: '3',
              TagField.discNumber: '1',
              TagField.discTotal: '1',
              TagField.genre: 'MPB',
            },
          ),
        );
        db.upsertTrack(
          ScannedTrack(
            path: path,
            title: title,
            artist: artist,
            albumArtist: 'Coral Vento',
            album: 'Maré Baixa',
            trackNumber: i + 1,
            sampleRate: 44100,
            bitrate: 1024000,
            size: 1,
            mtime: 1,
          ),
          folder,
          1,
        );
      }
      tracks = db.tracks(const TrackQuery()).where((t) {
        return t.path.startsWith(root);
      }).toList();
    });

    Future<void> real(WidgetTester tester) async {
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    BuildContext host(WidgetTester tester) =>
        tester.element(find.byType(ShellTemplate));
    PlayerActions actions(WidgetTester tester) =>
        PlayerActions.maybeOf(host(tester))!;

    testWidgets('uma faixa', (tester) async {
      await open(tester);
      await settle(tester);
      unawaited(showTagEditor(host(tester), actions(tester), tracks, 1));
      await real(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Compositor'),
        'Ana',
      );
      await settle(tester);
      await shot(tester, 'tag_editor');
    });

    testWidgets('várias faixas', (tester) async {
      await open(tester);
      await settle(tester);
      unawaited(showBatchTagEditor(host(tester), actions(tester), tracks));
      await real(tester);
      await shot(tester, 'tag_batch');
    });

    testWidgets('o álbum', (tester) async {
      await open(tester);
      await settle(tester);
      final album = db.albums().firstWhere((a) => a.title == 'Maré Baixa');
      unawaited(showAlbumTagEditor(host(tester), actions(tester), album));
      await real(tester);
      await shot(tester, 'tag_album');
    });

    testWidgets('organizar', (tester) async {
      await open(tester);
      await settle(tester);
      unawaited(showOrganize(host(tester), actions(tester), tracks: tracks));
      await real(tester);
      await shot(tester, 'organize');
    });

    testWidgets('estreita', (tester) async {
      await open(tester);
      setWindow(tester, 420, 800);
      await settle(tester);
      unawaited(showTagEditor(host(tester), actions(tester), tracks, 1));
      await real(tester);
      await shot(tester, 'tag_narrow');
    });
  });

  testWidgets('Sobre', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ajustes').first);
    await settle(tester);
    await tester.tap(find.text('Sobre').first);
    await settle(tester);
    await shot(tester, 'settings_about');
    await tester.drag(find.text('Spotify Redesign'), const Offset(0, -560));
    await settle(tester);
    await shot(tester, 'settings_about_licenses');
  });

  testWidgets('Equalizador', (tester) async {
    db.setSetting('settings', '{"equalizerOn":true}');
    setWindow(tester, 1280, 800);
    await pumpPlayer(tester, engine: engine, db: db, now: _clock);
    await settle(tester);
    await tester.tap(find.byTooltip('Ajustes').first);
    await settle(tester);
    await tester.tap(find.text('Equalizador'));
    await settle(tester);
    await tester.tap(find.text('Rock'));
    await settle(tester);
    await shot(tester, 'equalizer');
  });

  testWidgets('Tela da música', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Abrir a tela da música'));
    await settle(tester);
    await shot(tester, 'track');
  });

  testWidgets('Artista', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Biblioteca').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Artistas'));
    await settle(tester);
    await tester.tap(find.text('Ana Rio').first);
    await settle(tester);
    await shot(tester, 'artist');
  });

  testWidgets('Busca antes de digitar', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Buscar').first);
    await settle(tester);
    await shot(tester, 'search');
  });

  testWidgets('Modo compacto', (tester) async {
    setWindow(tester, 420, 760);
    db.setSetting('settings', '{"mode":"compact"}');
    await pumpPlayer(
      tester,
      engine: engine,
      db: db,
      now: _clock,
      initialPaths: [for (var i = 1; i <= 6; i++) '/musica/Maré Alta/$i.flac'],
    );
    await settle(tester);
    await shot(tester, 'compact');
    await tester.tap(find.byTooltip('Abrir a tela da música'));
    await settle(tester);
    await shot(tester, 'compact_track');
  });

  testWidgets('Miniplayer', (tester) async {
    setWindow(tester, 300, 364);
    db.setSetting('settings', '{"mode":"mini"}');
    await pumpPlayer(
      tester,
      engine: engine,
      db: db,
      now: _clock,
      initialPaths: [for (var i = 1; i <= 6; i++) '/musica/Maré Alta/$i.flac'],
    );
    await settle(tester);
    await shot(tester, 'mini');
  });

  testWidgets('Fila ao lado', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Fila').first);
    await settle(tester);
    await shot(tester, 'queue');
  });
}

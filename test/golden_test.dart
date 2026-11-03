// As telas como elas ficam, com a fonte de verdade: os testes de widget usam uma
// fonte de blocos, e aqui entram a Roboto e os ícones que vêm com o Flutter.
//
//   flutter test --update-goldens test/golden_test.dart
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/models.dart';

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

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('$fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
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
    await _loadFonts();
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

  testWidgets('Ajustes', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Ajustes').first);
    await settle(tester);
    await shot(tester, 'settings');
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

// test/playlist_cover_test.dart
//
// A arte das playlists: só capas de verdade na grade, a decoração sem nenhuma, e a
// capa que a pessoa escolhe.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/ui/atoms/cover_art.dart';
import 'package:psito_player/src/ui/atoms/generic_art.dart';
import 'package:psito_player/src/ui/atoms/mosaic_cover.dart';

import 'helpers.dart';

Widget _mosaic(List<String?> paths) => MaterialApp(
  home: Center(
    child: MosaicCover(
      size: 200,
      seed: 'Domingo',
      covers: [
        for (final (i, path) in paths.indexed) (path: path, seed: 'album $i'),
      ],
    ),
  ),
);

/// O caminho de cada capa desenhada, de cima para baixo.
List<String?> _cells(WidgetTester tester) => [
  for (final art in tester.widgetList<CoverArt>(find.byType(CoverArt)))
    art.path,
];

/// Uma imagem de verdade, 800×400, para ver o corte.
String _image(Directory dir) {
  final file = File(p.join(dir.path, 'foto.png'));
  file.writeAsBytesSync(img.encodePng(img.Image(width: 800, height: 400)));
  return file.path;
}

void main() {
  group('a grade', () {
    testWidgets('uma capa ocupa tudo', (tester) async {
      await tester.pumpWidget(_mosaic(['a.jpg']));
      expect(_cells(tester), ['a.jpg']);
      expect(tester.getSize(find.byType(CoverArt)), const Size(200, 200));
    });

    testWidgets('duas e três repetem na diagonal', (tester) async {
      await tester.pumpWidget(_mosaic(['a.jpg', 'b.jpg']));
      expect(_cells(tester), ['a.jpg', 'b.jpg', 'b.jpg', 'a.jpg']);
      await tester.pumpWidget(_mosaic(['a.jpg', 'b.jpg', 'c.jpg']));
      expect(_cells(tester), ['a.jpg', 'b.jpg', 'c.jpg', 'a.jpg']);
    });

    testWidgets('quatro, cada uma num canto', (tester) async {
      await tester.pumpWidget(_mosaic(['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg']));
      expect(_cells(tester), ['a.jpg', 'b.jpg', 'c.jpg', 'd.jpg']);
    });

    testWidgets('quem não tem capa não entra na grade', (tester) async {
      await tester.pumpWidget(_mosaic([null, 'a.jpg', null]));
      expect(_cells(tester), ['a.jpg']);
    });

    testWidgets('sem nenhuma, a decoração com a nota', (tester) async {
      for (final paths in [
        const <String?>[],
        const <String?>[null, null, null, null],
      ]) {
        await tester.pumpWidget(_mosaic(paths));
        expect(find.byType(CoverArt), findsNothing);
        expect(find.byType(GenericArt), findsOneWidget);
        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      }
    });
  });

  group('o banco', () {
    late LibraryDb db;

    setUp(() => db = LibraryDb.memory());
    tearDown(() => db.close());

    void album(String title, String? cover, int folder) {
      final albumId = db.upsertTrack(
        ScannedTrack(
          path: '/m/$title.mp3',
          title: title,
          album: title,
          size: 1,
          mtime: 1,
        ),
        folder,
        1,
      );
      if (cover != null) db.setAlbumCover(albumId, cover, 'embedded');
    }

    test('um álbum sem capa não ocupa lugar', () {
      final folder = db.addFolder('/m');
      album('A', null, folder);
      album('B', 'b.jpg', folder);
      db.createPlaylist('Lista', 1, ['/m/A.mp3', '/m/B.mp3']);
      expect(db.playlists().single.covers.map((c) => c.path), ['b.jpg']);
    });

    test('a capa escolhida passa na frente e sai sem deixar rastro', () {
      final folder = db.addFolder('/m');
      album('B', 'b.jpg', folder);
      final id = db.createPlaylist('Lista', 1, ['/m/B.mp3']);
      db.setPlaylistCover(id, 'minha.jpg', 2);
      var playlist = db.playlists().single;
      expect(playlist.customCover, 'minha.jpg');
      expect(playlist.covers.map((c) => c.path), ['minha.jpg']);
      db.setPlaylistCover(id, null, 3);
      playlist = db.playlists().single;
      expect(playlist.customCover, isNull);
      expect(playlist.covers.map((c) => c.path), ['b.jpg']);
    });
  });

  group('na tela', () {
    late Directory dir;
    late LibraryDb db;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('capa');
      db = LibraryDb.memory()..createPlaylist('Domingo', 1);
    });
    tearDown(() {
      db.close();
      dir.deleteSync(recursive: true);
    });

    Future<void> open(WidgetTester tester, String image) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(
        tester,
        db: db,
        pickedImage: image,
        playlistCovers: p.join(dir.path, 'capas'),
      );
      await tester.tap(find.byIcon(Icons.playlist_play_rounded).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Domingo').first);
      await tester.pumpAndSettle();
    }

    testWidgets('o ícone escolhe, e o menu remove', (tester) async {
      await tester.runAsync(() async {
        await open(tester, _image(dir));
      });
      final removeText = find.text('Remover capa');
      await tester.tap(find.byTooltip('Mais opções').last);
      await tester.pumpAndSettle();
      expect(find.text('Escolher capa'), findsOneWidget);
      expect(removeText, findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Escolher capa'));
        for (var i = 0; i < 200; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (db.playlists().single.customCover != null) break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      });
      expect(db.playlists().single.customCover, isNotNull);

      await tester.tap(find.byTooltip('Mais opções').last);
      await tester.pumpAndSettle();
      await tester.tap(removeText);
      await tester.pumpAndSettle();
      expect(db.playlists().single.customCover, isNull);
    });

    testWidgets('uma imagem ruim avisa', (tester) async {
      final bad = File(p.join(dir.path, 'ruim.png'))..writeAsStringSync('x');
      await tester.runAsync(() async {
        await open(tester, bad.path);
        await tester.tap(find.byTooltip('Escolher capa'));
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (find.text('Não deu para ler essa imagem').evaluate().isNotEmpty) {
            break;
          }
        }
      });
      expect(find.text('Não deu para ler essa imagem'), findsOneWidget);
    });
  });

  group('escolher a capa', () {
    late Directory dir;
    late LibraryDb db;
    late LibraryController library;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('capa');
      db = LibraryDb.memory();
      library = LibraryController(
        store: DirectStore(db),
        scanner: FakeScanner(),
        playlistCoverDir: p.join(dir.path, 'capas'),
      );
    });
    tearDown(() {
      library.dispose();
      db.close();
      dir.deleteSync(recursive: true);
    });

    Future<Playlist> created() async {
      await library.createPlaylist('Lista');
      return library.playlists.single;
    }

    test('grava uma cópia quadrada, e a original pode sumir', () async {
      final image = _image(dir);
      expect(await library.setPlaylistCover(await created(), image), isTrue);
      File(image).deleteSync();
      final cover = library.playlists.single.customCover!;
      final saved = img.decodeJpg(File(cover).readAsBytesSync())!;
      expect(saved.width, saved.height);
    });

    test('trocar e remover apagam o arquivo de antes', () async {
      final image = _image(dir);
      await library.setPlaylistCover(await created(), image);
      final first = library.playlists.single.customCover!;
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await library.setPlaylistCover(library.playlists.single, image);
      final second = library.playlists.single.customCover!;
      expect(second, isNot(first));
      expect(File(first).existsSync(), isFalse);
      await library.removePlaylistCover(library.playlists.single);
      expect(library.playlists.single.customCover, isNull);
      expect(File(second).existsSync(), isFalse);
    });

    test('apagar a playlist leva a capa junto', () async {
      await library.setPlaylistCover(await created(), _image(dir));
      final cover = library.playlists.single.customCover!;
      await library.deletePlaylist(library.playlists.single);
      expect(File(cover).existsSync(), isFalse);
    });

    test('um arquivo que não é imagem não muda nada', () async {
      final text = File(p.join(dir.path, 'nota.png'))
        ..writeAsStringSync('não sou uma imagem');
      final playlist = await created();
      expect(await library.setPlaylistCover(playlist, text.path), isFalse);
      expect(
        await library.setPlaylistCover(playlist, p.join(dir.path, 'sumiu.png')),
        isFalse,
      );
      expect(library.playlists.single.customCover, isNull);
    });
  });
}

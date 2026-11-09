// Organizar e copiar: o padrão, os nomes, a prévia, mover e desfazer com a
// biblioteca, e a tela.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/player_app.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/organize/file_organizer.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/ui/organisms/organize_dialog.dart';
import 'package:psito_player/src/ui/player_actions.dart';

import 'helpers.dart';

const _item = OrganizeItem(
  path: '/m/x.flac',
  root: '/m',
  title: 'Maré',
  artist: 'Ana',
  albumArtist: 'Coral',
  album: 'Disco',
  trackNumber: 3,
  year: 2021,
);

List<String> _expand(
  OrganizeItem item, {
  bool strict = false,
  String? pattern,
}) => expandOrganizePattern(
  pattern ?? defaultOrganizePattern,
  item,
  unknown: 'Desconhecido',
  strict: strict,
);

OrganizeItem _with({
  String title = 'Maré',
  String artist = 'Ana',
  String albumArtist = 'Coral',
  String album = 'Disco',
  int? track = 3,
  int? disc,
  bool multi = false,
  int? year = 2021,
}) => OrganizeItem(
  path: '/m/x.flac',
  root: '/m',
  title: title,
  artist: artist,
  albumArtist: albumArtist,
  album: album,
  trackNumber: track,
  discNumber: disc,
  multiDisc: multi,
  year: year,
);

void main() {
  group('o padrão', () {
    test('o normal', () {
      expect(_expand(_item), ['Coral', '2021 - Disco', '03 Maré']);
    });

    test('o que falta não deixa sobra', () {
      expect(_expand(_with(year: null, track: null)), [
        'Coral',
        'Disco',
        'Maré',
      ]);
    });

    test('sem artista do álbum, o artista; sem nada, Desconhecido', () {
      expect(_expand(_with(albumArtist: ''))[0], 'Ana');
      expect(_expand(_with(albumArtist: '', artist: ''))[0], 'Desconhecido');
    });

    test('o disco só entra em álbum de mais de um', () {
      expect(_expand(_with(disc: 2))[2], '03 Maré');
      expect(_expand(_with(disc: 2, multi: true))[2], '2-03 Maré');
    });

    test('a barra de um nome não vira pasta', () {
      expect(_expand(_with(albumArtist: 'AC/DC'))[0], 'AC_DC');
    });

    test('no FAT, sai o que ele recusa', () {
      expect(_expand(_with(title: 'A: B?'), strict: true)[2], '03 A_ B_');
      expect(_expand(_with(title: 'A: B?'))[2], '03 A: B?');
    });

    test('o que vale e o que não vale', () {
      expect(organizePatternValid(defaultOrganizePattern), isTrue);
      expect(organizePatternValid('{album}/{title}'), isTrue);
      expect(organizePatternValid('{album}'), isFalse);
      expect(organizePatternValid('{nada}/{title}'), isFalse);
      expect(organizePatternValid('../{title}'), isFalse);
      expect(organizePatternValid('/{title}'), isFalse);
      expect(organizePatternValid('{album}//{title}'), isFalse);
      expect(organizePatternValid('{title'), isFalse);
    });
  });

  group('nomes seguros', () {
    String safe(String n, [String ext = '']) =>
        safeFileName(n, unknown: 'X', extension: ext);

    test('tira pontos e espaços das pontas', () {
      expect(safe('.oculta. '), 'oculta');
      expect(safe('...'), 'X');
      expect(safe('Disco Vol. 1.'), 'Disco Vol. 1');
    });

    test('cabe em 255 bytes, sem cortar uma letra ao meio', () {
      final name = safe('ç' * 300, '.flac');
      expect(name.endsWith('.flac'), isTrue);
      expect(systemEncoding.encode(name).length, lessThanOrEqualTo(255));
      expect(name.contains('�'), isFalse);
    });

    test('os sistemas que pedem nomes seguros', () {
      expect(strictFileSystem('vfat'), isTrue);
      expect(strictFileSystem('exfat'), isTrue);
      expect(strictFileSystem('fuseblk'), isTrue);
      expect(strictFileSystem('ext4'), isFalse);
    });
  });

  test('os nomes de dispositivo do Windows ganham um sublinhado', () {
    String clean(String n, {bool strict = true}) =>
        safeFileName(n, unknown: 'X', extension: '.flac', strict: strict);
    expect(clean('CON'), 'CON_.flac');
    expect(clean('nul'), 'nul_.flac');
    expect(clean('Com1'), 'Com1_.flac');
    expect(clean('LPT9.ao vivo'), 'LPT9.ao vivo_.flac');
    expect(clean('Contato'), 'Contato.flac');
    expect(clean('COM'), 'COM.flac');
    expect(clean('CON', strict: false), 'CON.flac');
  });

  group('com arquivos', () {
    late Directory dir;
    late String root;
    late LibraryDb db;
    late LibraryController library;
    late int folder;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('psito-organize');
      root = p.join(dir.path, 'Musica');
      Directory(root).createSync();
      db = LibraryDb.memory();
      folder = db.addFolder(root);
      library = LibraryController(
        store: DirectStore(db),
        scanner: FakeScanner(),
        tagUndoDir: p.join(dir.path, 'tag-undo'),
      );
    });

    tearDown(() {
      library.dispose();
      db.close();
      dir.deleteSync(recursive: true);
    });

    String add(
      String relative, {
      String title = 'Faixa',
      String album = 'Disco',
      String artist = 'Ana',
      int? track = 1,
      int? disc,
      String? lyrics,
      List<int> bytes = const [1, 2, 3],
    }) {
      final path = p.normalize(p.join(root, relative));
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
      db.upsertTrack(
        ScannedTrack(
          path: path,
          title: title,
          artist: artist,
          albumArtist: artist,
          album: album,
          trackNumber: track,
          discNumber: disc,
          size: bytes.length,
          mtime: 1,
          lyricsPath: lyrics,
        ),
        folder,
        1,
      );
      return path;
    }

    OrganizePlan plan({String? copyTo, String? playing, String? pattern}) =>
        planOrganize(
          OrganizeRequest(
            items: db.organizeItems(folderId: folder),
            pattern: pattern ?? '{albumArtist}/{album}/{track} {title}',
            unknown: 'Desconhecido',
            copyTo: copyTo,
            playing: playing,
          ),
        );

    String target(String relative) => p.normalize(p.join(root, relative));

    test('a prévia não mexe em nada, e só lista o que muda', () {
      final path = add('solta.flac');
      add('Ana/Disco/02 Outra.flac', title: 'Outra', track: 2);
      final result = plan();
      expect(result.unchanged, 1);
      expect(result.moves.single.from, path);
      expect(result.moves.single.to, target('Ana/Disco/01 Faixa.flac'));
      expect(File(path).existsSync(), isTrue);
    });

    test('dois para o mesmo nome, e um que já existe, ficam marcados', () {
      add('a.flac', title: 'Igual');
      add('b.flac', title: 'Igual');
      final same = plan();
      expect(same.moves.map((m) => m.problem).toSet(), {
        null,
        MoveProblem.sameTarget,
      });
      File(target('Ana/Disco/01 Igual.flac'))
        ..createSync(recursive: true)
        ..writeAsStringSync('outro');
      expect(plan().moves.every((m) => m.problem != null), isTrue);
    });

    test('a faixa tocando fica', () {
      final path = add('a.flac');
      expect(plan(playing: path).moves.single.problem, MoveProblem.playing);
    });

    test('mover mantém o id, as marcas e as playlists, e desfaz', () async {
      final path = add('velha/a.flac');
      final lrc = p.join(root, 'velha/a.lrc');
      File(lrc).writeAsStringSync('[00:01.00]oi');
      File(p.join(root, 'velha/cover.jpg')).writeAsStringSync('capa');
      db.setLyricsPath(path, lrc);
      final before = db.tracks().single;
      db.setFavorite(before.id, true);
      db.setRating(before.id, 4);
      db.recordPlay(before.id, 5);
      db.createPlaylist('P', 1, [path]);
      db.setLyricsOffset(path, 300);
      await library.reload();

      final report = await library.runOrganize(plan());
      expect(report.failed, isEmpty);
      expect(report.done, 3);
      final to = target('Ana/Disco/01 Faixa.flac');
      expect(File(to).existsSync(), isTrue);
      expect(File(path).existsSync(), isFalse);
      expect(File(p.setExtension(to, '.lrc')).existsSync(), isTrue);
      expect(File(target('Ana/Disco/cover.jpg')).existsSync(), isTrue);
      expect(Directory(p.join(root, 'velha')).existsSync(), isFalse);

      final moved = db.tracks().single;
      expect(moved.id, before.id);
      expect(moved.path, to);
      expect(moved.favorite, isTrue);
      expect(moved.rating, 4);
      expect(moved.playCount, 1);
      expect(moved.lyricsPath, p.setExtension(to, '.lrc'));
      expect(db.lyricsOffset(to), 300);
      final list = db.playlists().single;
      expect(db.playlistTracks(list.id).map((t) => t.path), [to]);

      final undone = await library.undoOrganize(report.undoId!);
      expect(undone.done, 3);
      expect(File(path).existsSync(), isTrue);
      expect(File(lrc).existsSync(), isTrue);
      expect(File(p.join(root, 'velha/cover.jpg')).existsSync(), isTrue);
      expect(Directory(p.join(root, 'Ana')).existsSync(), isFalse);
      expect(db.tracks().single.path, path);
      expect(db.playlistTracks(list.id).map((t) => t.path), [path]);
    });

    test('a pasta que ainda tem coisa fica', () async {
      add('velha/a.flac');
      File(p.join(root, 'velha/nota.txt')).writeAsStringSync('x');
      await library.reload();
      await library.runOrganize(plan());
      expect(Directory(p.join(root, 'velha')).existsSync(), isTrue);
    });

    test('a capa fica se só parte da pasta muda', () async {
      add('d/a.flac', title: 'A', album: 'Um');
      add('d/b.flac', title: 'B', album: 'Dois');
      File(p.join(root, 'd/cover.jpg')).writeAsStringSync('capa');
      await library.reload();
      await library.runOrganize(plan());
      expect(File(p.join(root, 'd/cover.jpg')).existsSync(), isTrue);
    });

    test('nunca passa por cima, nem se aparecer depois da prévia', () async {
      add('a.flac');
      await library.reload();
      final ready = plan();
      File(ready.moves.single.to)
        ..createSync(recursive: true)
        ..writeAsStringSync('novo');
      final report = await library.runOrganize(ready);
      expect(report.failed.single.path, target('a.flac'));
      expect(File(ready.moves.single.to).readAsStringSync(), 'novo');
      expect(File(target('a.flac')).existsSync(), isTrue);
    });

    test(
      'copiar não apaga, leva a letra e a capa, e sabe o que já foi',
      () async {
        final path = add('a.flac');
        File(p.join(root, 'a.lrc')).writeAsStringSync('oi');
        File(p.join(root, 'folder.jpg')).writeAsStringSync('capa');
        final out = p.join(dir.path, 'pendrive');
        Directory(out).createSync();
        await library.reload();
        final report = await library.runOrganize(plan(copyTo: out));
        expect(report.done, 3);
        expect(report.undoId, isNull);
        expect(File(path).existsSync(), isTrue);
        expect(
          File(p.join(out, 'Ana/Disco/01 Faixa.flac')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(out, 'Ana/Disco/01 Faixa.lrc')).existsSync(),
          isTrue,
        );
        expect(File(p.join(out, 'Ana/Disco/folder.jpg')).existsSync(), isTrue);
        expect(db.tracks().single.path, path);
        final again = plan(copyTo: out);
        expect(again.moves, isEmpty);
        expect(again.unchanged, 1);
      },
    );

    test('cancelar para entre um arquivo e outro', () async {
      add('a.flac', title: 'A');
      add('b.flac', title: 'B');
      await library.reload();
      library.addListener(() {
        if (library.fileJob?.path != null) library.cancelFileJob();
      });
      final report = await library.runOrganize(plan());
      expect(report.done, 1);
      expect(report.cancelled, isTrue);
    });

    test('500 faixas com nomes repetidos, sem perder nada', () async {
      for (var i = 0; i < 500; i++) {
        final path = add(
          'bagunca/${i % 7}/f$i.flac',
          title: i % 50 == 0 ? 'Repetida' : 'Faixa $i',
          album: 'Album ${i % 20}',
          artist: 'Artista ${i % 5}',
          track: i % 50 == 0 ? 1 : i,
        );
        final id = db.tracks().firstWhere((t) => t.path == path).id;
        if (i % 3 == 0) db.setRating(id, 3);
        if (i % 40 == 0) {
          File(p.setExtension(path, '.lrc')).writeAsStringSync('oi');
        }
      }
      await library.reload();
      final before = {for (final t in db.tracks()) t.id: t.rating};
      final ready = plan();
      expect(ready.problems, greaterThan(0));
      final report = await library.runOrganize(ready);
      expect(report.failed, isEmpty);
      final tracks = db.tracks();
      expect(tracks, hasLength(500));
      expect(tracks.every((t) => File(t.path).existsSync()), isTrue);
      expect({for (final t in tracks) t.id: t.rating}, before);
      await library.undoOrganize(report.undoId!);
      expect(db.tracks().every((t) => t.path.contains('bagunca')), isTrue);
      expect(db.tracks().every((t) => File(t.path).existsSync()), isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));

    group('a tela', () {
      late PlaybackController playback;
      late PlayerActions actions;
      late BuildContext host;

      setUp(() {
        playback = PlaybackController(
          engine: FakeEngine(),
          store: DirectStore(db),
        );
      });

      Future<void> settle(WidgetTester tester) async {
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> pumpHost(
        WidgetTester tester, {
        double width = 1280,
        double height = 800,
      }) async {
        setWindow(tester, width, height);
        await tester.pumpWidget(
          MaterialApp(
            theme: playerBaseTheme(const Color(0xFFFFC107)),
            locale: const Locale('pt'),
            localizationsDelegates: PlayerLocalizations.localizationsDelegates,
            supportedLocales: PlayerLocalizations.supportedLocales,
            home: Scaffold(
              body: PlayerActions(
                library: library,
                playback: playback,
                exportPlaylist: (_, _) async {},
                revealFile: (_) async {},
                pickFolder: (_) async => p.join(dir.path, 'saida'),
                child: Builder(
                  builder: (context) {
                    host = context;
                    actions = PlayerActions.maybeOf(context)!;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        );
        await library.reload();
        await tester.pump();
      }

      testWidgets('mostra a prévia e só move ao confirmar', (tester) async {
        final path = add('a.flac');
        await pumpHost(tester);
        unawaited(showOrganize(host, actions, tracks: db.tracks()));
        await settle(tester);
        expect(find.text('1 arquivo será movido'), findsOneWidget);
        expect(File(path).existsSync(), isTrue);
        await tester.tap(find.widgetWithText(FilledButton, 'Organizar'));
        await settle(tester);
        expect(File(path).existsSync(), isFalse);
        expect(find.text('1 arquivo movido'), findsOneWidget);
        await tester.tap(find.text('Desfazer'));
        await settle(tester);
        expect(File(path).existsSync(), isTrue);
      });

      testWidgets('um padrão inválido não deixa seguir', (tester) async {
        add('a.flac');
        await pumpHost(tester);
        unawaited(showOrganize(host, actions, tracks: db.tracks()));
        await settle(tester);
        await tester.enterText(find.byType(TextField), '{album}');
        await settle(tester);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Organizar'),
              )
              .onPressed,
          isNull,
        );
      });

      testWidgets('o chip põe o campo no padrão', (tester) async {
        add('a.flac');
        await pumpHost(tester);
        unawaited(showOrganize(host, actions, tracks: db.tracks()));
        await settle(tester);
        await tester.enterText(find.byType(TextField), '{title}/');
        await tester.pump();
        await tester.tap(find.widgetWithText(ActionChip, 'Gênero'));
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '{title}/{genre}',
        );
      });

      testWidgets('copiar pede a pasta antes', (tester) async {
        add('a.flac');
        Directory(p.join(dir.path, 'saida')).createSync();
        await pumpHost(tester);
        unawaited(showCopyFiles(host, actions, tracks: db.tracks()));
        await settle(tester);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Copiar'))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Escolher pasta'));
        await settle(tester);
        expect(find.textContaining('será copiado'), findsOneWidget);
        expect(find.textContaining('livres'), findsOneWidget);
      });

      for (final (width, height) in [(420.0, 800.0), (240.0, 160.0)]) {
        testWidgets('cabe em $width × $height', (tester) async {
          add('a.flac');
          await pumpHost(tester, width: width, height: height);
          unawaited(showOrganize(host, actions, tracks: db.tracks()));
          await settle(tester);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });

  test('a fila vai junto', () async {
    final engine = FakeEngine();
    final db = LibraryDb.memory();
    addTearDown(db.close);
    final playback = PlaybackController(engine: engine, store: DirectStore(db));
    await engine.open(['/a.flac', '/b.flac', '/c.flac']);
    await playback.relocate({'/a.flac': '/x/a.flac', '/b.flac': '/x/b.flac'});
    expect(engine.state.value.queue, ['/a.flac', '/x/b.flac', '/c.flac']);
    expect(engine.state.value.index, 0);
  });
}

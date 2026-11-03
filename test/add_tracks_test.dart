import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/pick_folders.dart';

import 'helpers.dart';

Track _track(String path, {int? number, int? disc}) => Track(
  path: path,
  title: path,
  artist: '',
  albumId: 0,
  album: '',
  format: 'FLAC',
  trackNumber: number,
  discNumber: disc,
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  group('as pastas do seletor', () {
    test('sobem até a da biblioteca, somando as de dentro', () {
      final folders = pickFolders(
        [
          _track('/m/Salmos/Vol 1/a.flac'),
          _track('/m/Salmos/Vol 2/b.flac'),
          _track('/m/solta.mp3'),
        ],
        ['/m'],
      );
      expect(folders.map((f) => f.path), [
        '/m',
        '/m/Salmos',
        '/m/Salmos/Vol 1',
        '/m/Salmos/Vol 2',
      ]);
      expect(folders.map((f) => f.depth), [0, 1, 2, 2]);
      expect(folders.map((f) => f.paths.length), [3, 2, 1, 1]);
      expect(folders[0].location, '');
      expect(folders[2].location, 'm/Salmos');
      expect(folders[2].name, 'Vol 1');
    });

    test('a faixa fica na ordem do álbum, não na do nome', () {
      final folder = pickFolders(
        [
          _track('/m/a/x.flac', number: 2),
          _track('/m/a/z.flac', number: 1),
          _track('/m/a/y.flac', number: 1, disc: 2),
        ],
        ['/m/a'],
      ).single;
      expect(folder.paths, ['/m/a/z.flac', '/m/a/x.flac', '/m/a/y.flac']);
    });

    test('a pasta vem antes das de dentro, mesmo com nome parecido', () {
      final folders = pickFolders(
        [_track('/m/a b/1.flac'), _track('/m/a/c/2.flac')],
        ['/m'],
      );
      expect(folders.map((f) => f.path), ['/m', '/m/a', '/m/a/c', '/m/a b']);
    });
  });

  group('criar numa tela só', () {
    late LibraryDb db;

    setUp(() {
      db = LibraryDb.memory();
      addTearDown(db.close);
      seedAlbum(db, folder: '/m', album: 'Maré Alta');
      seedAlbum(db, folder: '/n', album: 'Céu Aberto', tracks: 2);
    });

    Future<void> openNew(WidgetTester tester) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester, db: db);
      await _settle(tester);
      await tester.tap(find.byTooltip('Playlists').first);
      await _settle(tester);
      await tester.tap(find.text('Nova playlist'));
      await _settle(tester);
    }

    Future<void> tabFolders(WidgetTester tester) async {
      await tester.tap(find.text('Pastas').last);
      await _settle(tester);
    }

    List<Playlist> mine() => db.playlists();

    testWidgets('sem nome não cria, e dá para criar vazia', (tester) async {
      await openNew(tester);
      final create = find.widgetWithText(FilledButton, 'Criar');
      expect(tester.widget<FilledButton>(create).onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'Vazia');
      await tester.pump();
      await tester.tap(create);
      await _settle(tester);
      expect(mine().single.name, 'Vazia');
      expect(db.playlistTracks(mine().single.id), isEmpty);
    });

    testWidgets('Enter no nome também cria', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).first, 'Rápida');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester);
      expect(mine().single.name, 'Rápida');
    });

    testWidgets('marcar a pasta sugere o nome e cria com as faixas', (
      tester,
    ) async {
      await openNew(tester);
      await tabFolders(tester);
      await tester.tap(find.text('Maré Alta'));
      await tester.pump();
      expect(find.text('Criar com 3 músicas'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Maré Alta',
      );
      await tester.tap(find.text('Criar com 3 músicas'));
      await _settle(tester);
      expect(mine().single.name, 'Maré Alta');
      expect(db.playlistTracks(mine().single.id).map((t) => t.title), [
        'Maré Alta 1',
        'Maré Alta 2',
        'Maré Alta 3',
      ]);
      expect(find.text('3 músicas adicionadas'), findsOneWidget);
    });

    testWidgets('o nome digitado não é trocado pela pasta', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).first, 'Minha');
      await tabFolders(tester);
      await tester.tap(find.text('Maré Alta'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Minha',
      );
    });

    testWidgets('desmarcar tudo tira o nome sugerido', (tester) async {
      await openNew(tester);
      await tabFolders(tester);
      await tester.tap(find.text('Maré Alta'));
      await tester.pump();
      await tester.tap(find.text('Limpar seleção'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      expect(find.text('Limpar seleção'), findsNothing);
    });

    testWidgets('marcar todas pega só o que a busca achou', (tester) async {
      await openNew(tester);
      expect(find.text('Marcar todas (5)'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'céu');
      await _settle(tester);
      await tester.tap(find.text('Marcar todas (2)'));
      await tester.pump();
      expect(find.text('Criar com 2 músicas'), findsOneWidget);
      await tester.tap(find.text('Marcar todas (2)'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Criar'), findsOneWidget);
    });

    testWidgets('a busca também filtra as pastas, e diz de onde vêm', (
      tester,
    ) async {
      await openNew(tester);
      await tabFolders(tester);
      await tester.enterText(find.byType(TextField).last, 'ceu');
      await tester.pump();
      expect(find.text('Céu Aberto'), findsOneWidget);
      expect(find.text('Maré Alta'), findsNothing);
      expect(find.text('n · 2 músicas'), findsOneWidget);
    });

    testWidgets('abre com o tema do player', (tester) async {
      await openNew(tester);
      final dialog = tester.element(find.byType(Dialog));
      final page = tester.element(find.text('Nova playlist').first);
      expect(
        Theme.of(dialog).colorScheme.primaryContainer,
        Theme.of(page).colorScheme.primaryContainer,
      );
    });

    testWidgets('todo controle tem nome para o leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await openNew(tester);
      for (final tab in ['Músicas', 'Pastas']) {
        expect(find.bySemanticsLabel(RegExp(tab)), findsWidgets);
      }
      expect(find.bySemanticsLabel(RegExp('Maré Alta 1')), findsOneWidget);
      semantics.dispose();
    });
  });

  group('adicionar a uma playlist', () {
    testWidgets('a pasta deixa de fora o que já está nela', (tester) async {
      final db = LibraryDb.memory();
      addTearDown(db.close);
      seedAlbum(db, folder: '/m', album: 'Maré Alta');
      final id = db.createPlaylist('Lista', 1, ['/m/Maré Alta/1.flac']);
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester, db: db);
      await _settle(tester);
      await tester.tap(find.byTooltip('Playlists').first);
      await _settle(tester);
      await tester.tap(find.text('Lista').first);
      await _settle(tester);
      await tester.tap(find.text('Adicionar músicas'));
      await _settle(tester);
      await tester.tap(find.text('Pastas').last);
      await _settle(tester);
      await tester.tap(find.text('Maré Alta'));
      await tester.pump();
      await tester.tap(find.text('Adicionar 2'));
      await _settle(tester);
      expect(db.playlistTracks(id).map((t) => t.title), [
        'Maré Alta 1',
        'Maré Alta 2',
        'Maré Alta 3',
      ]);
    });
  });

  for (final locale in PlayerLocalizations.supportedLocales) {
    final code = locale.languageCode;
    for (final (width, height) in const [
      (1280.0, 800.0),
      (420.0, 760.0),
      (240.0, 160.0),
    ]) {
      testWidgets('$code fits the new playlist at ${width}x$height', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = [locale];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final db = LibraryDb.memory();
        addTearDown(db.close);
        seedAlbum(db);
        setWindow(tester, 1280, 800);
        await pumpPlayer(tester, db: db);
        await _settle(tester);
        final l10n = lookupPlayerLocalizations(locale);
        await tester.tap(find.byTooltip(l10n.playlists).first);
        await _settle(tester);
        await tester.tap(find.text(l10n.newPlaylist));
        await _settle(tester);
        setWindow(tester, width, height);
        await _settle(tester);
        // Na janela mínima, o diálogo inteiro rola
        await tester.ensureVisible(find.text(l10n.folders).last);
        await tester.pump();
        await tester.tap(find.text(l10n.folders).last);
        await _settle(tester);
        await tester.ensureVisible(find.text('Maré Alta'));
        await tester.pump();
        await tester.tap(find.text('Maré Alta'));
        await _settle(tester);
        expect(find.text(l10n.clearSelection), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

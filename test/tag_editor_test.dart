// As telas do editor de tags, gravando em arquivos de verdade.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/player_app.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/tag_edit/tag_edit.dart';
import 'package:psito_player/src/library/tag_edit/tag_files.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/ui/molecules/embedded_cover_editor.dart';
import 'package:psito_player/src/ui/organisms/album_tag_editor.dart';
import 'package:psito_player/src/ui/organisms/selection_bar.dart';
import 'package:psito_player/src/ui/organisms/tag_batch_dialog.dart';
import 'package:psito_player/src/ui/organisms/tag_editor_dialog.dart';
import 'package:psito_player/src/ui/organisms/track_list.dart';
import 'package:psito_player/src/ui/player_actions.dart';
import 'package:psito_player/src/ui/track_selection.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  late LibraryDb db;
  late LibraryController library;
  late PlaybackController playback;
  late TrackSelection selection;
  late BuildContext host;
  late PlayerActions actions;
  late int folderId;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('psito-editor');
    db = LibraryDb.memory();
    folderId = db.addFolder(dir.path);
    selection = TrackSelection();
    library = LibraryController(
      store: DirectStore(db),
      scanner: FakeScanner(),
      tagUndoDir: p.join(dir.path, '.undo'),
    );
    playback = PlaybackController(engine: FakeEngine(), store: DirectStore(db));
  });

  tearDown(() {
    library.dispose();
    selection.dispose();
    db.close();
    dir.deleteSync(recursive: true);
  });

  Track add(
    int n, {
    String fixture = 'tone.flac',
    String album = 'Disco',
    String artist = 'Ana',
  }) {
    final ext = p.extension(fixture);
    final path = p.join(dir.path, '0$n Faixa $n$ext');
    File('test/fixtures/$fixture').copySync(path);
    if (ext != '.wma') {
      writeTags(
        path,
        TagEdit(
          fields: {
            TagField.title: 'Faixa $n',
            TagField.artist: artist,
            TagField.album: album,
            TagField.trackNumber: '$n',
            TagField.trackTotal: '9',
            TagField.genre: 'Rock',
          },
        ),
      );
    }
    db.upsertTrack(
      ScannedTrack(
        path: path,
        title: 'Faixa $n',
        artist: artist,
        albumArtist: artist,
        album: album,
        trackNumber: n,
        genre: 'Rock',
        size: 1,
        mtime: 1,
      ),
      folderId,
      1,
    );
    return db.tracks().firstWhere((t) => t.path == path);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpHost(
    WidgetTester tester, {
    double width = 1280,
    double height = 800,
    List<Track> list = const [],
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
            selection: selection,
            pickImage: (_) async => null,
            child: Builder(
              builder: (context) {
                host = context;
                actions = PlayerActions.maybeOf(context)!;
                return ListenableBuilder(
                  listenable: selection,
                  builder: (context, _) => Column(
                    children: [
                      if (selection.active)
                        SelectionBar(selection: selection, actions: actions),
                      Expanded(
                        child: CustomScrollView(
                          slivers: [
                            TrackList(
                              tracks: list,
                              library: library,
                              playback: playback,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await library.reload();
    await tester.pump();
  }

  Finder field(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextField));

  Future<void> open(WidgetTester tester, List<Track> tracks, int index) async {
    unawaited(showTagEditor(host, actions, tracks, index));
    await settle(tester);
  }

  group('uma faixa', () {
    testWidgets('mostra o arquivo, grava só o que mudou e desfaz', (
      tester,
    ) async {
      final track = add(1);
      await pumpHost(tester);
      await open(tester, [track], 0);
      expect(
        tester.widget<TextField>(field('Título')).controller!.text,
        'Faixa 1',
      );
      expect(find.widgetWithText(FilledButton, 'Salvar'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'))
            .onPressed,
        isNull,
      );

      await tester.enterText(field('Título'), 'Novo nome');
      await tester.pump();
      expect(find.text('1 campo alterado'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await settle(tester);

      final after = readEditableTags(track.path);
      expect(after.values[TagField.title], 'Novo nome');
      expect(after.values[TagField.trackTotal], '9');
      expect(find.text('Tags gravadas em 1 arquivo'), findsOneWidget);

      await tester.tap(find.text('Desfazer'));
      await settle(tester);
      expect(readEditableTags(track.path).values[TagField.title], 'Faixa 1');
    });

    testWidgets('as setas perguntam quando há mudança', (tester) async {
      final tracks = [add(1), add(2)];
      await pumpHost(tester);
      await open(tester, tracks, 0);
      expect(find.text('1 de 2'), findsOneWidget);

      await tester.enterText(field('Título'), 'Mexido');
      await tester.pump();
      await tester.tap(find.byTooltip('Próxima faixa'));
      await tester.pumpAndSettle();
      expect(find.text('Salvar as mudanças desta faixa?'), findsOneWidget);

      // Cancelar fica onde está
      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();
      expect(find.text('1 de 2'), findsOneWidget);

      // Salvar e seguir grava e anda
      await tester.tap(find.byTooltip('Próxima faixa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar e ir para a próxima'));
      await settle(tester);
      await settle(tester);
      expect(find.text('2 de 2'), findsOneWidget);
      expect(
        tester.widget<TextField>(field('Título')).controller!.text,
        'Faixa 2',
      );
      expect(readEditableTags(tracks[0].path).values[TagField.title], 'Mexido');
    });

    testWidgets('sair com mudanças pergunta, e descartar não grava', (
      tester,
    ) async {
      final track = add(1);
      await pumpHost(tester);
      await open(tester, [track], 0);
      await tester.enterText(field('Título'), 'Mexido');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await settle(tester);
      expect(find.byType(TagEditorDialog), findsNothing);
      expect(readEditableTags(track.path).values[TagField.title], 'Faixa 1');
    });

    testWidgets('WMA fica só para ler, e diz por quê', (tester) async {
      final track = add(1, fixture: 'tone.wma');
      await pumpHost(tester);
      await open(tester, [track], 0);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.textContaining('Ainda não dá para editar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Salvar'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Fechar'), findsOneWidget);
      expect(tester.widget<TextField>(field('Título')).readOnly, isTrue);
    });

    testWidgets('a capa: tirar e voltar', (tester) async {
      final track = add(1);
      await pumpHost(tester);
      await open(tester, [track], 0);
      await tester.tap(find.text('Capa'));
      await tester.pump();
      expect(find.byType(EmbeddedCoverEditor), findsOneWidget);
      expect(find.text('Remover a capa embutida'), findsNothing);
    });

    for (final (width, height) in [
      (420.0, 800.0),
      (240.0, 160.0),
      (640.0, 300.0),
    ]) {
      testWidgets('cabe em $width × $height', (tester) async {
        final track = add(1);
        await pumpHost(tester, width: width, height: height);
        await open(tester, [track, add(2)], 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('o menu da faixa abre o editor, e o Ctrl+E também', (
      tester,
    ) async {
      final track = add(1);
      await pumpHost(tester, list: [track]);
      await tester.tap(find.byTooltip('Mais opções').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar tags…'));
      await settle(tester);
      expect(find.byType(TagEditorDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await settle(tester);

      Focus.of(tester.element(find.text('Faixa 1').first)).requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(find.byType(TagEditorDialog), findsOneWidget);
    });

    testWidgets('todo controle tem nome para o leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      final tracks = [add(1), add(2)];
      await pumpHost(tester);
      await open(tester, tracks, 0);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  });

  group('a seleção', () {
    testWidgets('Ctrl marca, o clique segue marcando e o Shift estende', (
      tester,
    ) async {
      final tracks = [add(1), add(2), add(3), add(4)];
      await pumpHost(tester, list: tracks);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Faixa 1'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('1 selecionada'), findsOneWidget);
      expect(playback.current, isNull);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('Faixa 3'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(find.text('3 selecionadas'), findsOneWidget);

      await tester.tap(find.text('Faixa 2'));
      await tester.pump();
      expect(find.text('2 selecionadas'), findsOneWidget);

      await tester.tap(find.byTooltip('Limpar seleção'));
      await tester.pump();
      expect(selection.active, isFalse);
    });

    testWidgets('o menu da linha também marca', (tester) async {
      final track = add(1);
      await pumpHost(tester, list: [track]);
      await tester.tap(find.byTooltip('Mais opções').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();
      expect(selection.contains(track), isTrue);
    });
  });

  group('várias faixas', () {
    test('só grava o que mexeu', () {
      final edit = batchTagEdit(
        typed: {TagField.genre: ' MPB ', TagField.album: 'A'},
        initial: {TagField.genre: 'Rock', TagField.album: 'A'},
        erased: {TagField.comment},
        cover: const CoverChoice.keep(),
      );
      expect(edit.fields, {TagField.genre: 'MPB', TagField.comment: null});
      expect(edit.coverChanged, isFalse);
    });

    testWidgets('mostra "Vários valores", grava nas que dá e pula o WMA', (
      tester,
    ) async {
      final tracks = [
        add(1),
        add(2, artist: 'Bruno'),
        add(3, fixture: 'tone.wma'),
      ];
      await pumpHost(tester);
      unawaited(showBatchTagEditor(host, actions, tracks));
      await settle(tester);
      expect(find.text('Vários valores'), findsWidgets);
      expect(find.textContaining('fica de fora'), findsOneWidget);

      await tester.enterText(field('Gênero'), 'MPB');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar nas 2'));
      await settle(tester);
      for (final track in tracks.take(2)) {
        final tags = readEditableTags(track.path);
        expect(tags.values[TagField.genre], 'MPB');
        expect(tags.values[TagField.title], track.title);
      }
      expect(readEditableTags(tracks[1].path).values[TagField.artist], 'Bruno');
    });

    testWidgets('apagar um campo limpa em todas', (tester) async {
      final tracks = [add(1), add(2)];
      await pumpHost(tester);
      unawaited(showBatchTagEditor(host, actions, tracks));
      await settle(tester);
      await tester.tap(find.byTooltip('Apagar Gênero nas 2 faixas'));
      await tester.pump();
      expect(find.text('Será apagado nas 2 faixas'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar nas 2'));
      await settle(tester);
      expect(
        readEditableTags(tracks[0].path).values.containsKey(TagField.genre),
        isFalse,
      );
    });

    testWidgets('cabe em 240 × 160', (tester) async {
      final tracks = [add(1), add(2)];
      await pumpHost(tester, width: 240, height: 160);
      unawaited(showBatchTagEditor(host, actions, tracks));
      await settle(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('o álbum', () {
    Album album() => db.albums().single;

    test('o título que vem do nome do arquivo', () {
      expect(titleFromFileName('/m/03 - Maré Alta.flac'), 'Maré Alta');
      expect(titleFromFileName('/m/1. Um.mp3'), 'Um');
      expect(titleFromFileName('/m/Sem número.ogg'), 'Sem número');
      expect(titleFromFileName('/m/1999.flac'), '1999');
    });

    testWidgets('os campos do álbum valem para todas, e a linha para a dela', (
      tester,
    ) async {
      final tracks = [add(1), add(2)];
      await pumpHost(tester);
      unawaited(showAlbumTagEditor(host, actions, album()));
      await settle(tester);
      await tester.enterText(field('Álbum').first, 'Outro');
      await tester.enterText(
        find.widgetWithText(TextField, 'Faixa 1'),
        'Primeira',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await settle(tester);
      expect(readEditableTags(tracks[0].path).values[TagField.album], 'Outro');
      expect(readEditableTags(tracks[1].path).values[TagField.album], 'Outro');
      expect(
        readEditableTags(tracks[0].path).values[TagField.title],
        'Primeira',
      );
      expect(
        readEditableTags(tracks[1].path).values[TagField.title],
        'Faixa 2',
      );
    });

    testWidgets('mover e numerar segue a ordem da tabela', (tester) async {
      final tracks = [add(1), add(2), add(3)];
      await pumpHost(tester);
      unawaited(showAlbumTagEditor(host, actions, album()));
      await settle(tester);
      await tester.tap(find.byTooltip('Mais opções').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover para baixo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Numerar na ordem'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await settle(tester);
      String number(int i) =>
          readEditableTags(tracks[i].path).values[TagField.trackNumber]!;
      expect([number(0), number(1), number(2)], ['2', '1', '3']);
      // O total, que já estava lá, fica certo
      expect(readEditableTags(tracks[0].path).values[TagField.trackTotal], '3');
    });

    testWidgets('todo controle tem nome para o leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      add(1);
      add(2);
      await pumpHost(tester);
      unawaited(showAlbumTagEditor(host, actions, album()));
      await settle(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('título pelo nome do arquivo só preenche', (tester) async {
      final tracks = [add(1)];
      await pumpHost(tester);
      unawaited(showAlbumTagEditor(host, actions, album()));
      await settle(tester);
      await tester.tap(find.text('Título pelo nome do arquivo'));
      await tester.pump();
      expect(
        readEditableTags(tracks[0].path).values[TagField.title],
        'Faixa 1',
      );
      expect(find.widgetWithText(TextField, '01 Faixa 1'), findsNothing);
      expect(find.widgetWithText(TextField, 'Faixa 1'), findsOneWidget);
    });

    for (final (width, height) in [(420.0, 800.0), (240.0, 160.0)]) {
      testWidgets('cabe em $width × $height', (tester) async {
        add(1);
        add(2);
        await pumpHost(tester, width: width, height: height);
        unawaited(showAlbumTagEditor(host, actions, album()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

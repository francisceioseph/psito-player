// O menu do botão direito, o tocar nos cartões e o caminho até uma playlist.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/player/engine.dart';
import 'package:psito_player/src/ui/molecules/playlist_card.dart';

import 'helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late LibraryDb db;
  late FakeEngine engine;

  setUp(() {
    db = LibraryDb.memory();
    engine = FakeEngine();
    seedAlbum(db);
    seedAlbum(db, album: 'Serra Azul', artist: 'Ana Rio', tracks: 2);
  });

  Future<void> open(WidgetTester tester, String destination) async {
    setWindow(tester, 1280, 800);
    await pumpPlayer(tester, engine: engine, db: db);
    await tester.tap(find.byTooltip(destination).first);
    await _settle(tester);
  }

  Future<void> rightClick(WidgetTester tester, Finder target) async {
    await tester.tap(target, buttons: kSecondaryButton);
    await _settle(tester);
  }

  testWidgets('o botão direito num álbum toca e põe na fila', (tester) async {
    await open(tester, 'Biblioteca');
    await rightClick(tester, find.text('Maré Alta').first);
    expect(find.text('Adicionar à playlist'), findsOneWidget);
    await tester.tap(find.text('Tocar'));
    await _settle(tester);
    expect(engine.opened.single, hasLength(3));

    await rightClick(tester, find.text('Serra Azul').first);
    await tester.tap(find.text('Adicionar à fila'));
    await _settle(tester);
    expect(engine.state.value.queue, hasLength(5));
  });

  testWidgets('o botão direito numa música abre o menu dela', (tester) async {
    await open(tester, 'Biblioteca');
    await tester.tap(find.text('Maré Alta').first);
    await _settle(tester);
    await rightClick(tester, find.text('Maré Alta 2'));
    expect(find.text('Tocar a seguir'), findsOneWidget);
    expect(find.text('Adicionar à playlist'), findsOneWidget);
  });

  testWidgets('a tecla Menu abre o mesmo menu', (tester) async {
    await open(tester, 'Biblioteca');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    for (var i = 0; i < 40; i++) {
      final found = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<InkWell>();
      final card = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<Semantics>()
          ?.properties
          .label;
      if (found != null && card != null && card.contains('Maré Alta')) break;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await _settle(tester);
    expect(find.text('Adicionar à playlist'), findsOneWidget);
  });

  group('playlist', () {
    setUp(() {
      db.createPlaylist('Para correr', 1, [
        for (final t in db.albumTracks(db.albums().first.id)) t.path,
      ]);
    });

    testWidgets('o cartão mostra tocar com o ponteiro, e toca', (tester) async {
      await open(tester, 'Playlists');
      expect(find.byTooltip('Tocar Para correr'), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getCenter(find.widgetWithText(PlaylistCard, 'Para correr')),
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await _settle(tester);
      expect(engine.opened, isNotEmpty);
    });

    testWidgets('o botão direito renomeia e apaga', (tester) async {
      await open(tester, 'Playlists');
      await rightClick(tester, find.text('Para correr'));
      await tester.tap(find.text('Renomear'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Domingo');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await _settle(tester);
      expect(db.playlists().single.name, 'Domingo');

      await rightClick(tester, find.text('Domingo'));
      await tester.tap(find.text('Excluir playlist'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await _settle(tester);
      expect(db.playlists(), isEmpty);
    });

    testWidgets('Adicionar músicas busca, marca e adiciona', (tester) async {
      await open(tester, 'Playlists');
      await tester.tap(find.text('Para correr'));
      await _settle(tester);
      await tester.tap(find.text('Adicionar músicas'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'serra');
      await _settle(tester);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      await tester.tap(find.text('Serra Azul 1'));
      await tester.pump();
      await tester.tap(find.text('Adicionar 1'));
      await _settle(tester);
      expect(
        db.playlistTracks(db.playlists().single.id).map((t) => t.title),
        contains('Serra Azul 1'),
      );
      expect(find.text('1 música adicionada'), findsOneWidget);
    });

    testWidgets('o botão do álbum leva tudo a uma playlist, e avisa', (
      tester,
    ) async {
      await open(tester, 'Biblioteca');
      await tester.tap(find.text('Serra Azul').first);
      await _settle(tester);
      await tester.tap(find.byTooltip('Adicionar à playlist'));
      await _settle(tester);
      await tester.tap(find.text('Para correr'));
      await _settle(tester);
      expect(db.playlists().single.trackCount, 5);
      expect(find.text('Adicionado a “Para correr”'), findsOneWidget);
    });
  });

  group('som', () {
    testWidgets('os ajustes chegam ao motor, ao abrir e ao mudar', (
      tester,
    ) async {
      db.setSetting('settings', '{"gapless":false,"replayGain":"album"}');
      await open(tester, 'Ajustes');
      expect(engine.gapless, isFalse);
      expect(engine.replayGain, PlayerReplayGain.album);
      await tester.tap(find.text('Tocar sem pausa entre as faixas'));
      await tester.pump();
      await tester.tap(find.text('Faixa'));
      await _settle(tester);
      expect(engine.gapless, isTrue);
      expect(engine.replayGain, PlayerReplayGain.track);
    });
  });
}

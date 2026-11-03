// A auditoria de acessibilidade: dá para usar sem o mouse, o foco nunca some, e
// o texto e os alvos passam nas regras, nos dois temas.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/ui/molecules/album_card.dart';
import 'package:psito_player/src/ui/molecules/track_row.dart';
import 'package:psito_player/src/ui/organisms/navigation.dart';

import 'helpers.dart';

FocusNode? get _focus => FocusManager.instance.primaryFocus;

String? _focusedTooltip() =>
    _focus?.context?.findAncestorWidgetOfExactType<Tooltip>()?.message;

Future<void> _tab(WidgetTester tester, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Anda com o Tab até [found], e falha se der a volta sem achar.
Future<void> _tabTo(WidgetTester tester, bool Function() found) async {
  for (var i = 0; i < 200 && !found(); i++) {
    await _tab(tester);
  }
  expect(found(), isTrue);
}

void main() {
  late LibraryDb db;
  late FakeEngine engine;

  setUp(() {
    db = LibraryDb.memory();
    engine = FakeEngine();
    seedAlbum(db);
  });

  // O banco fica aberto: a sessão ainda grava depois que a tela sai
  Future<void> open(WidgetTester tester) async {
    setWindow(tester, 1280, 800);
    await pumpPlayer(tester, engine: engine, db: db);
    await tester.pump();
  }

  Future<void> playThree(WidgetTester tester) async {
    await engine.open(['/m/a.flac', '/m/b.flac', '/m/c.flac']);
    await tester.pump();
  }

  group('teclado', () {
    testWidgets('o Tab chega a todos os destinos, e o Enter abre', (
      tester,
    ) async {
      await open(tester);
      for (final (name, destination) in [
        ('Biblioteca', PlayerDestination.library),
        ('Playlists', PlayerDestination.playlists),
        ('Pastas', PlayerDestination.folders),
        ('Buscar', PlayerDestination.search),
      ]) {
        await _tabTo(tester, () => _focusedTooltip() == name);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await tester.pump();
        expect(
          tester.widget<PlayerRail>(find.byType(PlayerRail)).selected,
          destination,
        );
        // A busca pega o foco no campo, e o Tab segue a partir dele
      }
    });

    testWidgets('do cartão do álbum, o Tab passa ao botão de tocar sem perder '
        'o foco', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Biblioteca').first);
      await tester.pump();
      await _tabTo(
        tester,
        () =>
            _focus?.context?.findAncestorWidgetOfExactType<AlbumCard>() != null,
      );
      await tester.pump();
      await _tab(tester);
      expect(_focusedTooltip(), contains('Tocar'));
      expect(_focus?.context?.mounted, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(engine.opened, isNotEmpty);
    });

    testWidgets('os atalhos continuam depois que o que tinha o foco sai da '
        'tela', (tester) async {
      await open(tester);
      await playThree(tester);
      await tester.tap(find.byTooltip('Biblioteca').first);
      await tester.pump();
      await _tabTo(
        tester,
        () =>
            _focus?.context?.findAncestorWidgetOfExactType<AlbumCard>() != null,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      final before = engine.state.value.playing;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(engine.state.value.volume, 0);
      expect(engine.state.value.playing, before);
    });

    testWidgets('dá para reordenar a fila sem arrastar', (tester) async {
      await open(tester);
      await playThree(tester);
      await tester.tap(find.byTooltip('Fila').first);
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byType(TrackRow).last, buttons: kSecondaryButton);
      await _settle(tester);
      await tester.tap(find.text('Mover para cima'));
      await _settle(tester);
      expect(engine.state.value.queue, ['/m/a.flac', '/m/c.flac', '/m/b.flac']);
    });

    testWidgets('o foco fica visível num botão e numa linha', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Biblioteca').first);
      await tester.pump();
      final theme = Theme.of(tester.element(find.byType(AlbumCard).first));
      expect(theme.focusColor.a, greaterThanOrEqualTo(0.3));
      final side = theme.iconButtonTheme.style?.side?.resolve({
        WidgetState.focused,
      });
      expect(side?.width, greaterThanOrEqualTo(2));
      expect(side?.color, theme.colorScheme.primary);
      expect(
        theme.iconButtonTheme.style?.side?.resolve({}),
        anyOf(isNull, BorderSide.none),
      );
    });
  });

  group('regras', () {
    for (final (name, mode) in [('escuro', 'dark'), ('claro', 'light')]) {
      for (final page in [
        'Início',
        'Biblioteca',
        'Playlists',
        'Pastas',
        'Buscar',
      ]) {
        testWidgets('$page, no tema $name', (tester) async {
          final handle = tester.ensureSemantics();
          db.setSetting('settings', '{"themeMode":"$mode"}');
          await open(tester);
          await playThree(tester);
          await tester.tap(find.byTooltip(page).first);
          await _settle(tester);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });
      }

      testWidgets('Ajustes, no tema $name', (tester) async {
        final handle = tester.ensureSemantics();
        db.setSetting('settings', '{"themeMode":"$mode"}');
        await open(tester);
        await tester.tap(find.byTooltip('Ajustes').first);
        await _settle(tester);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}

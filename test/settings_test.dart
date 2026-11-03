import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/lyrics/lyrics_loader.dart';
import 'package:psito_player/src/player/player_shortcuts.dart';
import 'package:psito_player/src/settings/player_settings.dart';
import 'package:psito_player/src/ui/atoms/app_icon.dart';
import 'package:psito_player/src/ui/molecules/settings_rows.dart';
import 'package:psito_player/src/ui/molecules/track_row.dart';
import 'package:psito_player/src/ui/pages/settings_page.dart';
import 'package:psito_player/src/third_party.dart';
import 'package:psito_player/src/version.dart';

import 'helpers.dart';

Future<void> openSettings(WidgetTester tester, [String? category]) async {
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
  if (category != null) {
    await tester.tap(
      find.descendant(
        of: find.byType(SettingsPage),
        matching: find.text(category),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  test('a versão é a do pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(r'^version: ([\d.]+)', multiLine: true).firstMatch(pubspec)![1],
      playerVersion,
    );
  });

  test('todo pacote do pubspec está nas licenças', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final section = pubspec.substring(
      pubspec.indexOf('\ndependencies:'),
      pubspec.indexOf('\ndev_dependencies:'),
    );
    final packages = RegExp(
      r'^  (\w+):',
      multiLine: true,
    ).allMatches(section).map((m) => m[1]!);
    final listed = dartPackages.map((item) => item.$1).toSet();
    for (final name in packages) {
      if (name.startsWith('flutter')) continue;
      expect(listed, contains(name));
    }
  });

  test('o ícone desenhado é o do icon.svg', () {
    final svg = File('icon.svg').readAsStringSync();
    final paths = RegExp(r' d="([^"]*)"')
        .allMatches(svg)
        .map((m) => m[1]!.split(RegExp(r'\s+')).join(' '));
    expect(paths, [appIconShadowPath, appIconBodyPath]);
    expect(svg, contains('fill="#80280C"'));
    final bounds = parseIconPath(appIconBodyPath).getBounds();
    expect(bounds.left, greaterThan(0));
    expect(bounds.right, lessThan(20480));
    expect(bounds.top, greaterThan(0));
    expect(bounds.bottom, lessThan(20480));
  });

  group('Sobre', () {
    Future<List<String>> openAbout(WidgetTester tester) async {
      setWindow(tester, 1280, 800);
      final opened = <String>[];
      await pumpPlayer(tester, openFolder: (path) async => opened.add(path));
      await openSettings(tester, 'Sobre');
      return opened;
    }

    Future<void> tapRow(WidgetTester tester, String text) async {
      await tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SettingsPage),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
      await tester.pump();
    }

    testWidgets('o botão do bug abre as issues', (tester) async {
      final opened = await openAbout(tester);
      expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);
      await tester.tap(find.text('Relatar um problema no GitHub'));
      await tester.pump();
      expect(opened, [issuesUrl]);
    });

    testWidgets('mostra o ícone do player', (tester) async {
      await openAbout(tester);
      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('as inspirações abrem no Figma', (tester) async {
      final opened = await openAbout(tester);
      await tapRow(tester, 'Spotify Redesign');
      await tapRow(tester, 'Apple Music Redesign');
      expect(opened, [spotifyDesignUrl, appleMusicDesignUrl]);
    });

    testWidgets('avisa do Claude Code e lista as licenças', (tester) async {
      await openAbout(tester);
      expect(
        find.text('Desenvolvido com o auxílio do Claude Code.'),
        findsOneWidget,
      );
      for (final (name, license) in [
        ...dartPackages,
        ...systemLibraries,
        ...interfaceAssets,
      ]) {
        final row = find.ancestor(
          of: find.text(name, skipOffstage: false),
          matching: find.byType(SettingsTableRow, skipOffstage: false),
        );
        await tester.scrollUntilVisible(
          find.text(name),
          200,
          scrollable: find
              .descendant(
                of: find.byType(SettingsPage),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        expect(
          find.descendant(of: row, matching: find.text(license)),
          findsOneWidget,
        );
      }
    });
  });

  group('guardar', () {
    test('volta como estava, atalhos inclusive', () async {
      final store = DirectStore(LibraryDb.memory());
      final saved = PlayerSettings();
      await saved.load(store);
      saved
        ..themeMode = ThemeMode.light
        ..accent = AccentChoice.teal
        ..compact = true
        ..textScale = 1.15
        ..reduceMotion = true
        ..rememberSession = false
        ..playWholeList = false
        ..lyricsFiles = false
        ..lyricsEmbedded = false
        ..refreshOnOpen = false
        ..setShortcut(
          PlayerCommand.mute,
          const KeyCombo(LogicalKeyboardKey.keyU, control: true, shift: true),
        );
      await Future<void>.delayed(Duration.zero);

      final again = PlayerSettings();
      await again.load(store);
      expect(again.themeMode, ThemeMode.light);
      expect(again.accent, AccentChoice.teal);
      expect(again.compact, isTrue);
      expect(again.textScale, 1.15);
      expect(again.reduceMotion, isTrue);
      expect(again.rememberSession, isFalse);
      expect(again.playWholeList, isFalse);
      expect(again.lyricsFiles, isFalse);
      expect(again.lyricsEmbedded, isFalse);
      expect(again.refreshOnOpen, isFalse);
      expect(
        again.shortcuts[PlayerCommand.mute],
        const KeyCombo(LogicalKeyboardKey.keyU, control: true, shift: true),
      );
      expect(
        again.shortcuts[PlayerCommand.queue],
        defaultShortcuts[PlayerCommand.queue],
      );
    });

    test('o que não dá para ler fica no padrão', () async {
      final store = DirectStore(LibraryDb.memory());
      for (final broken in [
        'não é json',
        '[]',
        '{"themeMode":"neon","accent":3,"compact":"sim","textScale":9,'
            '"shortcuts":{"mute":{"key":"M"}}}',
      ]) {
        await store.setSetting('settings', broken);
        final settings = PlayerSettings();
        await settings.load(store);
        expect(settings.themeMode, ThemeMode.dark, reason: broken);
        expect(settings.accent, isNull, reason: broken);
        expect(settings.compact, isFalse, reason: broken);
        expect(settings.textScale, lessThanOrEqualTo(1.3), reason: broken);
        expect(
          settings.shortcuts[PlayerCommand.mute],
          defaultShortcuts[PlayerCommand.mute],
          reason: broken,
        );
      }
    });
  });

  group('na tela', () {
    testWidgets('mudar o tema, a cor e a densidade vale na hora', (
      tester,
    ) async {
      setWindow(tester, 1280, 800);
      final db = LibraryDb.memory();
      seedAlbum(db);
      await pumpPlayer(tester, db: db);
      await openSettings(tester, 'Aparência');
      Brightness brightness() =>
          Theme.of(tester.element(find.text('Tema'))).brightness;
      expect(brightness(), Brightness.dark);
      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(brightness(), Brightness.light);

      Color primary() =>
          Theme.of(tester.element(find.text('Tema'))).colorScheme.primary;
      final before = primary();
      await tester.tap(find.byTooltip('Roxo'));
      await tester.pumpAndSettle();
      expect(primary(), isNot(before));

      await tester.tap(find.text('Compacta'));
      await tester.pumpAndSettle();
      expect(
        TrackRow.extentOf(tester.element(find.text('Tema'))),
        TrackRow.compactHeight,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'cada categoria cabe, da janela estreita à grande, com o texto maior',
      (tester) async {
        for (final (w, h) in [
          (1280.0, 800.0),
          (700.0, 500.0),
          (240.0, 320.0),
        ]) {
          for (final scale in [1.0, 1.3]) {
            setWindow(tester, w, h);
            final db = LibraryDb.memory();
            seedAlbum(db);
            await DirectStore(db)
                .setSetting('settings', '{"textScale":$scale,"compact":true}');
            await pumpPlayer(tester, db: db);
            // Na janela estreita, a navegação rola
            await tester.ensureVisible(find.byTooltip('Ajustes'));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Ajustes'));
            await tester.pumpAndSettle();
            for (final category in [
              'Biblioteca',
              'Letras',
              'Aparência',
              'Atalhos de teclado',
              'Sobre',
              'Reprodução',
            ]) {
              final target = find.descendant(
                of: find.byType(SettingsPage),
                matching: find.text(category),
              );
              await tester.ensureVisible(target.first);
              await tester.pumpAndSettle();
              await tester.tap(target.first);
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$category em $w×$h a $scale',
              );
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets('as outras telas aguentam o texto maior', (tester) async {
      setWindow(tester, 1280, 800);
      final db = LibraryDb.memory();
      seedAlbum(db);
      await DirectStore(db)
          .setSetting('settings', '{"textScale":1.3,"compact":true}');
      final engine = FakeEngine();
      await pumpPlayer(tester, db: db, engine: engine);
      await engine.open(['/m/a.flac', '/m/b.flac']);
      await tester.pumpAndSettle();
      for (final destination in [
        'Início',
        'Biblioteca',
        'Playlists',
        'Pastas',
      ]) {
        await tester.tap(find.byTooltip(destination).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: destination);
      }
    });

    testWidgets('um atalho novo vale, e um repetido é recusado', (
      tester,
    ) async {
      setWindow(tester, 1280, 800);
      final engine = FakeEngine();
      await pumpPlayer(tester, engine: engine);
      await openSettings(tester, 'Atalhos de teclado');

      await tester.tap(find.byTooltip('Mudar o atalho: Silenciar'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pumpAndSettle();
      expect(
        find.text('Já é usado por: Abrir e fechar a letra'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await engine.setVolume(0.5);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(engine.state.value.volume, 0.5, reason: 'a tecla velha');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pump();
      expect(engine.state.value.volume, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.pump();
      expect(engine.state.value.volume, 0.5);

      await tester.tap(find.text('Restaurar padrões'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      expect(engine.state.value.volume, 0);
    });

    testWidgets('Esc cancela a troca do atalho', (tester) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester);
      await openSettings(tester, 'Atalhos de teclado');
      await tester.tap(find.byTooltip('Mudar o atalho: Silenciar'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('Ctrl + setas trocam de faixa', (tester) async {
      setWindow(tester, 1280, 800);
      final engine = FakeEngine();
      await pumpPlayer(tester, engine: engine);
      await engine.open(['/m/a.flac', '/m/b.flac']);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(engine.state.value.index, 1);
      expect(engine.seeks, isEmpty);
    });

    testWidgets('sem lembrar, a fila não volta, e o volume volta', (
      tester,
    ) async {
      setWindow(tester, 1280, 800);
      final db = LibraryDb.memory();
      final store = DirectStore(db);
      await store.setSetting(
        'session',
        '{"queue":["/m/a.flac"],"index":0,"positionMs":0,"volume":0.3}',
      );
      await store.setSetting('settings', '{"rememberSession":false}');
      final engine = FakeEngine();
      await pumpPlayer(tester, engine: engine, db: db);
      expect(engine.opened, isEmpty);
      expect(engine.state.value.volume, 0.3);
    });

    testWidgets('o que pedem para abrir depois toca e traz a janela', (
      tester,
    ) async {
      setWindow(tester, 1280, 800);
      final engine = FakeEngine();
      var raised = 0;
      final requests = Stream.fromIterable([
        ['/m/novo.flac'],
        const <String>[],
      ]);
      await pumpPlayer(
        tester,
        engine: engine,
        openRequests: requests,
        raiseWindow: () async => raised++,
      );
      await tester.pumpAndSettle();
      expect(engine.opened.last, ['/m/novo.flac']);
      expect(raised, 2);
    });
  });

  group('letras', () {
    test('procura só onde os Ajustes dizem', () async {
      final dir = await Directory.systemTemp.createTemp('player_lyrics_');
      addTearDown(() => dir.delete(recursive: true));
      final audio = '${dir.path}/faixa.mp3';
      File('test/fixtures/tone.mp3').copySync(audio);
      File('${dir.path}/faixa.lrc').writeAsStringSync('[00:01.00]Oi\n');
      expect(readLyrics(audio), isNotNull);
      expect(readLyrics(audio, files: false), isNull);
    });
  });
}

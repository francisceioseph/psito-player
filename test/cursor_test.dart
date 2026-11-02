import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/player_app.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/ui/molecules/album_card.dart';

import 'helpers.dart';

Future<MouseCursor?> cursorOver(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: 1,
  );
  await mouse.addPointer(location: tester.getCenter(target));
  await tester.pump();
  final cursor = RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(
    1,
  );
  await mouse.removePointer();
  return cursor;
}

void main() {
  testWidgets('os botões do tema mostram a mãozinha', (tester) async {
    final base = playerBaseTheme(Colors.amber);
    await tester.pumpWidget(
      MaterialApp(
        theme: playerTheme(base),
        home: Scaffold(
          body: Column(
            children: [
              IconButton(
                key: const Key('icon'),
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
              IconButton.filled(
                key: const Key('filledIcon'),
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
              TextButton(
                key: const Key('text'),
                onPressed: () {},
                child: const Text('a'),
              ),
              FilledButton.tonal(
                key: const Key('filled'),
                onPressed: () {},
                child: const Text('b'),
              ),
              OutlinedButton(
                key: const Key('outlined'),
                onPressed: () {},
                child: const Text('c'),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('segmento')),
                ],
                selected: const {0},
                onSelectionChanged: (_) {},
              ),
              const IconButton(
                key: Key('disabled'),
                icon: Icon(Icons.add),
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
    for (final key in ['icon', 'filledIcon', 'text', 'filled', 'outlined']) {
      expect(
        await cursorOver(tester, find.byKey(Key(key))),
        SystemMouseCursors.click,
        reason: key,
      );
    }
    expect(
      await cursorOver(tester, find.text('segmento')),
      SystemMouseCursors.click,
    );
    expect(
      await cursorOver(tester, find.byKey(const Key('disabled'))),
      SystemMouseCursors.basic,
    );
  });

  testWidgets('na tela, o que é clicável mostra a mãozinha', (tester) async {
    setWindow(tester, 1280, 800);
    final db = LibraryDb.memory();
    seedAlbum(db);
    await pumpPlayer(tester, db: db);
    for (final target in [
      find.text('Biblioteca'),
      find.byTooltip('Ajustes'),
      find.byType(AlbumCard).first,
    ]) {
      expect(
        await cursorOver(tester, target),
        SystemMouseCursors.click,
        reason: '$target',
      );
    }

    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    expect(
      await cursorOver(tester, find.byType(FilterChip).first),
      SystemMouseCursors.click,
    );
    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton).first);
    await tester.pumpAndSettle();
    expect(
      await cursorOver(
        tester,
        find.byWidgetPredicate((w) => w is PopupMenuItem).first,
      ),
      SystemMouseCursors.click,
    );
  });

  test('todo InkWell e FilterChip diz o cursor', () {
    final missing = <String>[];
    for (final file in Directory('lib/src').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final match in RegExp(
        r'\b(InkWell|FilterChip)\(\s*(\w+)',
      ).allMatches(text)) {
        if (match[2] != 'mouseCursor') missing.add(file.path);
      }
    }
    expect(missing, isEmpty);
  });
}

// A duração da fila, com a fonte de verdade: na de blocos, tudo seria largo demais.
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/ui/organisms/queue_panel.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadRealFonts);

  for (final locale in PlayerLocalizations.supportedLocales) {
    testWidgets('${locale.languageCode} does not cut the queue length', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      setWindow(tester, 1280, 800);
      final db = LibraryDb.memory();
      addTearDown(db.close);
      seedAlbum(db, tracks: 12);
      await pumpPlayer(
        tester,
        db: db,
        initialPaths: [for (var i = 1; i <= 12; i++) '/m/Maré Alta/$i.flac'],
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      final l10n = lookupPlayerLocalizations(locale);
      await tester.tap(find.byTooltip(l10n.queue).first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final length = find.descendant(
        of: find.byType(QueuePanel),
        matching: find.textContaining(' · '),
      );
      expect(length, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(length).didExceedMaxLines,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/ui/pages/settings_page.dart';

import 'helpers.dart';

Map<String, String> _messages(String code) {
  final arb =
      jsonDecode(File('lib/l10n/player_$code.arb').readAsStringSync())
          as Map<String, dynamic>;
  return {
    for (final entry in arb.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// Os marcadores de um texto, sem as formas do plural: `{n, plural, one{{n} x}}` dá `n`.
Set<String> _placeholders(String message) => {
  for (final match in RegExp(r'\{(\w+)[,}]').allMatches(message)) match[1]!,
};

void main() {
  final codes = [
    for (final locale in PlayerLocalizations.supportedLocales)
      locale.languageCode,
  ];
  final template = _messages('en');

  for (final code in codes) {
    test('$code has the same messages and placeholders as the template', () {
      final messages = _messages(code);
      expect(messages.keys.toSet(), template.keys.toSet());
      for (final entry in template.entries) {
        expect(
          _placeholders(messages[entry.key]!),
          _placeholders(entry.value),
          reason: entry.key,
        );
      }
    });

    for (final size in const [Size(1280, 800), Size(760, 560)]) {
      testWidgets('$code fits at ${size.width}x${size.height}', (tester) async {
        final l10n = lookupPlayerLocalizations(Locale(code));
        tester.platformDispatcher.localesTestValue = [Locale(code)];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        setWindow(tester, size.width, size.height);
        final db = LibraryDb.memory();
        addTearDown(db.close);
        seedAlbum(db);
        await pumpPlayer(tester, db: db);
        await tester.pumpAndSettle();
        for (final page in [l10n.library, l10n.playlists, l10n.settings]) {
          // Com a barra lateral aberta, o destino mostra o nome em vez da dica
          final tooltip = find.byTooltip(page);
          await tester.tap(
            tooltip.evaluate().isEmpty ? find.text(page).first : tooltip.first,
          );
          await tester.pumpAndSettle();
        }
        for (final section in [
          l10n.settingsEqualizer,
          l10n.settingsLibrary,
          l10n.settingsLyrics,
          l10n.settingsAppearance,
          l10n.settingsShortcuts,
          l10n.settingsAbout,
        ]) {
          await tester.tap(
            find.descendant(
              of: find.byType(SettingsPage),
              matching: find.text(section),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('English comes first, so an unsupported language falls back to it', () {
    expect(
      basicLocaleListResolution(const [
        Locale('it'),
      ], PlayerLocalizations.supportedLocales),
      const Locale('en'),
    );
  });

  test('Russian picks the plural form by the number', () {
    final l10n = lookupPlayerLocalizations(const Locale('ru'));
    expect(l10n.albumCount(1), '1 альбом');
    expect(l10n.albumCount(21), '21 альбом');
    expect(l10n.albumCount(3), '3 альбома');
    expect(l10n.albumCount(5), '5 альбомов');
    expect(l10n.albumCount(0), '0 альбомов');
    expect(l10n.scannedDays(0), 'Обновлено сегодня');
    expect(l10n.scannedDays(21), 'Обновлено 21 день назад');
  });

  test('Chinese has one plural form', () {
    final l10n = lookupPlayerLocalizations(const Locale('zh'));
    expect(l10n.albumCount(1), '1 张专辑');
    expect(l10n.albumCount(5), '5 张专辑');
    expect(l10n.scannedDays(1), '昨天更新');
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/player/equalizer.dart';
import 'package:psito_player/src/settings/player_settings.dart';

import 'helpers.dart';

void main() {
  group('filtro', () {
    test('tudo em zero tira o filtro', () {
      expect(equalizerFilter(flatEqualizer), isEmpty);
    });

    test('só as bandas mexidas, com espaço para o que sobe', () {
      final gains = [...flatEqualizer]
        ..[0] = 6
        ..[1] = -3;
      expect(
        equalizerFilter(gains),
        'format=format=floatp,lavfi=['
        'equalizer=f=31:t=o:w=1:g=6.0,'
        'equalizer=f=62:t=o:w=1:g=-3.0]',
      );
    });

    test('a banda vizinha soma, e só o que desce não pede espaço', () {
      expect(
        equalizerHeadroom(List.filled(equalizerBands.length, 12)),
        closeTo(19.2, 0.01),
      );
      expect(equalizerHeadroom(List.filled(equalizerBands.length, -12)), 0);
    });

    test('o espaço vira amplitude', () {
      expect(equalizerGain(flatEqualizer), 1);
      expect(equalizerGain([...flatEqualizer]..[0] = 6), closeTo(0.501, 0.001));
    });
  });

  group('predefinições', () {
    test('têm uma medida por banda, dentro dos limites', () {
      for (final preset in EqualizerPreset.values) {
        expect(preset.gains, hasLength(equalizerBands.length));
        expect(preset.gains.every((g) => g.abs() <= equalizerMaxGain), isTrue);
      }
    });

    test('são reconhecidas pelos ganhos', () {
      expect(EqualizerPreset.of(flatEqualizer), EqualizerPreset.flat);
      expect(
        EqualizerPreset.of(EqualizerPreset.rock.gains),
        EqualizerPreset.rock,
      );
      expect(EqualizerPreset.of([...flatEqualizer]..[3] = 1), isNull);
    });
  });

  group('ajustes', () {
    late LibraryDb db;

    setUp(() => db = LibraryDb.memory());
    tearDown(() => db.close());

    test('começa desligado e plano', () {
      final settings = PlayerSettings();
      expect(settings.equalizerOn, isFalse);
      expect(settings.equalizerGains, flatEqualizer);
    });

    test('guarda ao mudar', () async {
      final store = DirectStore(db);
      final settings = PlayerSettings();
      await settings.load(store);
      settings
        ..equalizerOn = true
        ..setEqualizerBand(2, 5);
      await pumpEventQueue();
      final again = PlayerSettings();
      await again.load(store);
      expect(again.equalizerOn, isTrue);
      expect(again.equalizerGains[2], 5);
    });

    test(
      'o que não dá para ler fica no padrão, e o exagero, no limite',
      () async {
        final store = DirectStore(db);
        for (final bad in [
          'alto',
          [1, 2],
          List.filled(equalizerBands.length, 'alto'),
        ]) {
          db.setSetting('settings', jsonEncode({'equalizerGains': bad}));
          final settings = PlayerSettings();
          await settings.load(store);
          expect(settings.equalizerGains, flatEqualizer);
        }
        db.setSetting(
          'settings',
          jsonEncode({
            'equalizerGains': List.filled(equalizerBands.length, 99),
          }),
        );
        final settings = PlayerSettings();
        await settings.load(store);
        expect(settings.equalizerGains.first, equalizerMaxGain);
      },
    );
  });

  group('tela', () {
    late LibraryDb db;
    late FakeEngine engine;

    setUp(() {
      db = LibraryDb.memory();
      engine = FakeEngine();
    });
    tearDown(() => db.close());

    Future<void> openEqualizer(WidgetTester tester) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester, engine: engine, db: db);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ajustes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Equalizador'));
      await tester.pumpAndSettle();
    }

    testWidgets('desligado, as bandas não mexem', (tester) async {
      await openEqualizer(tester);
      final sliders = tester
          .widgetList<Slider>(find.byType(Slider))
          .where((s) => s.min == -equalizerMaxGain);
      expect(sliders, hasLength(equalizerBands.length));
      expect(sliders.every((s) => s.onChanged == null), isTrue);
    });

    testWidgets('desligado, as predefinições não mexem, e ligar libera', (
      tester,
    ) async {
      bool enabled() => tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Mais graves'))
          .isEnabled;

      await openEqualizer(tester);
      expect(enabled(), isFalse);
      await tester.tap(find.text('Mais graves'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Mais graves'), findsOneWidget);
      expect(
        EqualizerPreset.of(engine.equalizer ?? flatEqualizer),
        EqualizerPreset.flat,
      );

      await tester.tap(find.text('Usar o equalizador'));
      await tester.pumpAndSettle();
      expect(enabled(), isTrue);
    });

    testWidgets('a predefinição chega ao motor e mexer vira personalizada', (
      tester,
    ) async {
      await openEqualizer(tester);
      await tester.tap(find.text('Usar o equalizador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mais graves'));
      await tester.pumpAndSettle();
      expect(engine.equalizer, EqualizerPreset.bass.gains);
      expect(find.text('Personalizada'), findsNothing);

      final band = find
          .byType(Slider)
          .at(
            tester
                .widgetList<Slider>(find.byType(Slider))
                .toList()
                .indexWhere((s) => s.min == -equalizerMaxGain),
          );
      await tester.drag(band, const Offset(0, -40));
      await tester.pumpAndSettle();
      expect(engine.equalizer, isNot(EqualizerPreset.bass.gains));
      expect(engine.equalizer![0], greaterThan(6));
      expect(find.text('Personalizada'), findsOneWidget);
    });

    for (final (w, h) in [(420.0, 760.0), (320.0, 560.0)]) {
      testWidgets('cabe em ${w.toInt()}x${h.toInt()}, rolando', (tester) async {
        setWindow(tester, w, h);
        db.setSetting('settings', '{"mode":"compact"}');
        await pumpPlayer(tester, engine: engine, db: db);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ajustes').first);
        await tester.pumpAndSettle();
        final chip = find.text('Equalizador');
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('31 Hz'), findsOneWidget);
      });
    }
  });
}

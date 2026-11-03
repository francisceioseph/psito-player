// test/track_number_test.dart
//
// A posição nas listas e o respiro entre o tempo e os ícones.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/l10n/player_localizations.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/ui/atoms/favorite_button.dart';
import 'package:psito_player/src/ui/molecules/track_row.dart';

import 'helpers.dart';

const _track = Track(
  id: 1,
  path: '/m/a.flac',
  title: 'Faixa',
  format: 'FLAC',
  artist: 'Artista',
  album: 'Disco',
  albumId: 1,
  duration: Duration(minutes: 3, seconds: 7),
);

Future<void> _pump(
  WidgetTester tester, {
  double width = 800,
  bool current = false,
  int? number = 7,
}) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: PlayerLocalizations.localizationsDelegates,
    supportedLocales: PlayerLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: TrackRow(
            track: _track,
            number: number,
            current: current,
            onTap: () {},
            onFavorite: (_) {},
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('mostra a posição antes de tudo', (tester) async {
    await _pump(tester);
    expect(
      tester.getCenter(find.text('7')).dx,
      lessThan(tester.getTopLeft(find.text('Faixa')).dx),
    );
  });

  testWidgets('a que toca troca o número pelo sinal', (tester) async {
    await _pump(tester, current: true);
    expect(find.text('7'), findsNothing);
    expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
  });

  testWidgets('sem largura, a posição sai antes do título', (tester) async {
    await _pump(tester, width: TrackRow.detailsMinWidth - 1);
    expect(find.text('7'), findsNothing);
    expect(find.text('Faixa'), findsOneWidget);
  });

  testWidgets('o tempo não encosta nos ícones', (tester) async {
    await _pump(tester);
    final end = tester.getTopRight(find.text('3:07')).dx;
    final heart = tester.getTopLeft(find.byType(FavoriteButton)).dx;
    expect(heart - end, greaterThanOrEqualTo(TrackRow.durationGap));
  });

  testWidgets('o número grande cabe sem cortar', (tester) async {
    await loadRealFonts();
    await _pump(tester, number: 50000);
    final text = tester.renderObject<RenderParagraph>(find.text('50000'));
    expect(text.didExceedMaxLines, isFalse);
  });
}

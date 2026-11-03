// O que veio da revisão com o redesign do Spotify: buscar dentro da lista, a coluna
// ao lado, as buscas recentes, os fixados, os mixes, a tela da música e a tinta.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_search.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/ui/atoms/star_rating.dart';
import 'package:psito_player/src/ui/atoms/cover_art.dart';
import 'package:psito_player/src/ui/atoms/cover_tint.dart';
import 'package:psito_player/src/ui/atoms/generic_art.dart';
import 'package:psito_player/src/ui/organisms/mini_player.dart';
import 'package:psito_player/src/ui/organisms/navigation.dart';
import 'package:psito_player/src/ui/organisms/player_bar.dart';
import 'package:psito_player/src/ui/molecules/track_row.dart';
import 'package:psito_player/src/ui/molecules/volume_control.dart';
import 'package:psito_player/src/ui/organisms/lyrics_view.dart';
import 'package:psito_player/src/ui/pages/track_page.dart';

import 'helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void _seed(LibraryDb db, String album, String artist, String genre, int n) {
  final folder = db.addFolder('/m');
  for (var i = 1; i <= n; i++) {
    db.upsertTrack(
      ScannedTrack(
        path: '/m/$album/$i.flac',
        title: '$album $i',
        artist: artist,
        albumArtist: artist,
        album: album,
        genre: genre,
        trackNumber: i,
        durationMs: 180000,
        size: 1000,
        mtime: 1,
      ),
      folder,
      1000 + i,
    );
  }
}

void main() {
  late LibraryDb db;
  late FakeEngine engine;

  setUp(() {
    db = LibraryDb.memory();
    engine = FakeEngine();
    _seed(db, 'Maré Alta', 'Coral Vento', 'Indie', 3);
    _seed(db, 'Serra Azul', 'Ana Rio', 'MPB', 12);
  });

  Future<void> open(
    WidgetTester tester, {
    String? destination,
    List<String> paths = const [],
  }) async {
    setWindow(tester, 1280, 800);
    await pumpPlayer(tester, engine: engine, db: db, initialPaths: paths);
    if (destination != null) {
      await tester.tap(find.byTooltip(destination).first);
    }
    await _settle(tester);
  }

  Future<void> rightClick(WidgetTester tester, Finder target) async {
    await tester.tap(target, buttons: kSecondaryButton);
    await _settle(tester);
  }

  testWidgets('o volume tem largura para acertar', (tester) async {
    await open(tester);
    final slider = find.descendant(
      of: find.byType(VolumeControl),
      matching: find.byType(Slider),
    );
    expect(tester.getSize(slider).width, VolumeControl.maxSliderWidth);
  });

  group('dentro da lista', () {
    testWidgets('a busca filtra, sem acento, e o Esc fecha', (tester) async {
      await open(tester, destination: 'Biblioteca');
      await tester.tap(find.text('Serra Azul').first);
      await _settle(tester);
      await tester.tap(find.byTooltip('Buscar nesta lista'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'AZUL 1');
      await _settle(tester);
      // 1, 10, 11 e 12
      expect(find.byType(TrackRow), findsNWidgets(4));
      await tester.enterText(find.byType(TextField), 'nada disso');
      await _settle(tester);
      expect(find.byType(TrackRow), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TrackRow), findsWidgets);
    });

    testWidgets('tocar a faixa filtrada toca a filtrada', (tester) async {
      await open(tester, destination: 'Biblioteca');
      await tester.tap(find.text('Serra Azul').first);
      await _settle(tester);
      await tester.tap(find.byTooltip('Buscar nesta lista'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'azul 12');
      await _settle(tester);
      await tester.tap(find.byType(TrackRow).first);
      await _settle(tester);
      expect(engine.opened.last, ['/m/Serra Azul/12.flac']);
    });
  });

  group('cabeçalho da coleção', () {
    testWidgets('a capa fica ao lado do título, e os links abrem', (
      tester,
    ) async {
      await open(tester, destination: 'Biblioteca');
      await tester.tap(find.text('Serra Azul').first);
      await _settle(tester);
      final art = tester.getRect(find.byType(CoverArt).first);
      final title = tester.getRect(find.text('Serra Azul').first);
      expect(art.right, lessThan(title.left));
      expect(art.top, lessThanOrEqualTo(title.top));

      await tester.tap(find.widgetWithText(ActionChip, 'MPB'));
      await _settle(tester);
      expect(find.text('Serra Azul 1'), findsWidgets);
      await tester.tap(find.text('Voltar'));
      await _settle(tester);
      await tester.tap(find.text('Ana Rio').first);
      await _settle(tester);
      expect(find.text('Visão geral'), findsOneWidget);
    });

    testWidgets('o artista de fora do álbum vira chip, e o dele não repete', (
      tester,
    ) async {
      final folder = db.addFolder('/m');
      db.upsertTrack(
        const ScannedTrack(
          path: '/m/Serra Azul/99.flac',
          title: 'Dueto',
          artist: 'Lua Nova',
          albumArtist: 'Ana Rio',
          album: 'Serra Azul',
          durationMs: 1000,
          size: 1,
          mtime: 1,
        ),
        folder,
        9,
      );
      await open(tester, destination: 'Biblioteca');
      await tester.tap(find.text('Serra Azul').first);
      await _settle(tester);
      expect(find.widgetWithText(ActionChip, 'Lua Nova'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Ana Rio'), findsNothing);
    });

    for (final (w, h) in [(800.0, 700.0), (300.0, 400.0)]) {
      testWidgets('cabe em ${w.toInt()}x${h.toInt()}', (tester) async {
        setWindow(tester, w, h);
        await pumpPlayer(tester, engine: engine, db: db);
        await tester.tap(find.byTooltip('Biblioteca').first);
        await _settle(tester);
        await tester.ensureVisible(find.text('Serra Azul').first);
        await tester.pump();
        await tester.tap(find.text('Serra Azul').first);
        await _settle(tester);
        expect(find.text('Voltar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('buscas recentes', () {
    testWidgets('a busca parada fica guardada, e clicar repete', (
      tester,
    ) async {
      await open(tester, destination: 'Buscar');
      await tester.enterText(find.byType(EditableText), 'serra');
      await tester.pump(LibrarySearch.debounce);
      await tester.pump();
      await tester.pump(LibrarySearch.rememberAfter);
      await tester.pump();
      await tester.tap(find.byTooltip('Limpar a busca'));
      await _settle(tester);
      expect(find.widgetWithText(InputChip, 'serra'), findsOneWidget);
      expect(find.text('Explorar por gênero'), findsOneWidget);
      expect(db.setting('recentSearches'), contains('serra'));

      await tester.tap(find.widgetWithText(InputChip, 'serra'));
      await tester.pump(LibrarySearch.debounce);
      await _settle(tester);
      expect(find.text('Serra Azul').evaluate(), isNotEmpty);
    });

    test('quem digita devagar não deixa os pedaços', () async {
      final search = LibrarySearch(DirectStore(db));
      addTearDown(search.dispose);
      for (final text in ['se', 'serr', 'serra']) {
        search.setQuery(text);
        await Future<void>.delayed(
          LibrarySearch.debounce + const Duration(milliseconds: 20),
        );
        await Future<void>.delayed(
          LibrarySearch.rememberAfter + const Duration(milliseconds: 20),
        );
      }
      expect(search.recent, ['serra']);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('fixados', () {
    testWidgets('fixar pelo menu leva ao Início, com o selo', (tester) async {
      await open(tester, destination: 'Biblioteca');
      await rightClick(tester, find.text('Serra Azul').first);
      await tester.tap(find.text('Fixar'));
      await _settle(tester);
      expect(find.text('Fixados'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsWidgets);
      expect(db.pins(), [(PinKind.album, db.albums().last.id)]);

      await tester.tap(find.byTooltip('Início').first);
      await _settle(tester);
      expect(find.text('Fixados'), findsOneWidget);

      await rightClick(tester, find.text('Serra Azul').first);
      await tester.tap(find.text('Desafixar'));
      await _settle(tester);
      expect(find.text('Fixados'), findsNothing);
      expect(db.pins(), isEmpty);
    });

    test('o que sumiu da biblioteca só deixa de aparecer', () {
      db.pin(PinKind.playlist, 99, 1);
      db.unpin(PinKind.playlist, 99);
      expect(db.pins(), isEmpty);
    });
  });

  group('mixes', () {
    test('o mix do dia não muda no dia, e muda no outro', () {
      final today = db.dailyMix(100).map((t) => t.path).toList();
      expect(db.dailyMix(100).map((t) => t.path), today);
      expect(db.dailyMix(101).map((t) => t.path), isNot(today));
      expect(today.toSet(), hasLength(15));
    });

    test('o mix do dia mistura o que ouve com o que não ouviu', () {
      final known = db.tracks(const TrackQuery()).first;
      db.recordPlay(known.id, 1);
      expect(db.dailyMix(100).first.path, known.path);
    });

    test('um gênero precisa de faixas para ter mix', () {
      final mixes = db.mixes(100);
      expect(mixes.map((m) => m.kind), [
        PlaylistKind.dailyMix,
        PlaylistKind.genreMix,
      ]);
      expect(mixes.last.name, 'MPB');
      expect(mixes.last.trackCount, 12);
      expect(mixes.first.covers, isNotEmpty);
    });

    test('as favoritas vêm antes no mix do gênero', () {
      final tracks = db.tracks(const TrackQuery(genre: 'MPB'));
      db.setFavorite(tracks.last.id, true);
      for (final day in [1, 2, 3]) {
        expect(db.genreMix('MPB', day).first.path, tracks.last.path);
      }
    });

    testWidgets('o mix aparece no Início, abre e toca', (tester) async {
      await open(tester);
      expect(find.text('Seus mixes'), findsOneWidget);
      await tester.tap(find.text('Mix de MPB'));
      await _settle(tester);
      expect(find.text('Mix de MPB'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Tocar'));
      await _settle(tester);
      expect(engine.opened.last, hasLength(12));
    });
  });

  group('tela da música', () {
    const paths = ['/m/Serra Azul/1.flac', '/m/Serra Azul/2.flac'];

    testWidgets('a capa da barra abre, com a letra, e Voltar sai', (
      tester,
    ) async {
      await open(tester, paths: paths);
      await tester.tap(find.byTooltip('Abrir a tela da música'));
      await _settle(tester);
      expect(find.byType(TrackPage), findsOneWidget);
      await tester.tap(find.text('Detalhes'));
      await _settle(tester);
      expect(find.text('Formato').evaluate().length, lessThan(2));
      expect(find.byType(LyricsView), findsNothing);
      await tester.tap(find.text('Voltar'));
      await _settle(tester);
      expect(find.byType(TrackPage), findsNothing);
    });

    testWidgets('abrir o painel fecha a tela, e os dois não brigam', (
      tester,
    ) async {
      await open(tester, paths: paths);
      await tester.tap(find.byTooltip('Abrir a tela da música'));
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await _settle(tester);
      expect(find.byType(TrackPage), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final (w, h) in [
      (1280.0, 800.0),
      (700.0, 600.0),
      (600.0, 300.0),
      (240.0, 320.0),
    ]) {
      testWidgets('cabe em ${w.toInt()}x${h.toInt()}', (tester) async {
        setWindow(tester, w, h);
        await pumpPlayer(tester, engine: engine, db: db, initialPaths: paths);
        await _settle(tester);
        final cover = find.byTooltip('Abrir a tela da música');
        if (cover.evaluate().isEmpty) return;
        await tester.tap(cover.first);
        await _settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('artista', () {
    testWidgets('as abas trocam, e os álbuns têm menu na linha', (
      tester,
    ) async {
      await open(tester, destination: 'Biblioteca');
      await tester.tap(find.widgetWithText(FilterChip, 'Artistas'));
      await _settle(tester);
      await tester.tap(find.text('Ana Rio').first);
      await _settle(tester);
      expect(find.text('Visão geral'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Músicas'));
      await _settle(tester);
      expect(find.byType(TrackRow), findsAtLeast(6));
      await tester.tap(find.widgetWithText(FilterChip, 'Álbuns'));
      await _settle(tester);
      expect(find.byType(TrackRow), findsNothing);
      expect(find.byTooltip('Mais opções'), findsWidgets);
    });
  });

  group('rail', () {
    testWidgets('abre com os nomes, fecha, e lembra', (tester) async {
      await open(tester);
      final rail = find.byType(PlayerRail);
      expect(tester.getSize(rail).width, PlayerRail.expandedWidth);
      expect(
        find.descendant(of: rail, matching: find.text('Biblioteca')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Esconder os nomes'));
      await _settle(tester);
      expect(tester.getSize(rail).width, lessThan(100));
      expect(
        find.descendant(of: rail, matching: find.text('Biblioteca')),
        findsNothing,
      );
      expect(db.setting('settings'), contains('"railExpanded":false'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem largura, fica fechado e sem o botão', (tester) async {
      setWindow(tester, 800, 700);
      await pumpPlayer(tester, engine: engine, db: db);
      await _settle(tester);
      expect(tester.getSize(find.byType(PlayerRail)).width, lessThan(100));
      expect(find.byTooltip('Esconder os nomes'), findsNothing);
    });
  });

  group('modos', () {
    final sizes = <(Size, bool)>[];
    Future<void> pump(WidgetTester tester, double w, double h) async {
      sizes.clear();
      setWindow(tester, w, h);
      await pumpPlayer(
        tester,
        engine: engine,
        db: db,
        initialPaths: const ['/m/Serra Azul/1.flac'],
        resizeWindow: (size, {bool keepAbove = false}) async =>
            sizes.add((size, keepAbove)),
      );
      await _settle(tester);
    }

    Future<void> choose(WidgetTester tester, String mode) async {
      await tester.tap(find.byTooltip('Tamanho do player'));
      await _settle(tester);
      await tester.tap(find.text(mode));
      await _settle(tester);
    }

    testWidgets('o compacto põe a navegação embaixo e encolhe a janela', (
      tester,
    ) async {
      await pump(tester, 1280, 800);
      expect(find.byType(PlayerBottomNav), findsNothing);
      await choose(tester, 'Compacto');
      expect(sizes.single.$1, const Size(420, 760));
      expect(sizes.single.$2, isFalse);
      expect(find.byType(PlayerBottomNav), findsOneWidget);
      expect(find.byType(PlayerRail), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('voltar ao completo devolve o tamanho de antes', (
      tester,
    ) async {
      await pump(tester, 1100, 700);
      await choose(tester, 'Compacto');
      await choose(tester, 'Completo');
      expect(sizes.last.$1, const Size(1100, 700));
    });

    testWidgets('o mini fica por cima, com a capa e os controles, e sai', (
      tester,
    ) async {
      await pump(tester, 1280, 800);
      await choose(tester, 'Miniplayer');
      expect(sizes.single.$1, const Size(300, 364));
      expect(sizes.single.$2, isTrue);
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.byType(PlayerBar), findsNothing);
      await tester.tap(find.byTooltip('Sair do miniplayer'));
      await _settle(tester);
      expect(find.byType(MiniPlayer), findsNothing);
      expect(sizes.last.$2, isFalse);
      expect(find.byType(PlayerBar), findsOneWidget);
    });

    testWidgets('os atalhos valem no mini', (tester) async {
      db.setSetting('settings', '{"mode":"mini"}');
      await pump(tester, 300, 364);
      final before = engine.state.value.playing;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(engine.state.value.playing, isNot(before));
    });

    testWidgets('o modo volta ao reabrir, com o tamanho dele', (tester) async {
      db.setSetting('settings', '{"mode":"mini"}');
      await pump(tester, 300, 364);
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(sizes.single.$2, isTrue);
    });

    for (final (w, h) in [(300.0, 364.0), (240.0, 160.0), (900.0, 700.0)]) {
      testWidgets('o mini cabe em ${w.toInt()}x${h.toInt()}', (tester) async {
        db.setSetting('settings', '{"mode":"mini"}');
        await pump(tester, w, h);
        expect(tester.takeException(), isNull);
      });
    }

    group('as estrelas', () {
      Future<void> trackPage(WidgetTester tester) async {
        await pump(tester, 1280, 800);
        await tester.tap(find.byTooltip('Abrir a tela da música'));
        await _settle(tester);
      }

      testWidgets('vêm desligadas, e a nota dada continua guardada', (
        tester,
      ) async {
        db.setRating(db.tracks().first.id, 5);
        await trackPage(tester);
        expect(find.byType(StarRating), findsNothing);
        expect(find.byType(StarBadge), findsNothing);
        expect(db.tracks().first.rating, 5);
      });

      testWidgets('ligadas nos Ajustes, aparecem na tela da música', (
        tester,
      ) async {
        db.setSetting('settings', '{"useRatings":true}');
        await trackPage(tester);
        expect(find.byType(StarRating), findsOneWidget);
      });
    });

    for (final (w, h) in [(420.0, 760.0), (320.0, 560.0), (1280.0, 800.0)]) {
      testWidgets('o compacto cabe em ${w.toInt()}x${h.toInt()}', (
        tester,
      ) async {
        db.setSetting('settings', '{"mode":"compact"}');
        await pump(tester, w, h);
        expect(find.byType(PlayerBottomNav), findsOneWidget);
        await tester.tap(find.byTooltip('Abrir a tela da música'));
        await _settle(tester);
        expect(find.byType(TrackPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sem como mudar a janela, os modos não aparecem', (
      tester,
    ) async {
      await open(tester);
      expect(find.byTooltip('Tamanho do player'), findsNothing);
    });

    testWidgets('janela estreita e alta já fica como celular', (tester) async {
      setWindow(tester, 400, 700);
      await pumpPlayer(tester, engine: engine, db: db);
      await _settle(tester);
      expect(find.byType(PlayerBottomNav), findsOneWidget);
    });
  });

  group('arte sem capa', () {
    test('as cores são estáveis, e o texto se lê', () {
      for (final seed in ['Maré Alta|Coral', 'x', '1989|Taylor', 'Ópera|Ana']) {
        final a = ArtPalette.of(stableHash(seed));
        expect(ArtPalette.of(stableHash(seed)).deep, a.deep);
        final ink = a.ink.computeLuminance() + .05;
        final deep = a.deep.computeLuminance() + .05;
        expect(ink / deep, greaterThanOrEqualTo(4.5), reason: seed);
      }
    });

    testWidgets('desenha em qualquer tamanho, com e sem título', (
      tester,
    ) async {
      for (final side in [1.0, 40.0, 96.0, 400.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox.square(
                dimension: side,
                child: const GenericArt(seed: 'Um título bem longo|Alguém'),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('agrupar álbuns', () {
    test('o artista principal de um crédito', () {
      expect(primaryArtist('Lady Gaga/Beyoncé'), 'Lady Gaga');
      expect(primaryArtist('Taylor Swift feat. Post Malone'), 'Taylor Swift');
      expect(primaryArtist('Ana Rio; Lua Nova'), 'Ana Rio');
      expect(primaryArtist('Ana Rio FT. Lua'), 'Ana Rio');
      expect(primaryArtist('AC/DC'), 'AC/DC');
      expect(primaryArtist('Simon & Garfunkel'), 'Simon & Garfunkel');
      expect(primaryArtist('Tyler, the Creator'), 'Tyler, the Creator');
      expect(primaryArtist(''), '');
    });

    test('as participações ficam no mesmo álbum', () {
      final fresh = LibraryDb.memory();
      final folder = fresh.addFolder('/x');
      for (final (i, artist) in ['Lady Gaga', 'Lady Gaga/Beyoncé'].indexed) {
        fresh.upsertTrack(
          ScannedTrack(
            path: '/x/$i.flac',
            title: '$i',
            artist: artist,
            albumArtist: artist,
            album: 'The Fame',
            durationMs: 1,
            size: 1,
            mtime: 1,
          ),
          folder,
          i,
        );
      }
      final album = fresh.albums().single;
      expect(album.artist, 'Lady Gaga');
      expect(album.trackCount, 2);
      // A faixa continua com o crédito inteiro
      expect(
        fresh.albumTracks(album.id).map((t) => t.artist),
        containsAll(['Lady Gaga', 'Lady Gaga/Beyoncé']),
      );
    });

    testWidgets('as faixas sozinhas saem da grade, para a entrada delas', (
      tester,
    ) async {
      _seed(db, 'Uma Só', 'Lua Nova', 'Rock', 1);
      await open(tester, destination: 'Biblioteca');
      expect(find.text('Uma Só'), findsNothing);
      expect(find.text('Maré Alta'), findsWidgets);
      await tester.tap(find.text('Músicas avulsas'));
      await _settle(tester);
      expect(find.text('Uma Só 1'), findsOneWidget);
      expect(find.byType(TrackRow), findsOneWidget);
    });

    testWidgets('uma biblioteca só de avulsas mostra todas na grade', (
      tester,
    ) async {
      db = LibraryDb.memory();
      _seed(db, 'Uma Só', 'Lua Nova', 'Rock', 1);
      await open(tester, destination: 'Biblioteca');
      expect(find.text('Uma Só'), findsWidgets);
      expect(find.text('Músicas avulsas'), findsNothing);
    });

    test('os recentes dão preferência aos álbuns', () {
      _seed(db, 'Uma Só', 'Lua Nova', 'Rock', 1);
      expect(db.recentAlbums(2).map((a) => a.title), isNot(contains('Uma Só')));
      expect(db.recentAlbums(3).map((a) => a.title), contains('Uma Só'));
    });
  });

  group('tinta da capa', () {
    test('pega a cor marcante, não a média cinza', () {
      final image = img.Image(width: 64, height: 64);
      img.fill(image, color: img.ColorRgb8(30, 30, 30));
      img.fillRect(
        image,
        x1: 0,
        y1: 0,
        x2: 24,
        y2: 24,
        color: img.ColorRgb8(220, 40, 40),
      );
      final color = dominantColor(img.encodePng(image))!;
      expect(color.r, greaterThan(.6));
      expect(color.g, lessThan(.3));
    });

    testWidgets('a capa de verdade tinge o alto da tela', (tester) async {
      final dir = Directory.systemTemp.createTempSync('psito-tint');
      addTearDown(() => dir.deleteSync(recursive: true));
      final image = img.Image(width: 16, height: 16);
      img.fill(image, color: img.ColorRgb8(30, 60, 220));
      final file = File('${dir.path}/c.png')
        ..writeAsBytesSync(img.encodePng(image));
      await tester.pumpWidget(
        MaterialApp(
          home: CoverTint(path: file.path, child: const SizedBox.expand()),
        ),
      );
      expect(find.byType(DecoratedBox), findsNothing);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pump();
      expect(find.byType(DecoratedBox), findsOneWidget);
    });

    test('uma capa sem cor não tinge', () {
      final image = img.Image(width: 8, height: 8);
      img.fill(image, color: img.ColorRgb8(90, 90, 90));
      expect(dominantColor(img.encodePng(image)), isNull);
    });

    test('o texto continua legível sobre a tinta, nos dois temas', () {
      for (final seed in const [
        Color(0xFFFF0000),
        Color(0xFF00FF00),
        Color(0xFF0000FF),
        Color(0xFFFFFF00),
        Color(0xFFFF00FF),
      ]) {
        for (final brightness in Brightness.values) {
          final scheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFC107),
            brightness: brightness,
          );
          final under = Color.alphaBlend(
            coverTintOf(seed, brightness),
            scheme.surface,
          );
          final a = under.computeLuminance() + .05;
          final b = scheme.onSurface.computeLuminance() + .05;
          final ratio = a > b ? a / b : b / a;
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '$seed $brightness');
        }
      }
    });
  });
}

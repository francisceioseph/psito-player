// test/smart_playlist_test.dart
//
// As playlists inteligentes: quem entra, como guardam as regras e a tela.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/models.dart';

import 'helpers.dart';

/// (título, gênero, ano, nota)
const _songs = [
  ('Um', 'Rock', 1975, 5),
  ('Dois', 'Rock', 1995, 2),
  ('Tres', 'MPB', 1975, 4),
  ('Quatro', 'MPB', 2010, 0),
  ('Cinco', null, null, 1),
];

void _seed(LibraryDb db) {
  final folder = db.addFolder('/m');
  var at = 1;
  for (final (title, genre, year, _) in _songs) {
    db.upsertTrack(
      ScannedTrack(
        path: '/m/$title.flac',
        title: title,
        album: 'Disco $title',
        artist: 'Artista',
        genre: genre,
        year: year,
        durationMs: 60000,
        size: 1,
        mtime: 1,
      ),
      folder,
      at++,
    );
  }
  for (final track in db.tracks()) {
    final rating = _songs.firstWhere((s) => s.$1 == track.title).$4;
    if (rating > 0) db.setRating(track.id, rating);
  }
}

void main() {
  late LibraryDb db;

  setUp(() {
    db = LibraryDb.memory();
    _seed(db);
  });
  tearDown(() => db.close());

  List<String> titles(SmartRules rules) => [
    for (final track in db.smartTracks(rules)) track.title,
  ];

  group('quem entra', () {
    test('gênero é, e não é', () {
      expect(
        titles(
          const SmartRules(
            rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'rock')],
          ),
        ),
        unorderedEquals(['Um', 'Dois']),
      );
      expect(
        titles(
          const SmartRules(
            rules: [
              SmartRule(SmartField.genre, SmartOp.notEquals, text: 'Rock'),
            ],
          ),
        ),
        unorderedEquals(['Tres', 'Quatro', 'Cinco']),
      );
    });

    test('o ano compara, e quem não tem ano fica de fora', () {
      expect(
        titles(
          const SmartRules(
            rules: [SmartRule(SmartField.year, SmartOp.atMost, number: 1980)],
          ),
        ),
        unorderedEquals(['Um', 'Tres']),
      );
    });

    test('"no máximo" na nota não pega quem não tem nota', () {
      expect(
        titles(
          const SmartRules(
            rules: [SmartRule(SmartField.rating, SmartOp.atMost, number: 2)],
          ),
        ),
        unorderedEquals(['Dois', 'Cinco']),
      );
    });

    const rock = SmartRule(SmartField.genre, SmartOp.equals, text: 'Rock');
    const old = SmartRule(SmartField.year, SmartOp.atMost, number: 1980);

    test('todas as regras, ou qualquer uma', () {
      expect(titles(const SmartRules(rules: [rock, old])), ['Um']);
      expect(
        titles(const SmartRules(rules: [rock, old], matchAll: false)),
        unorderedEquals(['Um', 'Dois', 'Tres']),
      );
    });

    test('sem regra, nada entra', () {
      expect(titles(const SmartRules(rules: [])), isEmpty);
    });

    test('ordena e limita, e o total respeita o limite', () {
      const rules = SmartRules(
        rules: [SmartRule(SmartField.rating, SmartOp.atLeast, number: 1)],
        sort: TrackSort.rating,
        ascending: false,
        limit: 2,
      );
      expect(titles(rules), ['Um', 'Tres']);
      expect(db.smartTotals(rules).tracks, 2);
      expect(db.smartTotals(rules).duration, const Duration(minutes: 2));
    });

    test('a ordem por ano deixa quem não tem ano por último', () {
      const rules = SmartRules(
        rules: [SmartRule(SmartField.rating, SmartOp.atLeast, number: 1)],
        sort: TrackSort.year,
        ascending: false,
      );
      expect(titles(rules).last, 'Cinco');
    });
  });

  group('as regras guardadas', () {
    const rules = SmartRules(
      rules: [
        SmartRule(SmartField.genre, SmartOp.notEquals, text: 'Rock'),
        SmartRule(SmartField.year, SmartOp.atLeast, number: 1990),
      ],
      matchAll: false,
      sort: TrackSort.added,
      ascending: false,
      limit: 20,
    );

    test('voltam iguais', () {
      final back = SmartRules.decode(rules.encode());
      expect(back.encode(), rules.encode());
      expect(back.valid, isTrue);
    });

    test('um JSON ruim vira uma lista sem nada, sem cair', () {
      for (final bad in ['{', '[]', '{"rules": 3}', '{"rules": [{"op": 1}]}']) {
        expect(SmartRules.decode(bad).rules, isEmpty);
        expect(SmartRules.decode(bad).valid, isFalse);
      }
    });

    test('a validação pede o que falta', () {
      expect(const SmartRules(rules: []).valid, isFalse);
      expect(
        const SmartRules(rules: [SmartRule(SmartField.genre, SmartOp.equals)])
            .valid,
        isFalse,
      );
      expect(
        const SmartRules(rules: [SmartRule(SmartField.year, SmartOp.atLeast)])
            .valid,
        isFalse,
      );
      expect(
        const SmartRules(
          rules: [SmartRule(SmartField.rating, SmartOp.equals, number: 6)],
        ).valid,
        isFalse,
      );
    });

    test('a playlist conta pelas regras, e não pela tabela', () {
      db.createSmartPlaylist('Velhas', rules, 1);
      final playlist = db.playlists().single;
      expect(playlist.smart, isTrue);
      expect(playlist.automatic, isFalse);
      expect(playlist.trackCount, db.smartTotals(playlist.rules!).tracks);
    });

    test('mudar as regras muda a playlist, e a escolhida à mão não', () {
      final id = db.createSmartPlaylist('Lista', rules, 1);
      db.createPlaylist('Minha', 1, ['/m/Um.flac']);
      db.setPlaylistRules(
        id,
        const SmartRules(
          rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'MPB')],
        ),
        2,
      );
      final all = db.playlists();
      expect(all.firstWhere((p) => p.name == 'Lista').trackCount, 2);
      expect(all.firstWhere((p) => p.name == 'Minha').smart, isFalse);
      expect(all.firstWhere((p) => p.name == 'Minha').trackCount, 1);
    });

    test('a capa vem das faixas que entram, e a escolhida passa na frente', () {
      final album = db.tracks().firstWhere((t) => t.title == 'Tres').albumId;
      db.setAlbumCover(album, 'tres.jpg', 'embedded');
      final id = db.createSmartPlaylist(
        'MPB',
        const SmartRules(
          rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'MPB')],
        ),
        1,
      );
      expect(db.playlists().single.covers.map((c) => c.path), ['tres.jpg']);
      db.setPlaylistCover(id, 'minha.jpg', 2);
      expect(db.playlists().single.covers.map((c) => c.path), ['minha.jpg']);
    });
  });

  group('o controlador', () {
    late LibraryController library;

    setUp(() {
      library = LibraryController(
        store: DirectStore(db),
        scanner: FakeScanner(),
      );
    });
    tearDown(() => library.dispose());

    test('as faixas vêm das regras, e uma música nova já entra', () async {
      await library.createSmartPlaylist(
        'Rock',
        const SmartRules(
          rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'Rock')],
        ),
      );
      final playlist = library.playlists.single;
      expect(await library.tracksOf(playlist), hasLength(2));
      db.upsertTrack(
        const ScannedTrack(
          path: '/m/novo.flac',
          title: 'Novo',
          album: 'Novo',
          genre: 'Rock',
          size: 1,
          mtime: 1,
        ),
        db.folders().single.id,
        9,
      );
      expect(await library.tracksOf(playlist), hasLength(3));
    });
  });

  group('a tela', () {
    Future<void> openPlaylists(WidgetTester tester) async {
      setWindow(tester, 1280, 800);
      await pumpPlayer(tester, db: db);
      await tester.tap(find.byIcon(Icons.playlist_play_rounded).first);
      await tester.pumpAndSettle();
    }

    testWidgets('cria com o nome e a regra, vendo a contagem', (tester) async {
      await openPlaylists(tester);
      await tester.tap(find.text('Playlist inteligente'));
      await tester.pumpAndSettle();
      final create = find.widgetWithText(FilledButton, 'Criar');
      // A regra já vem pronta, e falta o nome
      expect(tester.widget<FilledButton>(create).onPressed, isNull);
      expect(find.text('2 músicas'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Só o MPB');
      await tester.pump();
      await tester.tap(create);
      await tester.pumpAndSettle();
      final playlist = db.playlists().single;
      expect(playlist.name, 'Só o MPB');
      expect(playlist.smart, isTrue);
      expect(find.text('2 músicas · inteligente'), findsOneWidget);
    });

    testWidgets('dentro dela, nada de escolher à mão', (tester) async {
      db.createSmartPlaylist(
        'Rock',
        const SmartRules(
          rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'Rock')],
        ),
        1,
      );
      await openPlaylists(tester);
      await tester.tap(find.text('Rock').first);
      await tester.pumpAndSettle();
      expect(find.text('Adicionar músicas'), findsNothing);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
      expect(find.text('Um'), findsOneWidget);
      expect(find.text('Editar regras'), findsOneWidget);

      await tester.tap(find.text('Editar regras'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar regra'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remover regra'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Remover regra').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();
      expect(db.playlists().single.rules!.rules, hasLength(1));
    });

    testWidgets('não aparece em "Adicionar à playlist"', (tester) async {
      db.createPlaylist('Minha', 1);
      db.createSmartPlaylist(
        'Regrada',
        const SmartRules(
          rules: [SmartRule(SmartField.genre, SmartOp.equals, text: 'Rock')],
        ),
        1,
      );
      await openPlaylists(tester);
      await tester.tap(find.text('Regrada').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais opções').at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar à playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Minha'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Regrada'),
        ),
        findsNothing,
      );
    });
  });
}

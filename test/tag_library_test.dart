// O editor de tags com a biblioteca: gravar relê a pasta, desfazer volta, a capa
// embutida que mudou sai do álbum, e o compositor e o comentário entram na busca.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' show Image, encodePng;
import 'package:path/path.dart' as p;
import 'package:psito_player/src/library/library_controller.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/library/scanner.dart';
import 'package:psito_player/src/library/tag_edit/tag_edit.dart';
import 'package:psito_player/src/library/tag_edit/tag_files.dart';
import 'package:psito_player/src/library/tag_edit/tag_undo.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  late Directory music;
  late LibraryDb db;
  late FakeScanner scanner;
  late LibraryController library;

  final png = encodePng(Image(width: 4, height: 4));

  String track(String name, Map<TagField, String> tags) {
    final path = p.join(music.path, 'Disco', name);
    File(path).parent.createSync(recursive: true);
    File('test/fixtures/tone.flac').copySync(path);
    writeTags(path, TagEdit(fields: tags));
    return path;
  }

  Future<void> scan() => scanFolders(
    db: db,
    folders: db.folders(),
    coverDir: p.join(dir.path, 'covers'),
    control: ScanControl(),
    onProgress: (_) {},
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('psito-tag-library');
    music = Directory(p.join(dir.path, 'Musica'))..createSync();
    Directory(p.join(dir.path, 'covers')).createSync();
    db = LibraryDb.memory();
    db.addFolder(music.path);
    scanner = FakeScanner();
    library = LibraryController(
      store: DirectStore(db),
      scanner: scanner,
      tagUndoDir: p.join(dir.path, 'undo'),
    );
    addTearDown(library.dispose);
  });

  tearDown(() {
    db.close();
    dir.deleteSync(recursive: true);
  });

  test('compositor e comentário entram no banco e na busca', () async {
    track('1.flac', {
      TagField.title: 'Maré',
      TagField.composer: 'Dorival Caymmi',
      TagField.comment: 'gravado ao vivo',
    });
    await scan();
    expect(db.search('Caymmi').tracks.single.title, 'Maré');
    expect(db.search('vivo').tracks.single.title, 'Maré');
  });

  test('gravar relê a pasta, e desfazer volta o arquivo', () async {
    final path = track('1.flac', {
      TagField.title: 'Maré',
      TagField.album: 'Antigo',
      TagField.artist: 'Coral Vento',
    });
    await scan();
    await library.reload();
    final progress = <(int, int)?>[];
    library.addListener(() => progress.add(library.tagWrite));

    final report = await library.writeTags({
      path: const TagEdit(fields: {TagField.album: 'Novo'}),
    });
    expect(report.written, [path]);
    expect(report.failed, isEmpty);
    expect(report.undoId, isNotNull);
    expect(progress, containsAllInOrder([(0, 1), (1, 1), null]));
    // A releitura vai para o leitor, que aqui é falso: lê de verdade
    expect(scanner.sessions.last.folders.single.path, music.path);
    await scan();
    expect(db.albums().map((a) => a.title), ['Novo']);

    final undone = await library.undoTags(report.undoId!);
    expect(undone.written, [path]);
    expect(readEditableTags(path).values[TagField.album], 'Antigo');
    expect(Directory(p.join(dir.path, 'undo')).listSync(), isEmpty);
    await scan();
    expect(db.albums().map((a) => a.title), ['Antigo']);
  });

  test('uma faixa que falha não impede as outras', () async {
    final ok = track('1.flac', {TagField.title: 'Um'});
    final locked = track('2.flac', {TagField.title: 'Dois'});
    lockFile(locked);
    await scan();
    await library.reload();
    final report = await library.writeTags({
      for (final path in [ok, locked])
        path: const TagEdit(fields: {TagField.genre: 'MPB'}),
    });
    expect(report.written, [ok]);
    expect(report.failed.single.path, locked);
    expect(report.failed.single.reason, TagWriteFailure.noPermission);
  });

  test('a capa embutida que mudou sai do álbum e volta nova', () async {
    final path = track('1.flac', {
      TagField.title: 'Um',
      TagField.album: 'Disco',
    });
    writeTags(path, TagEdit(coverChanged: true, cover: TagPicture.sniff(png)));
    await scan();
    await library.reload();
    final before = db.albums().single;
    expect(before.coverPath, isNotNull);

    final other = encodePng(Image(width: 8, height: 8));
    await library.writeTags({
      path: TagEdit(coverChanged: true, cover: TagPicture.sniff(other)),
    });
    expect(db.albums().single.coverPath, isNull);
    expect(File(before.coverPath!).existsSync(), isFalse);
    await scan();
    expect(db.albums().single.coverPath, isNotNull);
  });

  test('sem o diário, grava mas não desfaz', () async {
    final path = track('1.flac', {TagField.title: 'Um'});
    final plain = LibraryController(store: DirectStore(db), scanner: scanner);
    addTearDown(plain.dispose);
    final report = await plain.writeTags({
      path: const TagEdit(fields: {TagField.title: 'Dois'}),
    });
    expect(report.written, [path]);
    expect(report.undoId, isNull);
  });

  test('o diário lido de volta desfaz pelo controlador', () async {
    final path = track('1.flac', {TagField.title: 'Um'});
    final result = writeTagFile(
      path,
      const TagEdit(fields: {TagField.title: 'Dois'}),
    );
    final id = TagUndoJournal(p.join(dir.path, 'undo'))
        .record([(result as TagFileWritten).undo], 1);
    await library.undoTags(id);
    expect(readEditableTags(path).values[TagField.title], 'Um');
  });
}

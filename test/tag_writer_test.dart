// O motor do editor de tags, nos arquivos de test/fixtures, gravados por encoders
// de verdade. Quem confere que o resto ficou igual é o mutagen
// (tool/check_tags.py), que não é o nosso leitor; sem ele, esses testes pulam.
// O áudio é conferido decodificando pela libmpv antes e depois.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' show Image, encodePng;
import 'package:psito_player/src/library/tag_edit/safe_write.dart';
import 'package:psito_player/src/library/tag_edit/tag_edit.dart';
import 'package:psito_player/src/library/tag_edit/tag_files.dart';
import 'package:psito_player/src/library/tag_edit/tag_undo.dart';
import 'package:psito_player/src/library/tags.dart';
import 'package:psito_player/src/player/media_kit_engine.dart';

const _formats = [
  'tone.flac',
  'tone.ogg',
  'tone.opus',
  'tone.m4a',
  'tone-moov-end.m4a',
  'tone.mp3',
  'tone.aac',
  'tone.wav',
  'tone.aiff',
  'tone.wv',
  'tone.ape',
];

final _hasMutagen =
    Process.runSync('python3', ['-c', 'import mutagen']).exitCode == 0;

/// Um PNG de verdade, de 2×2.
final _png = encodePng(Image(width: 2, height: 2));

const _all = TagEdit(
  fields: {
    TagField.title: 'Título novo',
    TagField.artist: 'Artista Ç',
    TagField.album: 'Álbum novo',
    TagField.albumArtist: 'Banda',
    TagField.trackNumber: '7',
    TagField.trackTotal: '9',
    TagField.discNumber: '2',
    TagField.discTotal: '3',
    TagField.year: '2024',
    TagField.genre: 'MPB',
    TagField.composer: 'Quem compôs',
    TagField.comment: 'Um comentário',
    TagField.lyrics: 'Primeira linha\nSegunda linha',
  },
);

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('psito-tags'));
  tearDown(() => dir.deleteSync(recursive: true));

  File copy(String name) =>
      File('test/fixtures/$name').copySync('${dir.path}/$name');

  group('grava e lê de volta', () {
    for (final name in _formats) {
      test(name, () {
        final file = copy(name);
        final edit = TagEdit(
          fields: _all.fields,
          coverChanged: true,
          cover: TagPicture(Uint8List.fromList(_png), 'image/png'),
        );
        writeTags(file.path, edit);
        final back = readEditableTags(file.path);
        expect(back.writable, Writable.yes);
        for (final field in TagField.values) {
          expect(back.values[field], _all.fields[field], reason: '$field');
        }
        expect(back.cover?.bytes, _png);

        // O leitor da biblioteca também vê
        final library = readFileTags(file);
        expect(library.title, 'Título novo');
        expect(library.album, 'Álbum novo');
        expect(library.trackNumber, 7);
        expect(library.year, 2024);
        expect(library.genre, 'MPB');
        expect(library.cover, _png);
        expect(library.durationMs, greaterThan(0));

        // Limpar tira, e o resto continua
        writeTags(file.path, const TagEdit(fields: {TagField.comment: null}));
        final cleared = readEditableTags(file.path);
        expect(cleared.values.containsKey(TagField.comment), isFalse);
        expect(cleared.values[TagField.title], 'Título novo');

        // Mudar só o número mantém o total
        writeTags(
          file.path,
          const TagEdit(fields: {TagField.trackNumber: '8'}),
        );
        final paired = readEditableTags(file.path);
        expect(paired.values[TagField.trackNumber], '8');
        expect(paired.values[TagField.trackTotal], '9');
      });
    }
  });

  group('desfazer', () {
    for (final name in _formats) {
      test(name, () {
        final file = copy(name);
        final before = readEditableTags(file.path);
        final result = writeTagFile(file.path, _all);
        expect(result, isA<TagFileWritten>());
        final undo = (result as TagFileWritten).undo;
        expect(undoTagFile(undo), isA<TagFileWritten>());
        final after = readEditableTags(file.path);
        expect(after.values, before.values);
      });
    }

    test('não desfaz por cima de outra mudança', () {
      final file = copy('tone.flac');
      final undo = (writeTagFile(file.path, _all) as TagFileWritten).undo;
      file.setLastModifiedSync(DateTime(2001));
      final result = undoTagFile(undo);
      expect(
        (result as TagFileFailed).reason,
        TagWriteFailure.changedMeanwhile,
      );
    });

    test('o diário guarda, lê e esquece o que passou do limite', () {
      final journal = TagUndoJournal('${dir.path}/undo');
      final entry = TagUndoEntry('/x.flac', 1, 2, _all);
      final id = journal.record([entry], 1000);
      final loaded = journal.load(id)!;
      expect(loaded.single.path, '/x.flac');
      expect(loaded.single.inverse.fields, _all.fields);
      for (var i = 0; i < tagUndoKeep + 3; i++) {
        journal.record([entry], 2000 + i);
      }
      expect(Directory('${dir.path}/undo').listSync().length, tagUndoKeep);
      journal.prune(2000 + tagUndoMaxAge.inMilliseconds + 100);
      expect(Directory('${dir.path}/undo').listSync(), isEmpty);
    });
  });

  group('gravar com segurança', () {
    test('no lugar, quando cabe: o arquivo é o mesmo', () {
      final file = copy('tone.flac');
      // A primeira gravação deixa espaço; a segunda cabe nele
      writeTags(file.path, _all);
      final inode = _inode(file);
      writeTags(file.path, const TagEdit(fields: {TagField.title: 'Curto'}));
      expect(_inode(file), inode);
      expect(readEditableTags(file.path).values[TagField.title], 'Curto');
    });

    test('a reescrita mantém o modo do arquivo', () {
      final file = copy('tone.mp3');
      Process.runSync('chmod', ['640', file.path]);
      writeTags(file.path, _all, forceRewrite: true);
      expect(file.statSync().mode & 0x1FF, 0x1A0);
      expect(
        dir.listSync().where((e) => e.path.contains('.psito-tmp')),
        isEmpty,
      );
    });

    test('uma conferência que falha deixa o original', () {
      final file = copy('tone.ogg');
      final bytes = file.readAsBytesSync();
      for (final force in [false, true]) {
        expect(
          () => applySplices(
            file,
            [Splice(0, 4, Uint8List.fromList('OggS'.codeUnits))],
            forceRewrite: force,
            verify: (_) =>
                throw const TagWriteException(TagWriteFailure.verifyFailed),
          ),
          throwsA(isA<TagWriteException>()),
        );
        expect(file.readAsBytesSync(), bytes);
      }
    });

    test('sem permissão, diz o motivo e não grava', () {
      final file = copy('tone.flac');
      Process.runSync('chmod', ['444', file.path]);
      expect(readEditableTags(file.path).writable, Writable.noPermission);
      final result = writeTagFile(file.path, _all);
      expect((result as TagFileFailed).reason, TagWriteFailure.noPermission);
    });

    test('WMA fica só leitura, com as tags do leitor da biblioteca', () {
      final tags = readEditableTags('test/fixtures/tone.wma');
      expect(tags.writable, Writable.unsupportedFormat);
      expect(tags.values[TagField.title], 'Tom');
      final result = writeTagFile(copy('tone.wma').path, _all);
      expect(
        (result as TagFileFailed).reason,
        TagWriteFailure.unsupportedFormat,
      );
    });

    test('um arquivo que sumiu', () {
      expect(
        readEditableTags('${dir.path}/nada.flac').writable,
        Writable.missing,
      );
    });

    test('zero é nenhum, e um ano curto volta como foi escrito', () {
      final file = copy('tone.flac');
      writeTags(
        file.path,
        const TagEdit(fields: {TagField.trackNumber: '0', TagField.year: '12'}),
      );
      final back = readEditableTags(file.path);
      expect(back.values.containsKey(TagField.trackNumber), isFalse);
      expect(back.values[TagField.year], '12');
    });

    test('MP3 sem nenhuma tag ganha um ID3v2', () {
      final file = copy('tone.mp3');
      // Tira o ID3v2 do fixture, se houver
      final raf = file.openSync();
      final size = id3v2SizeFor(raf);
      raf.closeSync();
      file.writeAsBytesSync(file.readAsBytesSync().sublist(size));
      writeTags(file.path, const TagEdit(fields: {TagField.title: 'Nova'}));
      expect(readFileTags(file).title, 'Nova');
    });

    test('Opus com uma capa grande renumera as páginas', () async {
      final file = copy('tone.opus');
      final big = Uint8List.fromList([..._png, ...List.filled(200000, 7)]);
      writeTags(
        file.path,
        TagEdit(coverChanged: true, cover: TagPicture(big, 'image/png')),
      );
      expect(readEditableTags(file.path).cover?.bytes, big);
      expect(await _decode(file.path), isNotEmpty);
    });
  });

  group('o resto fica igual, pelo mutagen', () {
    for (final name in _formats) {
      test(name, () async {
        final file = copy(name);
        _seed(file.path);
        final pcm = await _decode(file.path);
        final before = _dump(file.path);
        // O mutagen gravou mesmo o que o teste confere
        expect(
          (before['tags'] as Map).length,
          greaterThanOrEqualTo(10),
          reason: '$before',
        );

        writeTags(file.path, const TagEdit(fields: {TagField.title: 'Novo'}));
        final after = _dump(file.path);
        expect(_without(after, _titleKeys), _without(before, _titleKeys));
        expect(readFileTags(file).title, 'Novo');

        // Uma mudança grande reescreve, e o resto continua
        final big = Uint8List.fromList([..._png, ...List.filled(100000, 1)]);
        writeTags(
          file.path,
          TagEdit(coverChanged: true, cover: TagPicture(big, 'image/png')),
        );
        final rewritten = _dump(file.path);
        expect(
          _without(rewritten, {..._titleKeys, ..._coverKeys}),
          _without(before, {..._titleKeys, ..._coverKeys}),
        );
        expect(await _decode(file.path), pcm, reason: 'o áudio mudou');
      }, skip: _hasMutagen ? false : 'sem o python3-mutagen');
    }

    test('ID3v2.3 continua 2.3', () {
      final file = copy('tone.mp3');
      _seed(file.path, v23: true);
      final before = _dump(file.path);
      writeTags(file.path, const TagEdit(fields: {TagField.title: 'Novo'}));
      final after = _dump(file.path);
      expect(file.readAsBytesSync()[3], 3);
      expect(_without(after, _titleKeys), _without(before, _titleKeys));
    }, skip: _hasMutagen ? false : 'sem o python3-mutagen');
  });
}

int id3v2SizeFor(RandomAccessFile file) {
  final header = readAt(file, 0, 10);
  if (String.fromCharCodes(header, 0, 3) != 'ID3') return 0;
  return 10 +
      ((header[6] & 0x7F) << 21 |
          (header[7] & 0x7F) << 14 |
          (header[8] & 0x7F) << 7 |
          (header[9] & 0x7F));
}

int _inode(File file) {
  final out = Process.runSync('stat', ['-c', '%i', file.path]).stdout;
  return int.parse((out as String).trim());
}

/// As chaves do título e da capa em cada formato, que o teste muda.
const _titleKeys = {'TIT2', 'title', '©nam', 'Title'};
const _coverKeys = {
  'APIC:',
  'APIC:verso',
  'metadata_block_picture',
  'covr',
  'Cover Art (Front)',
  'pictures',
};

void _seed(String path, {bool v23 = false}) {
  final result = Process.runSync('python3', [
    'tool/check_tags.py',
    'seed',
    path,
    if (v23) '--v23',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
}

Map<String, Object?> _dump(String path) {
  final result = Process.runSync('python3', [
    'tool/check_tags.py',
    'dump',
    path,
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return jsonDecode(result.stdout as String) as Map<String, Object?>;
}

Map<String, Object?> _without(Map<String, Object?> dump, Set<String> keys) {
  final tags = Map.of(dump['tags'] as Map<String, Object?>)
    ..removeWhere((k, _) => keys.contains(k));
  return {
    'type': dump['type'],
    'info': dump['info'],
    'tags': tags,
    if (!keys.contains('pictures')) 'pictures': dump['pictures'],
  };
}

/// O áudio decodificado pela libmpv.
Future<List<int>> _decode(String path) async {
  final out = File('$path.pcm.wav');
  final engine = MediaKitEngine(
    options: {
      'ao': 'pcm',
      'ao-pcm-file': out.path,
      'audio-format': 's16',
      'audio-samplerate': '44100',
      'audio-channels': 'mono',
      'replaygain': 'no',
    },
  );
  await engine.open([File(path).absolute.path]);
  var last = -1;
  var still = 0;
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (still < 5 && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final size = out.existsSync() ? out.lengthSync() : 0;
    still = size == last && size > 44 ? still + 1 : 0;
    last = size;
  }
  await engine.dispose();
  final bytes = out.readAsBytesSync().sublist(44);
  out.deleteSync();
  return bytes;
}

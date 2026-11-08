// lib/src/library/tag_edit/tag_files.dart
//
// Ler e gravar as tags de um arquivo, escolhendo a estrutura pelo conteúdo.
import 'dart:io';

import 'package:path/path.dart' as p;

import '../tags.dart';
import 'apev2.dart';
import 'flac.dart';
import 'id3v2.dart';
import 'mp4.dart';
import 'ogg.dart';
import 'riff.dart';
import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';

/// A estrutura de tags de [file], ou nula para o que ainda não se grava (WMA).
TagFormat? tagFormatFor(RandomAccessFile file, String path) {
  if (FlacFormat.sniff(file)) return const FlacFormat();
  if (OggFormat.sniff(file)) return const OggFormat();
  if (Mp4Format.sniff(file)) return const Mp4Format();
  if (ChunkFormat.sniffWav(file)) return const ChunkFormat(aiff: false);
  if (ChunkFormat.sniffAiff(file)) return const ChunkFormat(aiff: true);
  return switch (p.extension(path).toLowerCase()) {
    '.mp3' => const Id3PrefixFormat('MP3'),
    '.aac' => const Id3PrefixFormat('AAC'),
    '.wv' => const ApeFormat('WavPack'),
    '.ape' => const ApeFormat("Monkey's Audio"),
    _ => null,
  };
}

String _formatName(String path) {
  final ext = p.extension(path);
  return ext.isEmpty ? '' : ext.substring(1).toUpperCase();
}

/// O que o leitor da biblioteca vê, para o que não se grava.
EditableTags _fromLibraryReader(
  File file,
  Writable writable, {
  bool cover = true,
}) {
  FileTags tags;
  try {
    tags = readFileTags(file);
  } catch (_) {
    tags = const FileTags();
  }
  return EditableTags(
    format: _formatName(file.path),
    values: {
      TagField.title: ?tags.title,
      TagField.artist: ?tags.artist,
      TagField.album: ?tags.album,
      TagField.albumArtist: ?tags.albumArtist,
      if (tags.trackNumber case final v?) TagField.trackNumber: '$v',
      if (tags.discNumber case final v?) TagField.discNumber: '$v',
      if (tags.year case final v?) TagField.year: '$v',
      TagField.genre: ?tags.genre,
    },
    cover: cover && tags.cover != null ? TagPicture.sniff(tags.cover!) : null,
    writable: writable,
  );
}

/// Os campos pelo leitor do editor, sem a capa, ou nulo se a estrutura não for
/// das que ele conhece. Não lança. Não cai no leitor da biblioteca, que chama
/// esta.
Map<TagField, String>? readStructuredTags(String path) {
  RandomAccessFile? raf;
  try {
    raf = File(path).openSync();
    return tagFormatFor(raf, path)?.read(raf, cover: false).values;
  } catch (_) {
    return null;
  } finally {
    raf?.closeSync();
  }
}

final _numericGenre = RegExp(r'^\(?(\d{1,3})\)?$');

/// As tags de [path] para o editor, e se dá para gravar. Não lança.
EditableTags readEditableTags(String path, {bool cover = true}) {
  final file = File(path);
  if (!file.existsSync()) {
    return EditableTags(format: _formatName(path), writable: Writable.missing);
  }
  RandomAccessFile? raf;
  try {
    raf = file.openSync();
    final format = tagFormatFor(raf, path);
    if (format == null) {
      raf.closeSync();
      raf = null;
      return _fromLibraryReader(file, Writable.unsupportedFormat, cover: cover);
    }
    var tags = format.read(raf, cover: cover);
    raf.closeSync();
    raf = null;
    // O gênero do ID3v1 em número: o leitor da biblioteca tem a tabela
    final genre = tags.values[TagField.genre];
    if (genre != null && _numericGenre.hasMatch(genre)) {
      final named = _fromLibraryReader(
        file,
        Writable.yes,
        cover: false,
      ).values[TagField.genre];
      if (named != null) {
        tags = EditableTags(
          format: tags.format,
          values: {...tags.values, TagField.genre: named},
          cover: tags.cover,
        );
      }
    }
    return tags.withWritable(writableState(file));
  } on TagWriteException {
    return _fromLibraryReader(file, Writable.unsupportedFormat, cover: cover);
  } on FileSystemException {
    return _fromLibraryReader(file, Writable.noPermission, cover: cover);
  } finally {
    raf?.closeSync();
  }
}

/// Grava [edit] em [path] e devolve como as tags estavam, para desfazer.
/// Lança [TagWriteException].
EditableTags writeTags(String path, TagEdit edit, {bool forceRewrite = false}) {
  final file = File(path);
  if (!file.existsSync()) {
    throw const TagWriteException(TagWriteFailure.missing);
  }
  final RandomAccessFile raf;
  try {
    raf = file.openSync();
  } on FileSystemException catch (e) {
    throw failureOf(e);
  }
  final TagFormat format;
  final EditableTags before;
  final TagEdit completed;
  final TagWritePlan plan;
  try {
    final found = tagFormatFor(raf, path);
    if (found == null) {
      throw const TagWriteException(TagWriteFailure.unsupportedFormat);
    }
    format = found;
    before = format.read(raf);
    completed = edit.completedWith(before);
    plan = format.plan(raf, completed);
  } on FileSystemException catch (e) {
    throw failureOf(e);
  } finally {
    raf.closeSync();
  }
  applySplices(
    file,
    plan.splices,
    tail: plan.tail,
    forceRewrite: forceRewrite,
    verify: (written) {
      final check = written.openSync();
      try {
        if (!format.read(check).matches(completed)) {
          throw const TagWriteException(TagWriteFailure.verifyFailed);
        }
      } on TagWriteException {
        rethrow;
      } catch (e) {
        throw TagWriteException(TagWriteFailure.verifyFailed, '$e');
      } finally {
        check.closeSync();
      }
    },
  );
  return before;
}

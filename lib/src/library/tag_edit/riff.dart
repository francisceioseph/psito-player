// lib/src/library/tag_edit/riff.dart
//
// O WAV e o AIFF guardam as tags num pedaço `ID3 ` (ou `id3 `). O que estava nos
// campos antigos (o `LIST/INFO` do WAV, o `NAME`, `AUTH` e `ANNO` do AIFF) sai
// quando o mesmo campo muda, para não aparecer de novo por baixo.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'id3v2.dart';
import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';

class _Chunk {
  final String id;
  final int offset;
  final int size;

  _Chunk(this.id, this.offset, this.size);

  int get dataStart => offset + 8;

  /// Com o byte de alinhamento.
  int get end => dataStart + size + (size.isOdd ? 1 : 0);
}

const _infoIds = <TagField, String>{
  TagField.title: 'INAM',
  TagField.artist: 'IART',
  TagField.album: 'IPRD',
  TagField.year: 'ICRD',
  TagField.genre: 'IGNR',
  TagField.comment: 'ICMT',
  TagField.trackNumber: 'ITRK',
};

const _aiffIds = <TagField, String>{
  TagField.title: 'NAME',
  TagField.artist: 'AUTH',
  TagField.comment: 'ANNO',
};

class ChunkFormat extends TagFormat {
  final bool aiff;

  const ChunkFormat({required this.aiff});

  @override
  String get name => aiff ? 'AIFF' : 'WAV';

  static bool sniffWav(RandomAccessFile file) {
    final head = readAt(file, 0, 12);
    return head.length == 12 &&
        String.fromCharCodes(head, 0, 4) == 'RIFF' &&
        String.fromCharCodes(head, 8, 12) == 'WAVE';
  }

  static bool sniffAiff(RandomAccessFile file) {
    final head = readAt(file, 0, 12);
    final kind = head.length == 12 ? String.fromCharCodes(head, 8, 12) : '';
    return head.length == 12 &&
        String.fromCharCodes(head, 0, 4) == 'FORM' &&
        (kind == 'AIFF' || kind == 'AIFC');
  }

  Endian get _endian => aiff ? Endian.big : Endian.little;

  List<_Chunk> _chunks(RandomAccessFile file, int from, int to) {
    final out = <_Chunk>[];
    var at = from;
    while (at + 8 <= to) {
      final head = readAt(file, at, 8);
      if (head.length < 8) break;
      final size = ByteData.sublistView(head).getUint32(4, _endian);
      final chunk = _Chunk(String.fromCharCodes(head, 0, 4), at, size);
      if (chunk.dataStart + size > to) break;
      out.add(chunk);
      at = chunk.end;
    }
    return out;
  }

  List<_Chunk> _top(RandomAccessFile file) =>
      _chunks(file, 12, file.lengthSync());

  _Chunk? _id3(List<_Chunk> chunks) =>
      chunks.where((c) => c.id == 'ID3 ' || c.id == 'id3 ').firstOrNull;

  String _legacyText(RandomAccessFile file, _Chunk chunk) {
    final bytes = readAt(file, chunk.dataStart, chunk.size);
    final text = latin1.decode(bytes).replaceAll('\u0000', '').trim();
    // Muitos programas gravam UTF-8 aqui, como o leitor da biblioteca supõe
    try {
      return utf8.decode(latin1.encode(text));
    } on FormatException {
      return text;
    }
  }

  /// Os campos antigos: (campo, pedaço).
  List<(TagField, _Chunk)> _legacy(RandomAccessFile file, List<_Chunk> chunks) {
    final out = <(TagField, _Chunk)>[];
    if (aiff) {
      for (final MapEntry(key: field, value: id) in _aiffIds.entries) {
        for (final c in chunks.where((c) => c.id == id)) {
          out.add((field, c));
        }
      }
      return out;
    }
    for (final list in chunks.where((c) => c.id == 'LIST')) {
      if (String.fromCharCodes(readAt(file, list.dataStart, 4)) != 'INFO') {
        continue;
      }
      for (final sub in _chunks(
        file,
        list.dataStart + 4,
        list.dataStart + list.size,
      )) {
        for (final MapEntry(key: field, value: id) in _infoIds.entries) {
          if (sub.id == id ||
              (field == TagField.trackNumber && sub.id == 'IPRT')) {
            out.add((field, sub));
          }
        }
      }
    }
    return out;
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final chunks = _top(file);
    final values = <TagField, String>{};
    for (final (field, chunk) in _legacy(file, chunks)) {
      final text = _legacyText(file, chunk);
      if (text.isNotEmpty) values[field] = text;
    }
    final year = yearOf(values[TagField.year]);
    year == null ? values.remove(TagField.year) : values[TagField.year] = year;
    TagPicture? picture;
    final id3 = _id3(chunks);
    if (id3 != null) {
      final tag = Id3Tag.parse(readAt(file, id3.dataStart, id3.size));
      values.addAll(id3Values(tag));
      if (cover) picture = id3Cover(tag);
    }
    return EditableTags(format: name, values: values, cover: picture);
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final chunks = _top(file);
    final legacy = _legacy(file, chunks);
    final id3Chunk = _id3(chunks);
    final Id3Tag tag;
    if (id3Chunk == null) {
      tag = Id3Tag(4, []);
      // O que só os campos antigos tinham vem junto para o ID3 novo
      final seed = <TagField, String?>{};
      for (final (field, chunk) in legacy) {
        final text = _legacyText(file, chunk);
        if (text.isNotEmpty) {
          seed[field] = field == TagField.year ? yearOf(text) : text;
        }
      }
      applyId3Edit(tag, TagEdit(fields: seed));
    } else {
      tag = Id3Tag.parse(readAt(file, id3Chunk.dataStart, id3Chunk.size));
    }
    applyId3Edit(tag, edit);

    final splices = <Splice>[];
    var delta = 0;
    void add(int start, int end, Uint8List bytes) {
      splices.add(Splice(start, end, bytes));
      delta += bytes.length - (end - start);
    }

    // Os campos antigos que mudaram saem
    final drop = {
      for (final (field, chunk) in legacy)
        if (edit.fields.containsKey(field)) chunk.offset,
    };
    if (aiff) {
      for (final c in chunks.where((c) => drop.contains(c.offset))) {
        add(c.offset, c.end, Uint8List(0));
      }
    } else {
      for (final list in chunks.where((c) => c.id == 'LIST')) {
        final subs = _chunks(
          file,
          list.dataStart + 4,
          list.dataStart + list.size,
        );
        if (!subs.any((s) => drop.contains(s.offset))) continue;
        final kept = BytesBuilder(copy: false)
          ..add(readAt(file, list.dataStart, 4));
        for (final s in subs.where((s) => !drop.contains(s.offset))) {
          kept.add(readAt(file, s.offset, s.end - s.offset));
        }
        final payload = kept.takeBytes();
        add(
          list.offset,
          list.end,
          payload.length <= 4 ? Uint8List(0) : _chunk('LIST', payload),
        );
      }
    }

    final length = file.lengthSync();
    if (id3Chunk != null) {
      final fits = tag.usedSize <= id3Chunk.size && drop.isEmpty;
      final bytes = fits ? tag.encode(fillTo: id3Chunk.size) : tag.encode();
      add(id3Chunk.offset, id3Chunk.end, _chunk(id3Chunk.id, bytes));
    } else {
      final end = chunks.isEmpty ? length : chunks.last.end;
      add(end, end, _chunk(aiff ? 'ID3 ' : 'id3 ', tag.encode()));
    }
    splices.sort((a, b) => a.start.compareTo(b.start));
    if (delta != 0) {
      final size = ByteData(4)
        ..setUint32(0, readFormSize(file) + delta, _endian);
      splices.insert(0, Splice(4, 8, size.buffer.asUint8List()));
    }
    return TagWritePlan(splices);
  }

  int readFormSize(RandomAccessFile file) =>
      ByteData.sublistView(readAt(file, 4, 4)).getUint32(0, _endian);

  Uint8List _chunk(String id, Uint8List payload) {
    final out = BytesBuilder(copy: false)..add(latin1.encode(id));
    out.add(
      (ByteData(4)..setUint32(0, payload.length, _endian)).buffer.asUint8List(),
    );
    out.add(payload);
    if (payload.length.isOdd) out.addByte(0);
    return out.takeBytes();
  }
}

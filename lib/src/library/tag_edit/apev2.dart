// lib/src/library/tag_edit/apev2.dart
//
// O APEv2 no fim do WavPack e do Monkey's Audio (antes de um ID3v1, se houver).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';

const _footerSize = 32;
const _coverKey = 'Cover Art (Front)';

const _apeKeys = <TagField, List<String>>{
  TagField.title: ['Title'],
  TagField.artist: ['Artist'],
  TagField.album: ['Album'],
  TagField.albumArtist: ['Album Artist', 'AlbumArtist', 'ALBUMARTIST'],
  TagField.year: ['Year'],
  TagField.genre: ['Genre'],
  TagField.composer: ['Composer'],
  TagField.comment: ['Comment'],
  TagField.lyrics: ['Lyrics'],
};

class _ApeItem {
  final String key;
  final int flags;
  final Uint8List value;

  const _ApeItem(this.key, this.value, [this.flags = 0]);

  bool get isText => flags & 0x06 == 0;
  String get text => utf8
      .decode(value, allowMalformed: true)
      .replaceAll('\u0000', multiValueSeparator)
      .trim();
}

class _ApeTag {
  /// Onde o tag (com o cabeçalho, se houver) começa e onde o rodapé termina.
  final int start;
  final int end;
  final List<_ApeItem> items;

  _ApeTag(this.start, this.end, this.items);
}

class ApeFormat extends TagFormat {
  @override
  final String name;

  const ApeFormat(this.name);

  /// Onde termina o que vem antes do ID3v1.
  int _beforeV1(RandomAccessFile file) {
    final length = file.lengthSync();
    if (length >= 128 &&
        String.fromCharCodes(readAt(file, length - 128, 3)) == 'TAG') {
      return length - 128;
    }
    return length;
  }

  _ApeTag? _tag(RandomAccessFile file) {
    final end = _beforeV1(file);
    if (end < _footerSize) return null;
    final footer = readAt(file, end - _footerSize, _footerSize);
    if (String.fromCharCodes(footer, 0, 8) != 'APETAGEX') return null;
    final view = ByteData.sublistView(footer);
    final size = view.getUint32(12, Endian.little);
    final count = view.getUint32(16, Endian.little);
    final flags = view.getUint32(20, Endian.little);
    final hasHeader = flags & 0x80000000 != 0;
    final itemsStart = end - size;
    if (itemsStart < 0 || size < _footerSize) throw malformed('ape size');
    final data = readAt(file, itemsStart, size - _footerSize);
    final items = <_ApeItem>[];
    var at = 0;
    final dv = ByteData.sublistView(data);
    for (var i = 0; i < count && at + 8 < data.length; i++) {
      final length = dv.getUint32(at, Endian.little);
      final itemFlags = dv.getUint32(at + 4, Endian.little);
      var keyEnd = at + 8;
      while (keyEnd < data.length && data[keyEnd] != 0) {
        keyEnd++;
      }
      if (keyEnd + 1 + length > data.length) throw malformed('ape item');
      final key = latin1.decode(data.sublist(at + 8, keyEnd));
      items.add(
        _ApeItem(
          key,
          Uint8List.fromList(data.sublist(keyEnd + 1, keyEnd + 1 + length)),
          itemFlags,
        ),
      );
      at = keyEnd + 1 + length;
    }
    final start = hasHeader ? itemsStart - _footerSize : itemsStart;
    return _ApeTag(start < 0 ? itemsStart : start, end, items);
  }

  String? _text(List<_ApeItem> items, List<String> keys) {
    for (final key in keys) {
      final item = items
          .where((i) => i.isText && i.key.toLowerCase() == key.toLowerCase())
          .firstOrNull;
      if (item != null && item.text.isNotEmpty) return item.text;
    }
    return null;
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final items = _tag(file)?.items ?? const [];
    final values = <TagField, String>{};
    for (final MapEntry(key: field, value: keys) in _apeKeys.entries) {
      final value = _text(items, keys);
      if (value != null) values[field] = value;
    }
    final year = yearOf(values[TagField.year]);
    year == null ? values.remove(TagField.year) : values[TagField.year] = year;
    for (final (key, number, total) in [
      ('Track', TagField.trackNumber, TagField.trackTotal),
      ('Disc', TagField.discNumber, TagField.discTotal),
    ]) {
      final (n, t) = splitPair(_text(items, [key]));
      if (n != null) values[number] = n;
      if (t != null) values[total] = t;
    }
    TagPicture? picture;
    if (cover) {
      final item = items
          .where((i) => i.key.toLowerCase() == _coverKey.toLowerCase())
          .firstOrNull;
      if (item != null) {
        final zero = item.value.indexOf(0);
        final bytes = Uint8List.fromList(item.value.sublist(zero + 1));
        if (bytes.isNotEmpty) picture = TagPicture.sniff(bytes);
      }
    }
    return EditableTags(format: name, values: values, cover: picture);
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final old = _tag(file);
    final items = List.of(old?.items ?? const <_ApeItem>[]);

    void replace(List<String> keys, _ApeItem? item) {
      final lower = keys.map((k) => k.toLowerCase()).toSet();
      var first = -1;
      for (var i = items.length - 1; i >= 0; i--) {
        if (lower.contains(items[i].key.toLowerCase())) {
          items.removeAt(i);
          first = i;
        }
      }
      if (item != null) items.insert(first < 0 ? items.length : first, item);
    }

    _ApeItem? text(String key, String? value) =>
        value == null ? null : _ApeItem(key, utf8.encode(value));

    for (final MapEntry(key: field, value: keys) in _apeKeys.entries) {
      if (!edit.fields.containsKey(field)) continue;
      replace(keys, text(keys.first, edit.valueOf(field)));
    }
    for (final (key, number, total) in [
      ('Track', TagField.trackNumber, TagField.trackTotal),
      ('Disc', TagField.discNumber, TagField.discTotal),
    ]) {
      if (!edit.fields.containsKey(number) && !edit.fields.containsKey(total)) {
        continue;
      }
      replace([
        key,
      ], text(key, joinPair(edit.valueOf(number), edit.valueOf(total))));
    }
    if (edit.coverChanged) {
      final cover = edit.cover;
      replace(
        [_coverKey],
        cover == null
            ? null
            : _ApeItem(
                _coverKey,
                Uint8List.fromList([
                  ...latin1.encode(
                    cover.mime == 'image/png' ? 'cover.png' : 'cover.jpg',
                  ),
                  0,
                  ...cover.bytes,
                ]),
                0x02,
              ),
      );
    }

    final body = BytesBuilder(copy: false);
    for (final item in items) {
      final head = ByteData(8)
        ..setUint32(0, item.value.length, Endian.little)
        ..setUint32(4, item.flags, Endian.little);
      body
        ..add(head.buffer.asUint8List())
        ..add(latin1.encode(item.key))
        ..addByte(0)
        ..add(item.value);
    }
    final itemsBytes = body.takeBytes();
    Uint8List frame(bool header) {
      final out = ByteData(_footerSize);
      final bytes = out.buffer.asUint8List();
      bytes.setAll(0, 'APETAGEX'.codeUnits);
      out
        ..setUint32(8, 2000, Endian.little)
        ..setUint32(12, itemsBytes.length + _footerSize, Endian.little)
        ..setUint32(16, items.length, Endian.little)
        ..setUint32(20, 0x80000000 | (header ? 0x20000000 : 0), Endian.little);
      return bytes;
    }

    final tag = Uint8List.fromList([
      ...frame(true),
      ...itemsBytes,
      ...frame(false),
    ]);
    final at = _beforeV1(file);
    return TagWritePlan([
      old == null ? Splice(at, at, tag) : Splice(old.start, old.end, tag),
    ]);
  }
}

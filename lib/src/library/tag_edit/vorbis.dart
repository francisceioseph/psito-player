// lib/src/library/tag_edit/vorbis.dart
//
// Os comentários Vorbis (FLAC, Ogg Vorbis, Opus) e o bloco de imagem do FLAC,
// que o Ogg também usa, em base64.
import 'dart:convert';
import 'dart:typed_data';

import 'tag_edit.dart';

/// Onde cada campo mora. A primeira chave é a que se grava; as outras são as
/// que outros programas usam, e saem quando o campo muda.
const vorbisKeys = <TagField, List<String>>{
  TagField.title: ['TITLE'],
  TagField.artist: ['ARTIST'],
  TagField.album: ['ALBUM'],
  TagField.albumArtist: ['ALBUMARTIST', 'ALBUM ARTIST', 'ALBUM_ARTIST'],
  TagField.trackNumber: ['TRACKNUMBER'],
  TagField.trackTotal: ['TRACKTOTAL', 'TOTALTRACKS'],
  TagField.discNumber: ['DISCNUMBER'],
  TagField.discTotal: ['DISCTOTAL', 'TOTALDISCS'],
  TagField.year: ['DATE', 'YEAR'],
  TagField.genre: ['GENRE'],
  TagField.composer: ['COMPOSER'],
  TagField.comment: ['COMMENT', 'DESCRIPTION'],
  TagField.lyrics: ['LYRICS', 'UNSYNCEDLYRICS'],
};

const vorbisPictureKey = 'METADATA_BLOCK_PICTURE';

class VorbisComments {
  String vendor;
  final List<(String, String)> entries;

  VorbisComments(this.vendor, this.entries);

  /// Lê a partir de [at], e devolve também onde terminou.
  static (VorbisComments, int) parse(Uint8List data, [int at = 0]) {
    final view = ByteData.sublistView(data);
    int u32() {
      if (at + 4 > data.length) {
        throw const TagWriteException(TagWriteFailure.malformed, 'vorbis');
      }
      final value = view.getUint32(at, Endian.little);
      at += 4;
      return value;
    }

    String text(int length) {
      if (at + length > data.length) {
        throw const TagWriteException(TagWriteFailure.malformed, 'vorbis');
      }
      final value = utf8.decode(
        data.sublist(at, at + length),
        allowMalformed: true,
      );
      at += length;
      return value;
    }

    final vendor = text(u32());
    final count = u32();
    final entries = <(String, String)>[];
    for (var i = 0; i < count; i++) {
      final entry = text(u32());
      final equals = entry.indexOf('=');
      if (equals <= 0) continue;
      entries.add((entry.substring(0, equals), entry.substring(equals + 1)));
    }
    return (VorbisComments(vendor, entries), at);
  }

  Uint8List encode() {
    final out = BytesBuilder(copy: false);
    void u32(int value) => out.add(
      (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List(),
    );
    void text(String value) {
      final bytes = utf8.encode(value);
      u32(bytes.length);
      out.add(bytes);
    }

    text(vendor);
    u32(entries.length);
    for (final (key, value) in entries) {
      text('$key=$value');
    }
    return out.takeBytes();
  }

  List<String> valuesOf(List<String> keys) {
    for (final key in keys) {
      final found = [
        for (final (k, v) in entries)
          if (k.toUpperCase() == key) v,
      ];
      if (found.isNotEmpty) return found;
    }
    return const [];
  }

  /// Tira todas as chaves de [keys] e, com valor, põe [keys.first] no lugar da
  /// primeira que havia (ou no fim).
  void replace(List<String> keys, String? value) {
    var first = -1;
    for (var i = entries.length - 1; i >= 0; i--) {
      if (keys.contains(entries[i].$1.toUpperCase())) {
        entries.removeAt(i);
        first = i;
      }
    }
    if (value == null) return;
    entries.insert(first < 0 ? entries.length : first, (keys.first, value));
  }
}

/// Os campos dos comentários.
Map<TagField, String> vorbisValues(VorbisComments comments) {
  final out = <TagField, String>{};
  for (final MapEntry(key: field, value: keys) in vorbisKeys.entries) {
    final values = comments
        .valuesOf(keys)
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty);
    if (values.isEmpty) continue;
    out[field] = values.join(multiValueSeparator);
  }
  // "3/12" no número da faixa, sem o total à parte
  for (final (number, total) in [
    (TagField.trackNumber, TagField.trackTotal),
    (TagField.discNumber, TagField.discTotal),
  ]) {
    final (n, t) = splitPair(out[number]);
    if (n == null) {
      out.remove(number);
    } else {
      out[number] = n;
    }
    if (t != null) out.putIfAbsent(total, () => t);
  }
  final year = yearOf(out[TagField.year]);
  year == null ? out.remove(TagField.year) : out[TagField.year] = year;
  return out;
}

/// Aplica os campos de [edit], já completado (ver [TagEdit.completedWith]).
void applyVorbisFields(VorbisComments comments, TagEdit edit) {
  for (final field in edit.fields.keys) {
    comments.replace(vorbisKeys[field]!, edit.valueOf(field));
  }
}

/// O bloco de imagem do FLAC.
class FlacPicture {
  final int type;
  final String mime;
  final String description;
  final int width;
  final int height;
  final int depth;
  final int colors;
  final Uint8List data;

  const FlacPicture({
    required this.type,
    required this.mime,
    this.description = '',
    this.width = 0,
    this.height = 0,
    this.depth = 0,
    this.colors = 0,
    required this.data,
  });

  factory FlacPicture.front(TagPicture picture) =>
      FlacPicture(type: 3, mime: picture.mime, data: picture.bytes);

  TagPicture get picture =>
      TagPicture(data, mime.isEmpty ? pictureMime(data) : mime);

  static FlacPicture parse(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    var at = 0;
    int u32() {
      if (at + 4 > bytes.length) {
        throw const TagWriteException(TagWriteFailure.malformed, 'picture');
      }
      final v = view.getUint32(at);
      at += 4;
      return v;
    }

    Uint8List take(int length) {
      if (at + length > bytes.length) {
        throw const TagWriteException(TagWriteFailure.malformed, 'picture');
      }
      final v = Uint8List.sublistView(bytes, at, at + length);
      at += length;
      return v;
    }

    final type = u32();
    final mime = latin1.decode(take(u32()));
    final description = utf8.decode(take(u32()), allowMalformed: true);
    final width = u32();
    final height = u32();
    final depth = u32();
    final colors = u32();
    final data = Uint8List.fromList(take(u32()));
    return FlacPicture(
      type: type,
      mime: mime,
      description: description,
      width: width,
      height: height,
      depth: depth,
      colors: colors,
      data: data,
    );
  }

  Uint8List encode() {
    final mimeBytes = latin1.encode(mime);
    final descBytes = utf8.encode(description);
    final out = BytesBuilder(copy: false);
    void u32(int v) =>
        out.add((ByteData(4)..setUint32(0, v)).buffer.asUint8List());
    u32(type);
    u32(mimeBytes.length);
    out.add(mimeBytes);
    u32(descBytes.length);
    out.add(descBytes);
    u32(width);
    u32(height);
    u32(depth);
    u32(colors);
    u32(data.length);
    out.add(data);
    return out.takeBytes();
  }
}

/// A imagem que a biblioteca mostra: a capa da frente, ou a primeira.
int? shownPicture(List<int> types) {
  if (types.isEmpty) return null;
  final front = types.indexOf(3);
  return front >= 0 ? front : 0;
}

/// Troca ou tira a imagem mostrada em [pictures], como [edit] pede.
List<T> applyPictureEdit<T>(
  List<T> pictures,
  int Function(T) typeOf,
  TagEdit edit,
  T Function(TagPicture) make,
) {
  if (!edit.coverChanged) return pictures;
  final out = List.of(pictures);
  final shown = shownPicture([for (final p in out) typeOf(p)]);
  final cover = edit.cover;
  if (cover == null) {
    if (shown != null) out.removeAt(shown);
  } else if (shown != null && typeOf(out[shown]) == 3) {
    out[shown] = make(cover);
  } else {
    out.insert(0, make(cover));
  }
  return out;
}

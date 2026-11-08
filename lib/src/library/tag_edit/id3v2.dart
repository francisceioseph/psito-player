// lib/src/library/tag_edit/id3v2.dart
//
// O ID3v2 (2.3 e 2.4), na frente do MP3 e do AAC e dentro do WAV e do AIFF, e o
// ID3v1 no fim do MP3. Só os quadros dos campos editados são refeitos: os
// outros (ReplayGain, MusicBrainz, nota, letras sincronizadas) passam como
// estão.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';
import 'vorbis.dart' show applyPictureEdit, shownPicture;

/// O espaço livre que fica depois de uma reescrita.
const id3Padding = 2048;

/// O tamanho do ID3v2 no começo do arquivo, ou 0.
int id3v2Size(RandomAccessFile file) {
  final header = readAt(file, 0, 10);
  if (header.length < 10 || String.fromCharCodes(header, 0, 3) != 'ID3') {
    return 0;
  }
  final footer = header[5] & 0x10 != 0 ? 10 : 0;
  return 10 + _syncsafe(header, 6) + footer;
}

int _syncsafe(List<int> b, int at) =>
    (b[at] & 0x7F) << 21 |
    (b[at + 1] & 0x7F) << 14 |
    (b[at + 2] & 0x7F) << 7 |
    (b[at + 3] & 0x7F);

List<int> _toSyncsafe(int v) => [
  v >> 21 & 0x7F,
  v >> 14 & 0x7F,
  v >> 7 & 0x7F,
  v & 0x7F,
];

List<int> _u32(int v) => [
  v >> 24 & 0xFF,
  v >> 16 & 0xFF,
  v >> 8 & 0xFF,
  v & 0xFF,
];

Uint8List _deUnsync(Uint8List data) {
  final out = BytesBuilder(copy: false);
  for (var i = 0; i < data.length; i++) {
    out.addByte(data[i]);
    if (data[i] == 0xFF && i + 1 < data.length && data[i + 1] == 0x00) i++;
  }
  return out.takeBytes();
}

class Id3Frame {
  final String id;
  final int flags;
  final Uint8List data;

  const Id3Frame(this.id, this.data, [this.flags = 0]);
}

class Id3Tag {
  /// 3 ou 4.
  final int version;
  final List<Id3Frame> frames;

  Id3Tag(this.version, this.frames);

  /// [bytes] começa no `ID3` e tem o tag inteiro. Lança se a versão for a 2.2,
  /// que só se lê.
  factory Id3Tag.parse(Uint8List bytes) {
    if (bytes.length < 10 || String.fromCharCodes(bytes, 0, 3) != 'ID3') {
      throw malformed('id3');
    }
    final version = bytes[3];
    if (version != 3 && version != 4) {
      throw const TagWriteException(
        TagWriteFailure.unsupportedFormat,
        'id3v2.2',
      );
    }
    final flags = bytes[5];
    final size = _syncsafe(bytes, 6);
    if (10 + size > bytes.length) throw malformed('id3 size');
    var body = Uint8List.sublistView(bytes, 10, 10 + size);
    if (version == 3 && flags & 0x80 != 0) body = _deUnsync(body);
    var at = 0;
    if (flags & 0x40 != 0 && body.length >= 4) {
      at = version == 3
          ? 4 + (body[0] << 24 | body[1] << 16 | body[2] << 8 | body[3])
          : _syncsafe(body, 0);
    }
    final frames = <Id3Frame>[];
    while (at + 10 <= body.length) {
      final id = String.fromCharCodes(body, at, at + 4);
      if (!RegExp(r'^[A-Z0-9]{4}$').hasMatch(id)) break;
      var frameSize = version == 4
          ? _syncsafe(body, at + 4)
          : body[at + 4] << 24 |
                body[at + 5] << 16 |
                body[at + 6] << 8 |
                body[at + 7];
      // O iTunes já gravou a 2.4 com o tamanho sem syncsafe
      if (version == 4 &&
          body.sublist(at + 4, at + 8).any((b) => b & 0x80 != 0)) {
        frameSize =
            body[at + 4] << 24 |
            body[at + 5] << 16 |
            body[at + 6] << 8 |
            body[at + 7];
      }
      final frameFlags = body[at + 8] << 8 | body[at + 9];
      if (at + 10 + frameSize > body.length) break;
      frames.add(
        Id3Frame(
          id,
          Uint8List.fromList(body.sublist(at + 10, at + 10 + frameSize)),
          frameFlags,
        ),
      );
      at += 10 + frameSize;
    }
    return Id3Tag(version, frames);
  }

  /// O tag inteiro, com o cabeçalho. Com [fillTo], completa até esse tamanho
  /// com zeros; sem, deixa [padding] livre.
  Uint8List encode({int? fillTo, int padding = id3Padding}) {
    final body = BytesBuilder(copy: false);
    for (final frame in frames) {
      body.add(latin1.encode(frame.id));
      body.add(
        version == 4 ? _toSyncsafe(frame.data.length) : _u32(frame.data.length),
      );
      body.add([frame.flags >> 8 & 0xFF, frame.flags & 0xFF]);
      body.add(frame.data);
    }
    final used = 10 + body.length;
    final total = fillTo != null && fillTo >= used ? fillTo : used + padding;
    body.add(Uint8List(total - used));
    final out = BytesBuilder(copy: false)
      ..add(latin1.encode('ID3'))
      ..add([version, 0, 0])
      ..add(_toSyncsafe(total - 10))
      ..add(body.takeBytes());
    return out.takeBytes();
  }

  /// O tamanho sem o espaço livre.
  int get usedSize => 10 + frames.fold(0, (sum, f) => sum + 10 + f.data.length);

  /// O conteúdo do quadro sem a dessincronização e o tamanho da 2.4. Nulo se
  /// estiver comprimido ou cifrado.
  Uint8List? content(Id3Frame frame) {
    var data = frame.data;
    if (version == 4) {
      if (frame.flags & 0x000C != 0) return null;
      if (frame.flags & 0x0002 != 0) data = _deUnsync(data);
      if (frame.flags & 0x0001 != 0) {
        if (data.length < 4) return null;
        data = Uint8List.sublistView(data, 4);
      }
    } else if (frame.flags & 0x00C0 != 0) {
      return null;
    }
    return data;
  }

  List<String> texts(String id) {
    for (final frame in frames.where((f) => f.id == id)) {
      final data = content(frame);
      if (data == null || data.isEmpty) continue;
      final values = _splitText(data[0], Uint8List.sublistView(data, 1));
      final clean = values.map((v) => v.trim()).where((v) => v.isNotEmpty);
      if (clean.isNotEmpty) return clean.toList();
    }
    return const [];
  }

  String? text(String id) {
    final values = texts(id);
    return values.isEmpty ? null : values.join(multiValueSeparator);
  }

  /// COMM e USLT: (idioma, descrição, texto).
  List<(String, String, String)> described(String id) => [
    for (final frame in frames.where((f) => f.id == id))
      ?_described(content(frame)),
  ];

  List<(int, TagPicture)> pictures() => [
    for (final frame in frames.where((f) => f.id == 'APIC'))
      ?_picture(content(frame)),
  ];

  /// Tira os quadros [ids] e põe [replacement] no lugar do primeiro.
  void replace(
    Set<String> ids,
    List<Id3Frame> replacement, [
    bool Function(Id3Frame)? only,
  ]) {
    var first = -1;
    for (var i = frames.length - 1; i >= 0; i--) {
      if (ids.contains(frames[i].id) && (only == null || only(frames[i]))) {
        frames.removeAt(i);
        first = i;
      }
    }
    frames.insertAll(first < 0 ? frames.length : first, replacement);
  }

  Id3Frame textFrame(String id, String value) =>
      Id3Frame(id, _encodeText(value, version));
}

List<String> _splitText(int encoding, Uint8List data) {
  final values = <String>[];
  if (encoding == 1 || encoding == 2) {
    var start = 0;
    for (var i = 0; i + 1 < data.length; i += 2) {
      if (data[i] == 0 && data[i + 1] == 0) {
        values.add(
          _utf16(Uint8List.sublistView(data, start, i), encoding == 2),
        );
        start = i + 2;
      }
    }
    if (start < data.length) {
      values.add(_utf16(Uint8List.sublistView(data, start), encoding == 2));
    }
  } else {
    final text = encoding == 3
        ? utf8.decode(data, allowMalformed: true)
        : latin1.decode(data);
    values.addAll(text.split('\u0000'));
  }
  return values.where((v) => v.isNotEmpty).toList();
}

String _utf16(Uint8List data, bool bigEndian) {
  var at = 0;
  var big = bigEndian;
  if (data.length >= 2) {
    if (data[0] == 0xFF && data[1] == 0xFE) {
      big = false;
      at = 2;
    } else if (data[0] == 0xFE && data[1] == 0xFF) {
      big = true;
      at = 2;
    }
  }
  final units = <int>[];
  for (var i = at; i + 1 < data.length; i += 2) {
    units.add(big ? data[i] << 8 | data[i + 1] : data[i + 1] << 8 | data[i]);
  }
  return String.fromCharCodes(units);
}

/// Onde a descrição termina, e o tamanho do terminador.
(int, int) _terminator(int encoding, Uint8List data, int from) {
  if (encoding == 1 || encoding == 2) {
    for (var i = from; i + 1 < data.length; i += 2) {
      if (data[i] == 0 && data[i + 1] == 0) return (i, 2);
    }
  } else {
    for (var i = from; i < data.length; i++) {
      if (data[i] == 0) return (i, 1);
    }
  }
  return (data.length, 0);
}

String _decode(int encoding, Uint8List data) =>
    _splitText(encoding, data).join(' ').trim();

(String, String, String)? _described(Uint8List? data) {
  if (data == null || data.length < 4) return null;
  final encoding = data[0];
  final lang = latin1.decode(data.sublist(1, 4), allowInvalid: true);
  final (end, size) = _terminator(encoding, data, 4);
  final desc = _decode(encoding, Uint8List.sublistView(data, 4, end));
  final rest = Uint8List.sublistView(data, (end + size).clamp(0, data.length));
  final text = encoding == 1 || encoding == 2
      ? _utf16(rest, encoding == 2)
      : (encoding == 3
            ? utf8.decode(rest, allowMalformed: true)
            : latin1.decode(rest));
  return (lang, desc, text.replaceAll('\u0000', '').trim());
}

(int, TagPicture)? _picture(Uint8List? data) {
  if (data == null || data.length < 4) return null;
  final encoding = data[0];
  var at = 1;
  while (at < data.length && data[at] != 0) {
    at++;
  }
  final mime = latin1.decode(data.sublist(1, at));
  at++;
  if (at >= data.length) return null;
  final type = data[at++];
  final (end, size) = _terminator(encoding, data, at);
  final bytes = Uint8List.fromList(
    data.sublist((end + size).clamp(0, data.length)),
  );
  if (bytes.isEmpty) return null;
  return (
    type,
    TagPicture(bytes, mime.contains('/') ? mime : pictureMime(bytes)),
  );
}

/// Na 2.4, UTF-8. Na 2.3, Latin-1 quando dá, e UTF-16 com BOM quando não.
Uint8List _encodeText(String value, int version, {bool terminated = false}) {
  final (encoding, bytes) = _encodeString(value, version);
  return Uint8List.fromList([
    encoding,
    ...bytes,
    if (terminated) ...(encoding == 1 ? [0, 0] : [0]),
  ]);
}

(int, List<int>) _encodeString(String value, int version) {
  if (version == 4) return (3, utf8.encode(value));
  if (value.codeUnits.every((c) => c < 256)) return (0, latin1.encode(value));
  final units = [0xFF, 0xFE];
  for (final c in value.codeUnits) {
    units
      ..add(c & 0xFF)
      ..add(c >> 8);
  }
  return (1, units);
}

Id3Frame _describedFrame(String id, String lang, String text, int version) {
  final (encoding, bytes) = _encodeString(text, version);
  final terminator = encoding == 1 ? [0xFF, 0xFE, 0, 0] : [0];
  return Id3Frame(
    id,
    Uint8List.fromList([
      encoding,
      ...latin1.encode(lang),
      ...terminator,
      ...bytes,
    ]),
  );
}

Id3Frame _pictureFrame(TagPicture picture) => Id3Frame(
  'APIC',
  Uint8List.fromList([
    0,
    ...latin1.encode(picture.mime),
    0,
    3,
    0,
    ...picture.bytes,
  ]),
);

const _textFrames = {
  TagField.title: 'TIT2',
  TagField.artist: 'TPE1',
  TagField.album: 'TALB',
  TagField.albumArtist: 'TPE2',
  TagField.genre: 'TCON',
  TagField.composer: 'TCOM',
};

Map<TagField, String> id3Values(Id3Tag tag) {
  final out = <TagField, String>{};
  for (final MapEntry(key: field, value: id) in _textFrames.entries) {
    final value = tag.text(id);
    if (value != null) out[field] = value;
  }
  void pair(String id, TagField number, TagField total) {
    final (n, t) = splitPair(tag.texts(id).firstOrNull);
    if (n != null) out[number] = n;
    if (t != null) out[total] = t;
  }

  pair('TRCK', TagField.trackNumber, TagField.trackTotal);
  pair('TPOS', TagField.discNumber, TagField.discTotal);
  final year = yearOf(tag.text('TDRC') ?? tag.text('TYER'));
  if (year != null) out[TagField.year] = year;
  final comment = tag
      .described('COMM')
      .where((c) => c.$2.isEmpty && c.$3.isNotEmpty)
      .firstOrNull;
  if (comment != null) out[TagField.comment] = comment.$3;
  final lyrics = tag
      .described('USLT')
      .where((c) => c.$3.isNotEmpty)
      .firstOrNull;
  if (lyrics != null) out[TagField.lyrics] = lyrics.$3;
  return out;
}

TagPicture? id3Cover(Id3Tag tag) {
  final pictures = tag.pictures();
  final shown = shownPicture([for (final p in pictures) p.$1]);
  return shown == null ? null : pictures[shown].$2;
}

void applyId3Edit(Id3Tag tag, TagEdit edit) {
  final v = tag.version;
  for (final MapEntry(key: field, value: id) in _textFrames.entries) {
    if (!edit.fields.containsKey(field)) continue;
    final value = edit.valueOf(field);
    tag.replace({id}, [if (value != null) tag.textFrame(id, value)]);
  }
  void pair(String id, TagField number, TagField total) {
    if (!edit.fields.containsKey(number) && !edit.fields.containsKey(total)) {
      return;
    }
    final value = joinPair(edit.valueOf(number), edit.valueOf(total));
    tag.replace({id}, [if (value != null) tag.textFrame(id, value)]);
  }

  pair('TRCK', TagField.trackNumber, TagField.trackTotal);
  pair('TPOS', TagField.discNumber, TagField.discTotal);
  if (edit.fields.containsKey(TagField.year)) {
    final year = edit.valueOf(TagField.year);
    tag.replace(
      {'TDRC', 'TYER'},
      [if (year != null) tag.textFrame(v == 4 ? 'TDRC' : 'TYER', year)],
    );
  }
  for (final (field, id, onlyPlain) in [
    (TagField.comment, 'COMM', true),
    (TagField.lyrics, 'USLT', false),
  ]) {
    if (!edit.fields.containsKey(field)) continue;
    final old = tag.described(id);
    final lang = old.firstOrNull?.$1 ?? 'eng';
    final value = edit.valueOf(field);
    tag.replace(
      {id},
      [
        if (value != null)
          _describedFrame(id, lang.length == 3 ? lang : 'eng', value, v),
      ],
      onlyPlain ? (f) => (_described(tag.content(f))?.$2 ?? '').isEmpty : null,
    );
  }
  if (edit.coverChanged) {
    final frames = tag.frames.where((f) => f.id == 'APIC').toList();
    int typeOf(Id3Frame f) => _picture(tag.content(f))?.$1 ?? 0;
    final changed = applyPictureEdit(frames, typeOf, edit, _pictureFrame);
    tag.replace({'APIC'}, changed);
  }
}

// ID3v1

const _v1Size = 128;

Map<TagField, String> id3v1Values(Uint8List b) {
  String field(int at, int length) {
    var end = at;
    while (end < at + length && b[end] != 0) {
      end++;
    }
    return latin1.decode(b.sublist(at, end)).trim();
  }

  final out = <TagField, String>{};
  void put(TagField key, String value) {
    if (value.isNotEmpty) out[key] = value;
  }

  put(TagField.title, field(3, 30));
  put(TagField.artist, field(33, 30));
  put(TagField.album, field(63, 30));
  final year = yearOf(field(93, 4));
  if (year != null) out[TagField.year] = year;
  if (b[125] == 0 && b[126] != 0) {
    put(TagField.comment, field(97, 28));
    out[TagField.trackNumber] = '${b[126]}';
  } else {
    put(TagField.comment, field(97, 30));
  }
  return out;
}

Uint8List _encodeId3v1(Uint8List old, Map<TagField, String> values) {
  final out = Uint8List.fromList(old);
  void put(int at, int length, String? value) {
    out.fillRange(at, at + length, 0);
    if (value == null) return;
    final bytes = [for (final c in value.codeUnits) c < 256 ? c : 0x3F];
    for (var i = 0; i < length && i < bytes.length; i++) {
      out[at + i] = bytes[i];
    }
  }

  put(3, 30, values[TagField.title]);
  put(33, 30, values[TagField.artist]);
  put(63, 30, values[TagField.album]);
  put(93, 4, values[TagField.year]);
  final track = int.tryParse(values[TagField.trackNumber] ?? '');
  if (track != null && track > 0 && track < 256) {
    put(97, 28, values[TagField.comment]);
    out[125] = 0;
    out[126] = track;
  } else {
    put(97, 30, values[TagField.comment]);
  }
  return out;
}

/// O ID3v2 na frente do arquivo: MP3 e AAC.
class Id3PrefixFormat extends TagFormat {
  @override
  final String name;

  const Id3PrefixFormat(this.name);

  Uint8List? _v1(RandomAccessFile file) {
    final length = file.lengthSync();
    if (length < _v1Size) return null;
    final bytes = readAt(file, length - _v1Size, _v1Size);
    return String.fromCharCodes(bytes, 0, 3) == 'TAG' ? bytes : null;
  }

  Id3Tag? _v2(RandomAccessFile file) {
    final size = id3v2Size(file);
    return size == 0 ? null : Id3Tag.parse(readAt(file, 0, size));
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final tag = _v2(file);
    final v1 = _v1(file);
    return EditableTags(
      format: name,
      values: {
        if (v1 != null) ...id3v1Values(v1),
        if (tag != null) ...id3Values(tag),
      },
      cover: tag == null || !cover ? null : id3Cover(tag),
    );
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final size = id3v2Size(file);
    final v1 = _v1(file);
    final Id3Tag tag;
    if (size == 0) {
      tag = Id3Tag(4, []);
      // Sem ID3v2, quem mostra é o v1: o que ele tem vem junto
      if (v1 != null) {
        final seed = id3v1Values(v1);
        applyId3Edit(tag, TagEdit(fields: seed));
      }
    } else {
      tag = Id3Tag.parse(readAt(file, 0, size));
    }
    applyId3Edit(tag, edit);
    final bytes = tag.usedSize <= size
        ? tag.encode(fillTo: size)
        : tag.encode();
    final splices = [Splice(0, size, bytes)];
    if (v1 != null) {
      final values = {...id3v1Values(v1)};
      for (final field in edit.fields.keys) {
        final value = edit.valueOf(field);
        value == null ? values.remove(field) : values[field] = value;
      }
      final length = file.lengthSync();
      splices.add(Splice(length - _v1Size, length, _encodeId3v1(v1, values)));
    }
    return TagWritePlan(splices);
  }
}

// lib/src/library/tag_edit/ogg.dart
//
// Os comentários do Ogg Vorbis e do Opus. Eles moram num pacote do cabeçalho,
// espalhado por páginas: o pacote novo é repaginado e, se o número de páginas
// mudar, as seguintes são renumeradas, com o CRC refeito.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';
import 'vorbis.dart';

final _crcTable = List<int>.generate(256, (i) {
  var r = i << 24;
  for (var j = 0; j < 8; j++) {
    r = r & 0x80000000 != 0 ? (r << 1) ^ 0x04C11DB7 : r << 1;
  }
  return r & 0xFFFFFFFF;
});

int oggCrc(Uint8List page) {
  var crc = 0;
  for (final b in page) {
    crc = ((crc << 8) & 0xFFFFFFFF) ^ _crcTable[(crc >> 24) ^ b];
  }
  return crc;
}

class _Page {
  final int offset;
  final int flags;
  final int granule;
  final int serial;
  final int sequence;
  final List<int> lacing;
  final Uint8List data;

  _Page(
    this.offset,
    this.flags,
    this.granule,
    this.serial,
    this.sequence,
    this.lacing,
    this.data,
  );

  int get size => 27 + lacing.length + data.length;
}

_Page? _readPage(RandomAccessFile file, int at) {
  final header = readAt(file, at, 27);
  if (header.length < 27 || String.fromCharCodes(header, 0, 4) != 'OggS') {
    return null;
  }
  final view = ByteData.sublistView(header);
  final count = header[26];
  final lacing = readAt(file, at + 27, count);
  if (lacing.length < count) return null;
  final length = lacing.fold(0, (sum, v) => sum + v);
  final data = readAt(file, at + 27 + count, length);
  if (data.length < length) return null;
  return _Page(
    at,
    header[5],
    view.getInt64(6, Endian.little),
    view.getUint32(14, Endian.little),
    view.getUint32(18, Endian.little),
    lacing,
    data,
  );
}

Uint8List _encodePage({
  required int flags,
  required int granule,
  required int serial,
  required int sequence,
  required List<int> lacing,
  required List<int> data,
}) {
  final out = Uint8List(27 + lacing.length + data.length);
  final view = ByteData.sublistView(out);
  out.setAll(0, 'OggS'.codeUnits);
  out[4] = 0;
  out[5] = flags;
  view.setInt64(6, granule, Endian.little);
  view.setUint32(14, serial, Endian.little);
  view.setUint32(18, sequence, Endian.little);
  out[26] = lacing.length;
  out.setAll(27, lacing);
  out.setAll(27 + lacing.length, data);
  view.setUint32(22, oggCrc(out), Endian.little);
  return out;
}

enum _Codec { vorbis, opus }

class _Headers {
  final _Codec codec;
  final int serial;

  /// Onde começam as páginas dos pacotes de cabeçalho depois do primeiro, e
  /// onde terminam.
  final int start;
  final int end;
  final int pageCount;

  /// Os pacotes de cabeçalho depois do primeiro: comentários e, no Vorbis, o
  /// setup.
  final List<Uint8List> packets;

  _Headers(
    this.codec,
    this.serial,
    this.start,
    this.end,
    this.pageCount,
    this.packets,
  );
}

const _vorbisPrefix = [0x03, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73];
final _opusPrefix = 'OpusTags'.codeUnits;

bool _startsWith(Uint8List data, List<int> prefix) {
  if (data.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (data[i] != prefix[i]) return false;
  }
  return true;
}

class OggFormat extends TagFormat {
  const OggFormat();

  @override
  String get name => 'Ogg';

  static bool sniff(RandomAccessFile file) =>
      String.fromCharCodes(readAt(file, 0, 4)) == 'OggS';

  _Headers _headers(RandomAccessFile file) {
    final first = _readPage(file, 0);
    if (first == null || first.flags & 0x02 == 0) throw malformed('ogg');
    final _Codec codec;
    if (_startsWith(first.data, const [
      0x01,
      0x76,
      0x6F,
      0x72,
      0x62,
      0x69,
      0x73,
    ])) {
      codec = _Codec.vorbis;
    } else if (_startsWith(first.data, 'OpusHead'.codeUnits)) {
      codec = _Codec.opus;
    } else {
      throw const TagWriteException(TagWriteFailure.unsupportedFormat, 'ogg');
    }
    // O primeiro pacote ocupa a primeira página sozinho
    if (first.lacing.isEmpty || first.lacing.last == 255) {
      throw const TagWriteException(TagWriteFailure.unsupportedFormat, 'ogg');
    }
    final wanted = codec == _Codec.vorbis ? 2 : 1;
    final packets = <Uint8List>[];
    final current = BytesBuilder(copy: false);
    var at = first.size;
    final start = at;
    var pages = 0;
    while (packets.length < wanted) {
      final page = _readPage(file, at);
      if (page == null) throw malformed('ogg page');
      if (page.serial != first.serial) {
        throw const TagWriteException(
          TagWriteFailure.unsupportedFormat,
          'ogg mux',
        );
      }
      pages++;
      var offset = 0;
      for (var i = 0; i < page.lacing.length; i++) {
        final value = page.lacing[i];
        current.add(Uint8List.sublistView(page.data, offset, offset + value));
        offset += value;
        if (value < 255) {
          packets.add(current.takeBytes());
          if (packets.length == wanted && i != page.lacing.length - 1) {
            // O áudio começaria na mesma página: fora da especificação
            throw const TagWriteException(
              TagWriteFailure.unsupportedFormat,
              'ogg',
            );
          }
        }
      }
      at += page.size;
    }
    return _Headers(codec, first.serial, start, at, pages, packets);
  }

  (VorbisComments, Uint8List) _comments(_Headers headers) {
    final packet = headers.packets.first;
    final prefix = headers.codec == _Codec.vorbis ? _vorbisPrefix : _opusPrefix;
    if (!_startsWith(packet, prefix)) throw malformed('ogg comments');
    final (comments, end) = VorbisComments.parse(packet, prefix.length);
    // Depois dos comentários: o bit de enquadramento do Vorbis, ou o que o Opus
    // permite guardar
    return (comments, Uint8List.fromList(packet.sublist(end)));
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final headers = _headers(file);
    final (comments, _) = _comments(headers);
    TagPicture? picture;
    if (cover) {
      final pictures = _pictures(comments);
      final shown = shownPicture([for (final p in pictures) p.type]);
      if (shown != null) picture = pictures[shown].picture;
    }
    return EditableTags(
      format: headers.codec == _Codec.vorbis ? 'Ogg Vorbis' : 'Opus',
      values: vorbisValues(comments),
      cover: picture,
    );
  }

  List<FlacPicture> _pictures(VorbisComments comments) {
    final out = <FlacPicture>[];
    for (final value in comments.valuesOf(const [vorbisPictureKey])) {
      try {
        out.add(FlacPicture.parse(base64.decode(value.trim())));
      } on FormatException {
        continue;
      } on TagWriteException {
        continue;
      }
    }
    return out;
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final headers = _headers(file);
    final (comments, trailer) = _comments(headers);
    applyVorbisFields(comments, edit);
    if (edit.coverChanged) {
      final changed = applyPictureEdit(
        _pictures(comments),
        (p) => p.type,
        edit,
        FlacPicture.front,
      );
      comments.replace(const [vorbisPictureKey], null);
      for (final p in changed) {
        comments.entries.add((vorbisPictureKey, base64.encode(p.encode())));
      }
    }
    final prefix = headers.codec == _Codec.vorbis ? _vorbisPrefix : _opusPrefix;
    final packet = Uint8List.fromList([
      ...prefix,
      ...comments.encode(),
      ...trailer,
    ]);
    final pages = _paginate([
      packet,
      ...headers.packets.skip(1),
    ], headers.serial);
    final bytes = BytesBuilder(copy: false);
    for (final page in pages) {
      bytes.add(page);
    }
    final shift = pages.length - headers.pageCount;
    final splice = Splice(headers.start, headers.end, bytes.takeBytes());
    if (shift == 0) return TagWritePlan([splice]);
    return TagWritePlan(
      [splice],
      tail: (source, from, out) =>
          _renumber(source, from, out, headers.serial, shift),
    );
  }
}

/// Os pacotes em páginas, a partir da sequência 1. Uma página onde termina um
/// pacote leva a posição 0; uma em que nenhum termina, -1.
List<Uint8List> _paginate(List<Uint8List> packets, int serial) {
  final pages = <Uint8List>[];
  var sequence = 1;
  var lacing = <int>[];
  final data = BytesBuilder(copy: false);
  var continued = false;
  var ends = false;

  void flush({required bool nextContinues}) {
    pages.add(
      _encodePage(
        flags: continued ? 0x01 : 0,
        granule: ends ? 0 : -1,
        serial: serial,
        sequence: sequence++,
        lacing: lacing,
        data: data.takeBytes(),
      ),
    );
    lacing = [];
    continued = nextContinues;
    ends = false;
  }

  for (final packet in packets) {
    var offset = 0;
    var left = packet.length;
    while (true) {
      final segment = left >= 255 ? 255 : left;
      lacing.add(segment);
      data.add(Uint8List.sublistView(packet, offset, offset + segment));
      offset += segment;
      left -= segment;
      final finished = segment < 255;
      if (finished) ends = true;
      if (lacing.length == 255) flush(nextContinues: !finished);
      if (finished) break;
    }
  }
  if (lacing.isNotEmpty) flush(nextContinues: false);
  return pages;
}

/// Copia as páginas que seguem, somando [shift] à sequência das de [serial].
void _renumber(
  RandomAccessFile source,
  int from,
  RandomAccessFile out,
  int serial,
  int shift,
) {
  final length = source.lengthSync();
  var at = from;
  while (at < length) {
    final page = _readPage(source, at);
    if (page == null) {
      // O que não for página vai como está
      source.setPositionSync(at);
      out.writeFromSync(source.readSync(length - at));
      return;
    }
    if (page.serial == serial) {
      out.writeFromSync(
        _encodePage(
          flags: page.flags,
          granule: page.granule,
          serial: page.serial,
          sequence: (page.sequence + shift) & 0xFFFFFFFF,
          lacing: page.lacing,
          data: page.data,
        ),
      );
    } else {
      out.writeFromSync(readAt(source, at, page.size));
    }
    at += page.size;
  }
}

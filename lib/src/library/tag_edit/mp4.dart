// lib/src/library/tag_edit/mp4.dart
//
// As tags do M4A: os átomos de `moov/udta/meta/ilst`. Os `----` (ReplayGain,
// MusicBrainz) e o resto passam como estão. Quando o `ilst` muda de tamanho,
// o `free` ao lado absorve; senão, o `moov` cresce e os deslocamentos das
// amostras que ficam depois dele são corrigidos.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';
import 'vorbis.dart' show applyPictureEdit;

/// O espaço livre que fica depois de uma reescrita.
const mp4Padding = 2048;

class _Atom {
  final String type;

  /// Onde começa, no arquivo, e o tamanho com o cabeçalho.
  final int offset;
  final int size;
  final int header;

  _Atom(this.type, this.offset, this.size, this.header);

  int get end => offset + size;
  int get dataStart => offset + header;
}

List<_Atom> _children(Uint8List bytes, int base, int from, int to) {
  final out = <_Atom>[];
  var at = from;
  while (at + 8 <= to) {
    final view = ByteData.sublistView(bytes);
    var size = view.getUint32(at - base);
    final type = latin1.decode(bytes.sublist(at - base + 4, at - base + 8));
    var header = 8;
    if (size == 1) {
      if (at + 16 > to) break;
      size = view.getUint64(at - base + 8);
      header = 16;
    } else if (size == 0) {
      size = to - at;
    }
    if (size < header || at + size > to) break;
    out.add(_Atom(type, at, size, header));
    at += size;
  }
  return out;
}

List<_Atom> _topLevel(RandomAccessFile file) {
  final length = file.lengthSync();
  final out = <_Atom>[];
  var at = 0;
  while (at + 8 <= length) {
    final head = readAt(file, at, 16);
    final view = ByteData.sublistView(head);
    var size = view.getUint32(0);
    final type = latin1.decode(head.sublist(4, 8));
    var header = 8;
    if (size == 1) {
      size = view.getUint64(8);
      header = 16;
    } else if (size == 0) {
      size = length - at;
    }
    if (size < header || at + size > length) break;
    out.add(_Atom(type, at, size, header));
    at += size;
  }
  return out;
}

class _Item {
  final String type;

  /// O átomo inteiro, com o cabeçalho.
  final Uint8List raw;

  _Item(this.type, this.raw);

  /// Os átomos `data`: (tipo, valor).
  List<(int, Uint8List)> get data {
    final out = <(int, Uint8List)>[];
    for (final child in _children(raw, 0, 8, raw.length)) {
      if (child.type != 'data' || child.size < 16) continue;
      final kind =
          ByteData.sublistView(raw).getUint32(child.offset + 8) & 0xFFFFFF;
      out.add((kind, Uint8List.sublistView(raw, child.offset + 16, child.end)));
    }
    return out;
  }
}

Uint8List _atom(String type, List<int> payload) {
  final out = Uint8List(8 + payload.length);
  ByteData.sublistView(out).setUint32(0, out.length);
  out.setAll(4, latin1.encode(type));
  out.setAll(8, payload);
  return out;
}

Uint8List _dataItem(String type, int kind, List<int> value) => _atom(type, [
  ..._atom('data', [0, 0, 0, kind, 0, 0, 0, 0, ...value]),
]);

_Item _textItem(String type, String value) =>
    _Item(type, _dataItem(type, 1, utf8.encode(value)));

_Item _pairItem(String type, int number, int total) => _Item(
  type,
  _dataItem(type, 0, [
    0,
    0,
    number >> 8 & 0xFF,
    number & 0xFF,
    total >> 8 & 0xFF,
    total & 0xFF,
    if (type == 'trkn') ...[0, 0],
  ]),
);

const _textAtoms = {
  TagField.title: '©nam',
  TagField.artist: '©ART',
  TagField.album: '©alb',
  TagField.albumArtist: 'aART',
  TagField.genre: '©gen',
  TagField.composer: '©wrt',
  TagField.comment: '©cmt',
  TagField.lyrics: '©lyr',
  TagField.year: '©day',
};

class _Layout {
  final _Atom moov;
  final Uint8List moovBytes;

  /// O caminho até o `ilst`, que pode faltar.
  final _Atom? udta;
  final _Atom? meta;
  final _Atom? ilst;
  final List<_Item> items;

  _Layout(
    this.moov,
    this.moovBytes,
    this.udta,
    this.meta,
    this.ilst,
    this.items,
  );
}

class Mp4Format extends TagFormat {
  const Mp4Format();

  @override
  String get name => 'M4A';

  static bool sniff(RandomAccessFile file) =>
      String.fromCharCodes(readAt(file, 4, 4)) == 'ftyp';

  _Layout _layout(RandomAccessFile file) {
    final top = _topLevel(file);
    final moov = top.where((a) => a.type == 'moov').firstOrNull;
    if (moov == null) throw malformed('moov');
    final bytes = readAt(file, moov.offset, moov.size);
    final base = moov.offset;
    _Atom? find(_Atom parent, String type, [int skip = 0]) => _children(
      bytes,
      base,
      parent.dataStart + skip,
      parent.end,
    ).where((a) => a.type == type).firstOrNull;
    final udta = find(moov, 'udta');
    final meta = udta == null ? null : find(udta, 'meta');
    // O `meta` tem versão e flags antes dos filhos
    final ilst = meta == null ? null : find(meta, 'ilst', 4);
    final items = ilst == null
        ? <_Item>[]
        : [
            for (final a in _children(bytes, base, ilst.dataStart, ilst.end))
              _Item(
                a.type,
                Uint8List.fromList(
                  bytes.sublist(a.offset - base, a.end - base),
                ),
              ),
          ];
    return _Layout(moov, bytes, udta, meta, ilst, items);
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final layout = _layout(file);
    final values = <TagField, String>{};
    for (final MapEntry(key: field, value: type) in _textAtoms.entries) {
      final item = layout.items.where((i) => i.type == type).firstOrNull;
      final texts = [
        for (final (kind, value) in item?.data ?? const <(int, Uint8List)>[])
          if (kind == 1) utf8.decode(value, allowMalformed: true).trim(),
      ].where((t) => t.isNotEmpty);
      if (texts.isNotEmpty) values[field] = texts.join(multiValueSeparator);
    }
    final year = yearOf(values[TagField.year]);
    year == null ? values.remove(TagField.year) : values[TagField.year] = year;
    for (final (type, number, total) in [
      ('trkn', TagField.trackNumber, TagField.trackTotal),
      ('disk', TagField.discNumber, TagField.discTotal),
    ]) {
      final data = layout.items.where((i) => i.type == type).firstOrNull?.data;
      final value = data?.firstOrNull?.$2;
      if (value == null || value.length < 6) continue;
      final n = value[2] << 8 | value[3];
      final t = value[4] << 8 | value[5];
      if (n > 0) values[number] = '$n';
      if (t > 0) values[total] = '$t';
    }
    TagPicture? picture;
    if (cover) {
      final covr = layout.items.where((i) => i.type == 'covr').firstOrNull;
      final first = covr?.data.firstOrNull;
      if (first != null && first.$2.isNotEmpty) {
        picture = TagPicture.sniff(Uint8List.fromList(first.$2));
      }
    }
    return EditableTags(format: name, values: values, cover: picture);
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final layout = _layout(file);
    final items = List.of(layout.items);

    void replace(Set<String> types, List<_Item> replacement) {
      var first = -1;
      for (var i = items.length - 1; i >= 0; i--) {
        if (types.contains(items[i].type)) {
          items.removeAt(i);
          first = i;
        }
      }
      items.insertAll(first < 0 ? items.length : first, replacement);
    }

    for (final MapEntry(key: field, value: type) in _textAtoms.entries) {
      if (!edit.fields.containsKey(field)) continue;
      final value = edit.valueOf(field);
      // O gênero numérico do iTunes sai junto
      replace(
        {type, if (field == TagField.genre) 'gnre'},
        [if (value != null) _textItem(type, value)],
      );
    }
    for (final (type, number, total) in [
      ('trkn', TagField.trackNumber, TagField.trackTotal),
      ('disk', TagField.discNumber, TagField.discTotal),
    ]) {
      if (!edit.fields.containsKey(number) && !edit.fields.containsKey(total)) {
        continue;
      }
      final n = int.tryParse(edit.valueOf(number) ?? '') ?? 0;
      final t = int.tryParse(edit.valueOf(total) ?? '') ?? 0;
      replace(
        {type},
        [
          if (n > 0 || t > 0)
            _pairItem(type, n.clamp(0, 0xFFFF), t.clamp(0, 0xFFFF)),
        ],
      );
    }
    if (edit.coverChanged) {
      final covr = items.where((i) => i.type == 'covr').firstOrNull;
      final pictures = [
        for (final (_, value) in covr?.data ?? const <(int, Uint8List)>[])
          value,
      ];
      // No `covr` não há tipo: a primeira é a que aparece
      final changed = applyPictureEdit<Uint8List>(
        pictures,
        (_) => 3,
        edit,
        (p) => p.bytes,
      );
      replace(
        {'covr'},
        [
          if (changed.isNotEmpty)
            _Item(
              'covr',
              _atom('covr', [
                for (final value in changed)
                  ..._atom('data', [
                    0,
                    0,
                    0,
                    pictureMime(value) == 'image/png' ? 14 : 13,
                    0,
                    0,
                    0,
                    0,
                    ...value,
                  ]),
              ]),
            ),
        ],
      );
    }
    final ilstPayload = BytesBuilder(copy: false);
    for (final item in items) {
      ilstPayload.add(item.raw);
    }
    final ilst = _atom('ilst', ilstPayload.takeBytes());
    return _plan(file, layout, ilst);
  }

  TagWritePlan _plan(RandomAccessFile file, _Layout layout, Uint8List ilst) {
    final base = layout.moov.offset;
    final bytes = layout.moovBytes;

    // Com o caminho inteiro, tenta o `free` logo depois do `ilst`
    final oldIlst = layout.ilst;
    if (oldIlst != null && oldIlst.header == 8) {
      final delta = ilst.length - oldIlst.size;
      final after = _children(
        bytes,
        base,
        oldIlst.end,
        layout.meta!.end,
      ).firstOrNull;
      if (delta == 0) {
        return TagWritePlan([Splice(oldIlst.offset, oldIlst.end, ilst)]);
      }
      if (after != null &&
          (after.type == 'free' || after.type == 'skip') &&
          after.header == 8) {
        final freeSize = after.size - delta;
        if (freeSize >= 8) {
          return TagWritePlan([
            Splice(
              oldIlst.offset,
              after.end,
              Uint8List.fromList([
                ...ilst,
                ..._atom('free', Uint8List(freeSize - 8)),
              ]),
            ),
          ]);
        }
      }
    }

    // Senão, o `moov` cresce, com espaço para a próxima vez
    final padded = Uint8List.fromList([
      ...ilst,
      ..._atom('free', Uint8List(mp4Padding)),
    ]);
    final Uint8List moov;
    final int insertAt;
    if (oldIlst != null) {
      moov = _spliceTree(
        bytes,
        base,
        [layout.moov, layout.udta!, layout.meta!],
        oldIlst,
        padded,
      );
      insertAt = oldIlst.offset;
    } else if (layout.meta != null) {
      final meta = layout.meta!;
      moov = _spliceTree(
        bytes,
        base,
        [layout.moov, layout.udta!],
        meta,
        _meta(padded),
      );
      insertAt = meta.offset;
    } else if (layout.udta != null) {
      final udta = layout.udta!;
      final empty = _Atom('', udta.end, 0, 0);
      moov = _spliceTree(
        bytes,
        base,
        [layout.moov, udta],
        empty,
        _meta(padded),
      );
      insertAt = udta.end;
    } else {
      final empty = _Atom('', layout.moov.end, 0, 0);
      moov = _spliceTree(
        bytes,
        base,
        [layout.moov],
        empty,
        _atom('udta', _meta(padded)),
      );
      insertAt = layout.moov.end;
    }
    final delta = moov.length - layout.moov.size;
    _fixOffsets(moov, insertAt - base, delta, base);
    return TagWritePlan([Splice(layout.moov.offset, layout.moov.end, moov)]);
  }

  Uint8List _meta(Uint8List ilst) {
    final hdlr = _atom('hdlr', [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      ...'mdir'.codeUnits,
      ...'appl'.codeUnits,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
    return _atom('meta', [0, 0, 0, 0, ...hdlr, ...ilst]);
  }
}

/// Troca [old] (ou insere no fim dele, se o tamanho for 0) por [replacement]
/// dentro do `moov`, somando a diferença ao tamanho de cada átomo de [path].
Uint8List _spliceTree(
  Uint8List moov,
  int base,
  List<_Atom> path,
  _Atom old,
  Uint8List replacement,
) {
  final delta = replacement.length - old.size;
  final out = Uint8List.fromList([
    ...moov.sublist(0, old.offset - base),
    ...replacement,
    ...moov.sublist(old.end - base),
  ]);
  final view = ByteData.sublistView(out);
  for (final atom in path) {
    final at = atom.offset - base;
    if (atom.header == 16) {
      view.setUint64(at + 8, atom.size + delta);
    } else {
      final size = atom.size + delta;
      if (size > 0xFFFFFFFF) throw malformed('moov grande demais');
      view.setUint32(at, size);
    }
  }
  return out;
}

/// Os `stco` e `co64` apontam para o arquivo: o que estava depois do ponto em
/// que o `moov` cresceu anda [delta]. Num `moov` fragmentado, os `moof` também
/// apontariam: fica de fora.
void _fixOffsets(Uint8List moov, int insertAt, int delta, int base) {
  if (delta == 0) return;
  final view = ByteData.sublistView(moov);
  void walk(int from, int to) {
    for (final atom in _children(moov, 0, from, to)) {
      switch (atom.type) {
        case 'trak' || 'mdia' || 'minf' || 'stbl':
          walk(atom.dataStart, atom.end);
        case 'mvex':
          throw const TagWriteException(
            TagWriteFailure.unsupportedFormat,
            'mp4 fragmentado',
          );
        case 'stco':
          final count = view.getUint32(atom.dataStart + 4);
          for (var i = 0; i < count; i++) {
            final at = atom.dataStart + 8 + i * 4;
            if (at + 4 > atom.end) break;
            final value = view.getUint32(at);
            if (value >= base + insertAt) {
              final moved = value + delta;
              if (moved > 0xFFFFFFFF) throw malformed('stco');
              view.setUint32(at, moved);
            }
          }
        case 'co64':
          final count = view.getUint32(atom.dataStart + 4);
          for (var i = 0; i < count; i++) {
            final at = atom.dataStart + 8 + i * 8;
            if (at + 8 > atom.end) break;
            final value = view.getUint64(at);
            if (value >= base + insertAt) view.setUint64(at, value + delta);
          }
      }
    }
  }

  walk(8, moov.length);
}

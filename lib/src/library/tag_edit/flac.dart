// lib/src/library/tag_edit/flac.dart
//
// As tags do FLAC: o bloco de comentários (4) e os de imagem (6). O resto dos
// blocos e o áudio passam como estão.
import 'dart:io';
import 'dart:typed_data';

import 'id3v2.dart';
import 'safe_write.dart';
import 'tag_edit.dart';
import 'tag_format.dart';
import 'vorbis.dart';

const _streamInfo = 0;
const _padding = 1;
const _comment = 4;
const _picture = 6;

/// O espaço livre que fica depois de uma reescrita, para a próxima caber.
const flacPadding = 8192;
const _maxBlock = 0xFFFFFF;

class _Block {
  final int type;
  final Uint8List data;

  _Block(this.type, this.data);
}

class _FlacLayout {
  /// Onde começa o `fLaC` (depois de um ID3v2, se houver).
  final int start;
  final int audioStart;
  final List<_Block> blocks;

  _FlacLayout(this.start, this.audioStart, this.blocks);
}

class FlacFormat extends TagFormat {
  const FlacFormat();

  @override
  String get name => 'FLAC';

  static bool sniff(RandomAccessFile file) {
    final start = id3v2Size(file);
    return String.fromCharCodes(readAt(file, start, 4)) == 'fLaC';
  }

  _FlacLayout _layout(RandomAccessFile file, {bool pictures = true}) {
    final start = id3v2Size(file);
    if (String.fromCharCodes(readAt(file, start, 4)) != 'fLaC') {
      throw malformed('flac');
    }
    final length = file.lengthSync();
    var at = start + 4;
    final blocks = <_Block>[];
    var last = false;
    while (!last) {
      final header = readAt(file, at, 4);
      if (header.length < 4) throw malformed('flac block');
      last = header[0] & 0x80 != 0;
      final type = header[0] & 0x7F;
      final size = header[1] << 16 | header[2] << 8 | header[3];
      if (at + 4 + size > length) throw malformed('flac block size');
      final data = type == _padding || (type == _picture && !pictures)
          ? Uint8List(0)
          : readAt(file, at + 4, size);
      blocks.add(_Block(type, data));
      at += 4 + size;
    }
    return _FlacLayout(start, at, blocks);
  }

  @override
  EditableTags read(RandomAccessFile file, {bool cover = true}) {
    final layout = _layout(file, pictures: cover);
    final comments = layout.blocks.where((b) => b.type == _comment).firstOrNull;
    final values = comments == null
        ? const <TagField, String>{}
        : vorbisValues(VorbisComments.parse(comments.data).$1);
    TagPicture? picture;
    if (cover) {
      final pictures = [
        for (final b in layout.blocks)
          if (b.type == _picture) FlacPicture.parse(b.data),
      ];
      final shown = shownPicture([for (final p in pictures) p.type]);
      if (shown != null) picture = pictures[shown].picture;
    }
    return EditableTags(format: name, values: values, cover: picture);
  }

  @override
  TagWritePlan plan(RandomAccessFile file, TagEdit edit) {
    final layout = _layout(file);
    final blocks = layout.blocks.where((b) => b.type != _padding).toList();

    final commentAt = blocks.indexWhere((b) => b.type == _comment);
    final comments = commentAt < 0
        ? VorbisComments('Psito Player', [])
        : VorbisComments.parse(blocks[commentAt].data).$1;
    applyVorbisFields(comments, edit);
    final commentBlock = _Block(_comment, comments.encode());
    if (commentAt < 0) {
      final info = blocks.indexWhere((b) => b.type == _streamInfo);
      blocks.insert(info + 1, commentBlock);
    } else {
      blocks[commentAt] = commentBlock;
    }

    if (edit.coverChanged) {
      final pictures = [
        for (final b in blocks)
          if (b.type == _picture) FlacPicture.parse(b.data),
      ];
      final changed = applyPictureEdit(
        pictures,
        (p) => p.type,
        edit,
        FlacPicture.front,
      );
      final firstPicture = blocks.indexWhere((b) => b.type == _picture);
      blocks.removeWhere((b) => b.type == _picture);
      final at = firstPicture < 0
          ? blocks.indexWhere((b) => b.type == _comment) + 1
          : firstPicture.clamp(0, blocks.length);
      blocks.insertAll(at, [
        for (final p in changed) _Block(_picture, p.encode()),
      ]);
    }

    for (final b in blocks) {
      if (b.data.length > _maxBlock) {
        throw const TagWriteException(
          TagWriteFailure.malformed,
          'bloco grande demais para o FLAC',
        );
      }
    }
    final room = layout.audioStart - (layout.start + 4);
    final needed = blocks.fold(0, (sum, b) => sum + 4 + b.data.length);
    int padding;
    if (needed == room) {
      padding = -1;
    } else if (needed + 4 <= room) {
      padding = room - needed - 4;
    } else {
      padding = flacPadding;
    }
    if (padding >= 0) blocks.add(_Block(_padding, Uint8List(padding)));

    final out = BytesBuilder(copy: false);
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final size = b.data.length;
      out.add([
        (i == blocks.length - 1 ? 0x80 : 0) | b.type,
        size >> 16 & 0xFF,
        size >> 8 & 0xFF,
        size & 0xFF,
      ]);
      out.add(b.data);
    }
    return TagWritePlan([
      Splice(layout.start + 4, layout.audioStart, out.takeBytes()),
    ]);
  }
}

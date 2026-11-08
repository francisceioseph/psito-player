// lib/src/library/tag_edit/safe_write.dart
//
// Trocar pedaços de um arquivo sem nunca deixar ele pela metade.
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'tag_edit.dart';

/// Troca os bytes de [start] até [end] por [bytes].
class Splice {
  final int start;
  final int end;
  final Uint8List bytes;

  const Splice(this.start, this.end, this.bytes);

  bool get sameSize => end - start == bytes.length;
}

/// Reescreve o que vem depois do último pedaço, como o Ogg, que renumera as
/// páginas. Lê de [source] a partir de [from], até o fim, e escreve em [out].
typedef TailRewrite = void Function(
  RandomAccessFile source,
  int from,
  RandomAccessFile out,
);

const _copyChunk = 1 << 20;

/// Aplica [splices] (em ordem e sem sobreposição) a [file].
///
/// Quando todos têm o mesmo tamanho do que trocam e não há [tail], grava no
/// lugar, só nesses bytes: não muda dono, permissão nem o áudio. Senão, ou com
/// [forceRewrite], monta uma cópia ao lado, com o modo do original, e renomeia
/// por cima. [verify] confere o resultado antes de valer, e lança se não bate.
void applySplices(
  File file,
  List<Splice> splices, {
  TailRewrite? tail,
  bool forceRewrite = false,
  void Function(File written)? verify,
}) {
  final inPlace =
      !forceRewrite && tail == null && splices.every((s) => s.sameSize);
  try {
    if (inPlace) {
      _writeInPlace(file, splices, verify);
    } else {
      _rewrite(file, splices, tail, verify);
    }
  } on FileSystemException catch (e) {
    throw failureOf(e);
  }
}

void _writeInPlace(
  File file,
  List<Splice> splices,
  void Function(File)? verify,
) {
  final out = file.openSync(mode: FileMode.append);
  final old = <Uint8List>[];
  try {
    for (final splice in splices) {
      out.setPositionSync(splice.start);
      old.add(out.readSync(splice.end - splice.start));
    }
    for (final splice in splices) {
      out.setPositionSync(splice.start);
      out.writeFromSync(splice.bytes);
    }
    out.flushSync();
    if (verify != null) {
      try {
        verify(file);
      } catch (_) {
        // O que estava antes volta: no lugar não há cópia para jogar fora
        for (var i = 0; i < splices.length; i++) {
          out.setPositionSync(splices[i].start);
          out.writeFromSync(old[i]);
        }
        out.flushSync();
        rethrow;
      }
    }
  } finally {
    out.closeSync();
  }
}

void _rewrite(
  File file,
  List<Splice> splices,
  TailRewrite? tail,
  void Function(File)? verify,
) {
  final mode = file.statSync().mode & 0xFFF;
  final temp = File(
    p.join(file.parent.path, '.${p.basename(file.path)}.psito-tmp'),
  );
  final source = file.openSync();
  RandomAccessFile? out;
  var renamed = false;
  try {
    out = temp.openSync(mode: FileMode.write);
    var at = 0;
    for (final splice in splices) {
      _copy(source, at, splice.start, out);
      out.writeFromSync(splice.bytes);
      at = splice.end;
    }
    if (tail != null) {
      tail(source, at, out);
    } else {
      _copy(source, at, source.lengthSync(), out);
    }
    out.flushSync();
    out.closeSync();
    out = null;
    _chmod(temp.path, mode);
    verify?.call(temp);
    temp.renameSync(file.path);
    renamed = true;
  } finally {
    out?.closeSync();
    source.closeSync();
    if (!renamed && temp.existsSync()) temp.deleteSync();
  }
}

void _copy(RandomAccessFile source, int from, int to, RandomAccessFile out) {
  source.setPositionSync(from);
  var left = to - from;
  while (left > 0) {
    final chunk = source.readSync(left < _copyChunk ? left : _copyChunk);
    if (chunk.isEmpty) break;
    out.writeFromSync(chunk);
    left -= chunk.length;
  }
}

typedef _ChmodC = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);

_ChmodDart? _chmodFn;

/// O `dart:io` não muda o modo de um arquivo.
void _chmod(String path, int mode) {
  final chmod = _chmodFn ??= DynamicLibrary.process()
      .lookupFunction<_ChmodC, _ChmodDart>('chmod');
  final native = path.toNativeUtf8();
  try {
    if (chmod(native, mode) != 0) {
      throw FileSystemException('chmod falhou', path);
    }
  } finally {
    malloc.free(native);
  }
}

/// O motivo de uma falha do sistema de arquivos, para a tela.
TagWriteException failureOf(FileSystemException e) {
  return switch (e.osError?.errorCode) {
    30 => TagWriteException(TagWriteFailure.readOnlyDisk, e.message),
    1 || 13 => TagWriteException(TagWriteFailure.noPermission, e.message),
    2 || 19 || 6 => TagWriteException(TagWriteFailure.missing, e.message),
    28 || 122 => TagWriteException(TagWriteFailure.noSpace, e.message),
    _ => TagWriteException(TagWriteFailure.malformed, '$e'),
  };
}

/// Se dá para gravar em [file], sem mudar nada nele: abre para escrita e fecha.
Writable writableState(File file) {
  if (!file.existsSync()) return Writable.missing;
  try {
    file.openSync(mode: FileMode.append).closeSync();
    return Writable.yes;
  } on FileSystemException catch (e) {
    return switch (failureOf(e).reason) {
      TagWriteFailure.readOnlyDisk => Writable.readOnlyDisk,
      TagWriteFailure.missing => Writable.missing,
      _ => Writable.noPermission,
    };
  }
}

/// Lê [length] bytes a partir de [at].
Uint8List readAt(RandomAccessFile file, int at, int length) {
  file.setPositionSync(at);
  return file.readSync(length);
}

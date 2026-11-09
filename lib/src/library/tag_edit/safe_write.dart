// lib/src/library/tag_edit/safe_write.dart
//
// Trocar pedaços de um arquivo sem nunca deixar ele pela metade.
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../platform/desktop_platform.dart';
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

/// O antivírus e a prévia do Explorer seguram um arquivo por instantes.
const _replaceTries = 5;
const _replaceWait = Duration(milliseconds: 100);

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
  RandomAccessFile? source = file.openSync();
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
    desktopPlatform.restoreFileMode(temp.path, mode);
    verify?.call(temp);
    // No Windows, nem o próprio player pode estar com ele aberto
    source.closeSync();
    source = null;
    _replace(temp, file);
    renamed = true;
  } finally {
    out?.closeSync();
    source?.closeSync();
    if (!renamed && temp.existsSync()) temp.deleteSync();
  }
}

void _replace(File temp, File file) {
  for (var attempt = 1; ; attempt++) {
    try {
      temp.renameSync(file.path);
      return;
    } on FileSystemException catch (e) {
      if (!_heldOpen(e, file)) rethrow;
      if (attempt == _replaceTries) {
        throw TagWriteException(TagWriteFailure.inUse, e.message);
      }
      sleep(_replaceWait);
    }
  }
}

/// O Windows dá "acesso negado" ao substituir um arquivo aberto. Se dá para
/// escrever nele, a permissão não é o motivo.
bool _heldOpen(FileSystemException e, File file) {
  if (!desktopPlatform.openFilesBlockReplace) return false;
  final code = e.osError?.errorCode;
  return switch (code == null ? null : desktopPlatform.fileProblem(code)) {
    FileProblem.inUse => true,
    FileProblem.noPermission => writableState(file) == Writable.yes,
    _ => false,
  };
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

/// O motivo de uma falha do sistema de arquivos, para a tela.
TagWriteException failureOf(FileSystemException e) {
  final code = e.osError?.errorCode;
  return switch (code == null ? null : desktopPlatform.fileProblem(code)) {
    FileProblem.readOnlyDisk => TagWriteException(
      TagWriteFailure.readOnlyDisk,
      e.message,
    ),
    FileProblem.noPermission => TagWriteException(
      TagWriteFailure.noPermission,
      e.message,
    ),
    FileProblem.missing => TagWriteException(
      TagWriteFailure.missing,
      e.message,
    ),
    FileProblem.noSpace => TagWriteException(
      TagWriteFailure.noSpace,
      e.message,
    ),
    FileProblem.inUse => TagWriteException(TagWriteFailure.inUse, e.message),
    FileProblem.otherDisk ||
    null => TagWriteException(TagWriteFailure.malformed, '$e'),
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

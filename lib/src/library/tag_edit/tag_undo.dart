// lib/src/library/tag_edit/tag_undo.dart
//
// Gravar várias faixas de uma vez, e o diário que desfaz.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'tag_edit.dart';
import 'tag_files.dart';

/// Quantas gravações o diário guarda, e por quanto tempo.
const tagUndoKeep = 20;
const tagUndoMaxAge = Duration(days: 7);

/// Uma faixa gravada: como desfazer, e como o arquivo ficou, para não desfazer
/// por cima de uma mudança de outro programa.
class TagUndoEntry {
  final String path;
  final int size;
  final int mtimeMs;
  final TagEdit inverse;

  const TagUndoEntry(this.path, this.size, this.mtimeMs, this.inverse);

  Map<String, Object?> toJson() => {
    'path': path,
    'size': size,
    'mtime': mtimeMs,
    'inverse': inverse.toJson(),
  };

  factory TagUndoEntry.fromJson(Map<String, Object?> json) => TagUndoEntry(
    json['path'] as String,
    json['size'] as int,
    json['mtime'] as int,
    TagEdit.fromJson(json['inverse'] as Map<String, Object?>),
  );

  /// O arquivo continua como a gravação deixou.
  bool get untouched {
    final stat = File(path).statSync();
    return stat.type != FileSystemEntityType.notFound &&
        stat.size == size &&
        stat.modified.millisecondsSinceEpoch == mtimeMs;
  }
}

/// O resultado de gravar uma faixa, que atravessa isolates.
sealed class TagFileResult {
  final String path;

  const TagFileResult(this.path);
}

class TagFileWritten extends TagFileResult {
  final TagUndoEntry undo;

  const TagFileWritten(super.path, this.undo);
}

class TagFileFailed extends TagFileResult {
  final TagWriteFailure reason;

  const TagFileFailed(super.path, this.reason);
}

/// Grava uma faixa e diz como desfazer. Não lança.
TagFileResult writeTagFile(
  String path,
  TagEdit edit, {
  bool forceRewrite = false,
}) {
  try {
    final before = writeTags(path, edit, forceRewrite: forceRewrite);
    final stat = File(path).statSync();
    return TagFileWritten(
      path,
      TagUndoEntry(
        path,
        stat.size,
        stat.modified.millisecondsSinceEpoch,
        edit.completedWith(before).inverseOf(before),
      ),
    );
  } on TagWriteException catch (e) {
    return TagFileFailed(path, e.reason);
  } catch (_) {
    return TagFileFailed(path, TagWriteFailure.malformed);
  }
}

/// Desfaz uma faixa, se ela não mudou desde a gravação.
TagFileResult undoTagFile(TagUndoEntry entry, {bool forceRewrite = false}) {
  if (!File(entry.path).existsSync()) {
    return TagFileFailed(entry.path, TagWriteFailure.missing);
  }
  if (!entry.untouched) {
    return TagFileFailed(entry.path, TagWriteFailure.changedMeanwhile);
  }
  return writeTagFile(entry.path, entry.inverse, forceRewrite: forceRewrite);
}

/// O diário, um JSON por gravação, em [dir].
class TagUndoJournal {
  final String dir;

  const TagUndoJournal(this.dir);

  File _file(String id) => File(p.join(dir, '$id.json'));

  /// Guarda e devolve o nome da gravação. [now] em milissegundos.
  String record(List<TagUndoEntry> entries, int now) {
    Directory(dir).createSync(recursive: true);
    var id = '$now';
    var n = 1;
    while (_file(id).existsSync()) {
      id = '$now-${n++}';
    }
    _file(id).writeAsStringSync(
      jsonEncode({
        'at': now,
        'entries': [for (final e in entries) e.toJson()],
      }),
    );
    prune(now);
    return id;
  }

  List<TagUndoEntry>? load(String id) {
    final file = _file(id);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      return [
        for (final e in json['entries'] as List<Object?>)
          TagUndoEntry.fromJson(e as Map<String, Object?>),
      ];
    } on FormatException {
      return null;
    }
  }

  void delete(String id) {
    final file = _file(id);
    if (file.existsSync()) file.deleteSync();
  }

  /// Tira o que passou de [tagUndoKeep] ou de [tagUndoMaxAge].
  void prune(int now) {
    final folder = Directory(dir);
    if (!folder.existsSync()) return;
    final files =
        folder
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    final oldest = now - tagUndoMaxAge.inMilliseconds;
    for (var i = 0; i < files.length; i++) {
      final at = int.tryParse(
        p.basenameWithoutExtension(files[i].path).split('-').first,
      );
      if (i >= tagUndoKeep || (at != null && at < oldest)) {
        files[i].deleteSync();
      }
    }
  }
}

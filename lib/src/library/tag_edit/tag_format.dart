// lib/src/library/tag_edit/tag_format.dart
//
// O que cada estrutura de tag sabe fazer.
import 'dart:io';

import 'safe_write.dart';
import 'tag_edit.dart';

/// O que gravar: os pedaços trocados e, no Ogg, o resto renumerado.
class TagWritePlan {
  final List<Splice> splices;
  final TailRewrite? tail;

  const TagWritePlan(this.splices, {this.tail});
}

abstract class TagFormat {
  const TagFormat();

  /// O nome do formato para a tela.
  String get name;

  /// Lança [TagWriteException] se a estrutura não for a esperada.
  EditableTags read(RandomAccessFile file, {bool cover = true});

  /// [edit] já vem completado ([TagEdit.completedWith]).
  TagWritePlan plan(RandomAccessFile file, TagEdit edit);
}

TagWriteException malformed(String what) =>
    TagWriteException(TagWriteFailure.malformed, what);

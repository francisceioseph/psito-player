// lib/src/library/tag_edit/tag_edit.dart
//
// O que o editor de tags lê e grava, igual para todos os formatos.
import 'dart:convert';
import 'dart:typed_data';

/// Os campos que o editor mostra e grava.
enum TagField {
  title,
  artist,
  album,
  albumArtist,
  trackNumber,
  trackTotal,
  discNumber,
  discTotal,
  year,
  genre,
  composer,
  comment,
  lyrics,
}

/// Os campos que são números inteiros.
const numericTagFields = {
  TagField.trackNumber,
  TagField.trackTotal,
  TagField.discNumber,
  TagField.discTotal,
  TagField.year,
};

/// Uma imagem embutida.
class TagPicture {
  final Uint8List bytes;
  final String mime;

  const TagPicture(this.bytes, this.mime);

  /// O tipo pelo começo do arquivo, ou JPEG.
  factory TagPicture.sniff(Uint8List bytes) =>
      TagPicture(bytes, pictureMime(bytes));

  Map<String, Object?> toJson() => {
    'mime': mime,
    'bytes': base64.encode(bytes),
  };

  factory TagPicture.fromJson(Map<String, Object?> json) => TagPicture(
    base64.decode(json['bytes'] as String),
    json['mime'] as String,
  );

  @override
  bool operator ==(Object other) =>
      other is TagPicture &&
      other.mime == mime &&
      _sameBytes(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(mime, bytes.length);
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String pictureMime(Uint8List bytes) {
  bool starts(List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  if (starts(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (starts(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (bytes.length >= 12 &&
      starts(const [0x52, 0x49, 0x46, 0x46]) &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return 'image/jpeg';
}

/// Uma mudança: só o que está aqui é tocado. Um valor `null` (ou vazio) limpa o
/// campo. A capa só muda com [coverChanged], e [cover] nulo então a tira.
class TagEdit {
  final Map<TagField, String?> fields;
  final bool coverChanged;
  final TagPicture? cover;

  const TagEdit({
    this.fields = const {},
    this.coverChanged = false,
    this.cover,
  });

  bool get isEmpty => fields.isEmpty && !coverChanged;

  /// O valor que fica no campo, sem os espaços das pontas; vazio é nulo.
  String? valueOf(TagField field) {
    final value = fields[field]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Faixa e total andam juntos, e disco e total também: em vários formatos são
  /// um campo só ("3/12"), e gravar um sem o outro perderia o que não mudou.
  TagEdit completedWith(EditableTags before) {
    final out = Map.of(fields);
    void pair(TagField a, TagField b) {
      if (!out.containsKey(a) && !out.containsKey(b)) return;
      out.putIfAbsent(a, () => before.values[a]);
      out.putIfAbsent(b, () => before.values[b]);
    }

    pair(TagField.trackNumber, TagField.trackTotal);
    pair(TagField.discNumber, TagField.discTotal);
    return TagEdit(fields: out, coverChanged: coverChanged, cover: cover);
  }

  /// O que desfaz esta mudança num arquivo que estava como [before].
  TagEdit inverseOf(EditableTags before) => TagEdit(
    fields: {for (final field in fields.keys) field: before.values[field]},
    coverChanged: coverChanged,
    cover: coverChanged ? before.cover : null,
  );

  Map<String, Object?> toJson() => {
    'fields': {for (final e in fields.entries) e.key.name: e.value},
    if (coverChanged) 'cover': cover?.toJson(),
    'coverChanged': coverChanged,
  };

  factory TagEdit.fromJson(Map<String, Object?> json) {
    final fields = json['fields'] as Map<String, Object?>;
    final cover = json['cover'] as Map<String, Object?>?;
    return TagEdit(
      fields: {
        for (final e in fields.entries)
          TagField.values.byName(e.key): e.value as String?,
      },
      coverChanged: json['coverChanged'] as bool? ?? false,
      cover: cover == null ? null : TagPicture.fromJson(cover),
    );
  }
}

/// Se dá para gravar, e por que não.
enum Writable { yes, unsupportedFormat, readOnlyDisk, noPermission, missing }

/// As tags de um arquivo, como o editor mostra.
class EditableTags {
  /// O nome do formato para a tela: FLAC, MP3, Ogg Vorbis...
  final String format;
  final Map<TagField, String> values;
  final TagPicture? cover;
  final Writable writable;

  const EditableTags({
    required this.format,
    this.values = const {},
    this.cover,
    this.writable = Writable.yes,
  });

  EditableTags withWritable(Writable value) => EditableTags(
    format: format,
    values: values,
    cover: cover,
    writable: value,
  );

  /// Se [edit] já está valendo aqui: o que a conferência depois de gravar pede.
  bool matches(TagEdit edit) {
    for (final field in edit.fields.keys) {
      final want = edit.valueOf(field);
      final have = values[field];
      if (numericTagFields.contains(field)) {
        if (int.tryParse(want ?? '') != int.tryParse(have ?? '')) return false;
      } else if (want != have) {
        return false;
      }
    }
    if (edit.coverChanged && edit.cover != cover) return false;
    return true;
  }
}

/// A gravação não deu certo.
class TagWriteException implements Exception {
  final TagWriteFailure reason;
  final String detail;

  const TagWriteException(this.reason, [this.detail = '']);

  @override
  String toString() => 'TagWriteException(${reason.name}: $detail)';
}

enum TagWriteFailure {
  unsupportedFormat,
  readOnlyDisk,
  noPermission,
  missing,
  noSpace,
  changedMeanwhile,
  verifyFailed,
  malformed,
}

/// Vários valores de um campo viram um texto só.
const multiValueSeparator = '; ';

/// "3/12" em número e total. Os dois podem faltar.
(String?, String?) splitPair(String? value) {
  if (value == null) return (null, null);
  final parts = value.split('/');
  String? clean(String s) {
    final n = int.tryParse(s.trim());
    return n == null || n <= 0 ? null : '$n';
  }

  return (clean(parts[0]), parts.length > 1 ? clean(parts[1]) : null);
}

/// Número e total num campo só, como o ID3 e o APE guardam. Sem número, nada.
String? joinPair(String? number, String? total) {
  if (number == null) return null;
  return total == null ? number : '$number/$total';
}

/// O ano de uma data como "1997-05-01" ou "1997".
String? yearOf(String? value) {
  final match = RegExp(r'^\s*(\d{4})').firstMatch(value ?? '');
  return match?.group(1);
}

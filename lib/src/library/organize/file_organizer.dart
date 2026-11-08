// lib/src/library/organize/file_organizer.dart
//
// Pôr os arquivos nos lugares que as tags dizem, ou copiar para outra pasta: o
// padrão, os nomes que o disco aceita, a prévia e o trabalho em cada arquivo.
// Sem tela e sem banco.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../scanner.dart';
import '../tag_edit/safe_write.dart';
import '../tag_edit/tag_edit.dart';
import '../tag_edit/tag_undo.dart';

const defaultOrganizePattern =
    '{albumArtist}/{year} - {album}/{disc}{track} {title}';

/// O que pode entrar no padrão.
enum OrganizeToken {
  albumArtist,
  artist,
  album,
  year,
  disc,
  track,
  title,
  genre,
}

final _tokenPattern = RegExp(r'\{([^{}]*)\}');

/// Um padrão vale se só usa o que existe, diz o título (senão as faixas de uma
/// pasta teriam o mesmo nome) e fica dentro da pasta.
bool organizePatternValid(String pattern) {
  final names = OrganizeToken.values.map((t) => t.name).toSet();
  final used = [for (final m in _tokenPattern.allMatches(pattern)) m[1]!];
  if (used.any((name) => !names.contains(name))) return false;
  if (!used.contains(OrganizeToken.title.name)) return false;
  final text = pattern.replaceAll(_tokenPattern, '');
  if (text.contains('{') || text.contains('}')) return false;
  return !pattern.startsWith('/') &&
      !pattern.endsWith('/') &&
      !pattern.split('/').any((s) => s.trim().isEmpty || s.trim() == '..');
}

/// Uma faixa, com o que o padrão pode pedir.
class OrganizeItem {
  final String path;

  /// A pasta da biblioteca de onde ela é.
  final String root;
  final String title;
  final String artist;
  final String albumArtist;
  final String album;
  final int? trackNumber;
  final int? discNumber;

  /// O álbum tem mais de um disco: o número dele entra no nome.
  final bool multiDisc;
  final int? year;
  final String? genre;

  const OrganizeItem({
    required this.path,
    required this.root,
    required this.title,
    this.artist = '',
    this.albumArtist = '',
    this.album = '',
    this.trackNumber,
    this.discNumber,
    this.multiDisc = false,
    this.year,
    this.genre,
  });
}

const _strictChars = r'\:*?"<>|';

/// O que um disco FAT, exFAT ou NTFS recusa também fica de fora.
String _cleanValue(String value, {required bool strict}) {
  final out = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final bad =
        rune < 0x20 || char == '/' || (strict && _strictChars.contains(char));
    out.write(bad ? '_' : char);
  }
  return out.toString();
}

/// Sem pontos na frente (a pasta sumiria) nem pontos e espaços no fim (o FAT
/// corta), e cabendo nos 255 bytes de um nome.
String safeFileName(
  String name, {
  required String unknown,
  String extension = '',
}) {
  var clean = name.trim().replaceFirst(RegExp(r'^[.\s]+'), '');
  clean = clean.replaceFirst(RegExp(r'[.\s]+$'), '');
  if (clean.isEmpty) clean = unknown;
  final room = 255 - utf8.encode(extension).length;
  if (utf8.encode(clean).length > room) {
    final buffer = StringBuffer();
    var used = 0;
    for (final rune in clean.runes) {
      final char = String.fromCharCode(rune);
      used += utf8.encode(char).length;
      if (used > room) break;
      buffer.write(char);
    }
    clean = buffer.toString().replaceFirst(RegExp(r'[.\s]+$'), '');
  }
  return '$clean$extension';
}

final _edges = RegExp(r'^[\s\-_.,]+|[\s\-_.,]+$');

/// O caminho que [pattern] dá para [item], relativo à pasta, sem a extensão.
List<String> expandOrganizePattern(
  String pattern,
  OrganizeItem item, {
  required String unknown,
  required bool strict,
}) {
  String value(OrganizeToken token) => switch (token) {
    OrganizeToken.albumArtist =>
      item.albumArtist.isNotEmpty
          ? item.albumArtist
          : item.artist.isNotEmpty
          ? item.artist
          : unknown,
    OrganizeToken.artist => item.artist.isNotEmpty ? item.artist : unknown,
    OrganizeToken.album => item.album.isNotEmpty ? item.album : unknown,
    OrganizeToken.year => item.year == null ? '' : '${item.year}',
    OrganizeToken.disc =>
      item.multiDisc && item.discNumber != null ? '${item.discNumber}-' : '',
    OrganizeToken.track =>
      item.trackNumber == null ? '' : '${item.trackNumber}'.padLeft(2, '0'),
    OrganizeToken.title => item.title.isNotEmpty ? item.title : unknown,
    OrganizeToken.genre => item.genre ?? '',
  };

  final segments = <String>[];
  for (final segment in pattern.split('/')) {
    var empty = false;
    final values = <String>[];
    // Os valores ficam guardados enquanto se limpa só o texto do próprio padrão
    var text = segment.replaceAllMapped(_tokenPattern, (m) {
      final v = value(OrganizeToken.values.byName(m[1]!));
      if (v.isEmpty) {
        empty = true;
        return '';
      }
      values.add(_cleanValue(v, strict: strict));
      return '\u{1}';
    });
    // "{year} - {album}" sem ano não deixa o " - " sobrando
    if (empty) text = text.replaceAll(_edges, '');
    text = _cleanValue(text.replaceAll('\u{1}', '\u{FFFF}'), strict: strict);
    var next = 0;
    segments.add(text.replaceAllMapped('\u{FFFF}', (_) => values[next++]));
  }
  return segments;
}

enum FileMoveKind { track, sidecar, cover }

/// Por que um arquivo fica onde está.
enum MoveProblem { sameTarget, targetExists, playing, noSpace }

class FileMove {
  final String from;
  final String to;
  final FileMoveKind kind;
  final int size;
  final MoveProblem? problem;

  /// Quem é a faixa de um arquivo que vai junto.
  final String? track;

  const FileMove({
    required this.from,
    required this.to,
    required this.kind,
    required this.size,
    this.problem,
    this.track,
  });

  /// O caminho de volta.
  FileMove get reversed =>
      FileMove(from: to, to: from, kind: kind, size: size, track: track);

  Map<String, Object?> toJson() => {
    'from': from,
    'to': to,
    'kind': kind.name,
    'size': size,
    'track': track,
  };

  factory FileMove.fromJson(Map<String, Object?> json) => FileMove(
    from: json['from'] as String,
    to: json['to'] as String,
    kind: FileMoveKind.values.byName(json['kind'] as String),
    size: json['size'] as int,
    track: json['track'] as String?,
  );

  FileMove withProblem(MoveProblem problem) => FileMove(
    from: from,
    to: to,
    kind: kind,
    size: size,
    problem: problem,
    track: track,
  );
}

class OrganizeRequest {
  final List<OrganizeItem> items;
  final String pattern;

  /// O nome do que as tags não dizem.
  final String unknown;

  /// Copiar para esta pasta. Sem ela, move dentro da pasta de cada faixa.
  final String? copyTo;

  /// A faixa tocando fica onde está.
  final String? playing;

  const OrganizeRequest({
    required this.items,
    required this.pattern,
    required this.unknown,
    this.copyTo,
    this.playing,
  });
}

class OrganizePlan {
  final List<FileMove> moves;

  /// Faixas que já estão no lugar.
  final int unchanged;

  /// Quanto cabe no destino da cópia, se deu para saber.
  final int? freeBytes;
  final bool copying;

  const OrganizePlan({
    this.moves = const [],
    this.unchanged = 0,
    this.freeBytes,
    this.copying = false,
  });

  List<FileMove> get ready => moves.where((m) => m.problem == null).toList();
  int get problems => moves.where((m) => m.problem != null).length;
  int get bytes => ready.fold(0, (sum, m) => sum + m.size);
}

/// O espaço livre e o tipo do disco de [path], ou nulo se o `df` não disser.
(int, String)? diskInfo(String path) {
  try {
    final result = Process.runSync('df', [
      '-B1',
      '--output=avail,fstype',
      path,
    ]);
    if (result.exitCode != 0) return null;
    final lines = (result.stdout as String).trim().split('\n');
    final parts = lines.last.trim().split(RegExp(r'\s+'));
    final avail = int.tryParse(parts.first);
    return avail == null || parts.length < 2 ? null : (avail, parts[1]);
  } on ProcessException {
    return null;
  }
}

const _strictSystems = {
  'vfat',
  'msdos',
  'exfat',
  'ntfs',
  'ntfs3',
  'fuseblk',
  'cifs',
  'smb3',
};

bool strictFileSystem(String type) => _strictSystems.contains(type);

const _lyricsExtensions = {'.lrc', '.srt'};

/// O que seria feito. Só olha os arquivos: não muda nada.
OrganizePlan planOrganize(OrganizeRequest request) {
  final copying = request.copyTo != null;
  final moves = <FileMove>[];
  var unchanged = 0;
  final strictOf = <String, bool>{};
  final info = copying ? diskInfo(request.copyTo!) : null;

  bool strict(String root) => strictOf.putIfAbsent(root, () {
    final disk = diskInfo(root);
    return disk != null && strictFileSystem(disk.$2);
  });

  final listings = <String, List<String>>{};
  List<String> namesIn(String dir) => listings.putIfAbsent(dir, () {
    try {
      return [for (final e in Directory(dir).listSync()) p.basename(e.path)];
    } on FileSystemException {
      return const [];
    }
  });

  int sizeOf(String path) {
    try {
      return File(path).lengthSync();
    } on FileSystemException {
      return 0;
    }
  }

  // Para onde vai cada faixa de cada pasta de origem
  final targetsByDir = <String, Set<String>>{};
  final movedByDir = <String, int>{};
  final seen = <String, int>{};
  final keyStrict = copying
      ? (info == null || strictFileSystem(info.$2))
      : null;
  String key(String path, bool isStrict) =>
      isStrict ? path.toLowerCase() : path;

  for (final item in request.items) {
    final root = request.copyTo ?? item.root;
    final isStrict = keyStrict ?? strict(item.root);
    final extension = p.extension(item.path);
    final parts = expandOrganizePattern(
      request.pattern,
      item,
      unknown: request.unknown,
      strict: isStrict,
    );
    final safe = [
      for (var i = 0; i < parts.length; i++)
        safeFileName(
          parts[i],
          unknown: request.unknown,
          extension: i == parts.length - 1 ? extension : '',
        ),
    ];
    final to = p.joinAll([root, ...safe]);
    final dir = p.dirname(item.path);
    if (!copying && to == item.path) {
      unchanged++;
      targetsByDir.putIfAbsent(dir, () => {}).add(p.dirname(to));
      movedByDir[dir] = (movedByDir[dir] ?? 0) + 1;
      continue;
    }
    MoveProblem? problem;
    final target = File(to);
    final size = sizeOf(item.path);
    var already = false;
    if (seen.containsKey(key(to, isStrict))) {
      problem = MoveProblem.sameTarget;
    } else if (target.existsSync() || Directory(to).existsSync()) {
      if (copying && target.existsSync() && target.lengthSync() == size) {
        already = true;
      } else {
        problem = MoveProblem.targetExists;
      }
    } else if (!copying && item.path == request.playing) {
      problem = MoveProblem.playing;
    }
    seen[key(to, isStrict)] = moves.length;
    if (already) {
      unchanged++;
      continue;
    }
    moves.add(
      FileMove(
        from: item.path,
        to: to,
        kind: FileMoveKind.track,
        size: size,
        problem: problem,
      ),
    );
    if (problem != null) continue;
    targetsByDir.putIfAbsent(dir, () => {}).add(p.dirname(to));
    movedByDir[dir] = (movedByDir[dir] ?? 0) + 1;

    // A letra de mesmo nome vai junto
    final stem = p.basenameWithoutExtension(item.path).toLowerCase();
    for (final name in namesIn(dir)) {
      final ext = p.extension(name);
      if (!_lyricsExtensions.contains(ext.toLowerCase())) continue;
      if (p.basenameWithoutExtension(name).toLowerCase() != stem) continue;
      final from = p.join(dir, name);
      final sidecar = p.setExtension(to, ext);
      final taken = File(sidecar).existsSync();
      if (copying && taken) continue;
      moves.add(
        FileMove(
          from: from,
          to: sidecar,
          kind: FileMoveKind.sidecar,
          size: sizeOf(from),
          track: item.path,
          problem: taken ? MoveProblem.targetExists : null,
        ),
      );
    }
  }

  // A capa da pasta vai quando a pasta inteira muda, e a cópia sempre leva
  for (final MapEntry(key: dir, value: targets) in targetsByDir.entries) {
    final names = namesIn(dir);
    final audio = names.where(
      (n) => audioExtensions.contains(p.extension(n).toLowerCase()),
    );
    final whole = targets.length == 1 && movedByDir[dir] == audio.length;
    if (!copying && !whole) continue;
    final cover = findCoverFile(names);
    if (cover == null) continue;
    for (final targetDir in copying ? targets : {targets.single}) {
      if (!copying && targetDir == dir) continue;
      final to = p.join(targetDir, cover);
      if (File(to).existsSync() || seen.containsKey(to)) continue;
      seen[to] = moves.length;
      final from = p.join(dir, cover);
      moves.add(
        FileMove(
          from: from,
          to: to,
          kind: FileMoveKind.cover,
          size: sizeOf(from),
        ),
      );
    }
  }

  // Na cópia, o que passa do espaço livre fica de fora, na ordem da lista
  final free = info?.$1;
  if (free != null) {
    var left = free;
    for (var i = 0; i < moves.length; i++) {
      final move = moves[i];
      if (move.problem != null) continue;
      if (move.size > left) {
        moves[i] = move.withProblem(MoveProblem.noSpace);
      } else {
        left -= move.size;
      }
    }
  }
  return OrganizePlan(
    moves: moves,
    unchanged: unchanged,
    freeBytes: free,
    copying: copying,
  );
}

const _copied = '.psito-tmp';

void _copyChecked(File source, String to) {
  final stat = source.statSync();
  final temp = p.join(p.dirname(to), '.${p.basename(to)}$_copied');
  try {
    source.copySync(temp);
    final copy = File(temp);
    if (copy.lengthSync() != stat.size) {
      throw const TagWriteException(TagWriteFailure.verifyFailed, 'cópia');
    }
    // Com a mesma data, a biblioteca não lê de novo
    try {
      copy.setLastModifiedSync(stat.modified);
    } on FileSystemException {
      // O FAT arredonda ou recusa: no pior caso, relê a faixa
    }
    copy.renameSync(to);
  } finally {
    final copy = File(temp);
    if (copy.existsSync()) copy.deleteSync();
  }
}

/// Faz um arquivo: copia, ou move sem nunca passar por cima de outro. Não lança.
TagFileFailed? runFileMove(FileMove move, {required bool copy}) {
  final from = File(move.from);
  if (!from.existsSync()) {
    return TagFileFailed(move.from, TagWriteFailure.missing);
  }
  if (File(move.to).existsSync() || Directory(move.to).existsSync()) {
    return TagFileFailed(move.from, TagWriteFailure.targetExists);
  }
  try {
    Directory(p.dirname(move.to)).createSync(recursive: true);
    if (copy) {
      _copyChecked(from, move.to);
      return null;
    }
    try {
      from.renameSync(move.to);
    } on FileSystemException catch (e) {
      // Outro disco: copia, confere e só então apaga
      if (e.osError?.errorCode != 18) rethrow;
      _copyChecked(from, move.to);
      from.deleteSync();
    }
    return null;
  } on FileSystemException catch (e) {
    return TagFileFailed(move.from, failureOf(e).reason);
  } on TagWriteException catch (e) {
    return TagFileFailed(move.from, e.reason);
  }
}

/// Tira as pastas que o trabalho esvaziou, subindo até [roots], que ficam.
void removeEmptiedFolders(Iterable<String> dirs, Set<String> roots) {
  final ordered = dirs.toSet().toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (var dir in ordered) {
    while (!roots.contains(dir) && roots.any((r) => p.isWithin(r, dir))) {
      try {
        Directory(dir).deleteSync();
      } on FileSystemException {
        break;
      }
      dir = p.dirname(dir);
    }
  }
}

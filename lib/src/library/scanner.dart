// lib/src/library/scanner.dart
//
// A leitura das pastas: acha os arquivos, lê as tags, as letras e as capas ao
// lado, e grava aos poucos, para o que já foi lido aparecer e tocar. Roda num
// isolate (IsolateScanner), e o `scanFolders` não sabe disso.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'library_db.dart';
import 'cue.dart';
import 'models.dart';
import 'tags.dart';

const audioExtensions = {
  '.flac',
  '.mp3',
  '.ogg',
  '.opus',
  '.m4a',
  '.wav',
  '.aac',
  '.wma',
  '.ape',
  '.wv',
  '.aiff',
  '.aif',
};

/// O lado da miniatura em disco: o dobro do maior cartão não precisa mais.
const coverThumbSize = 400;

const _coverNames = ['cover', 'folder'];
const _coverExtensions = ['.jpg', '.jpeg', '.png'];

/// De quanto em quanto o que foi lido entra no banco e na tela.
const _batchFiles = 40;
const _batchTime = Duration(milliseconds: 700);

@immutable
class ScanProgress {
  /// Arquivos de áudio achados até agora. Cresce enquanto há pastas por listar.
  final int total;
  final int done;
  final String? currentFolder;

  final int albums;
  final int tracks;
  final int covers;

  /// Os que nem deu para abrir.
  final int skipped;
  final bool paused;
  final bool finished;

  /// As pastas que não estavam lá.
  final int missingFolders;

  const ScanProgress({
    this.total = 0,
    this.done = 0,
    this.currentFolder,
    this.albums = 0,
    this.tracks = 0,
    this.covers = 0,
    this.skipped = 0,
    this.paused = false,
    this.finished = false,
    this.missingFolders = 0,
  });

  ScanProgress copyWith({bool? paused, bool? finished}) => ScanProgress(
    total: total,
    done: done,
    currentFolder: currentFolder,
    albums: albums,
    tracks: tracks,
    covers: covers,
    skipped: skipped,
    missingFolders: missingFolders,
    paused: paused ?? this.paused,
    finished: finished ?? this.finished,
  );
}

/// Pausar e cancelar, de fora do laço.
class ScanControl {
  bool cancelled = false;
  Completer<void>? _resume;

  bool get paused => _resume != null;

  void pause() => _resume ??= Completer();

  void resume() {
    _resume?.complete();
    _resume = null;
  }

  void cancel() {
    cancelled = true;
    resume();
  }

  /// Dá a vez às mensagens e espera se estiver em pausa.
  Future<void> checkpoint() async {
    await Future<void>.delayed(Duration.zero);
    while (_resume != null) {
      await _resume!.future;
    }
  }
}

/// A capa ao lado da música, sem diferenciar maiúsculas.
String? findCoverFile(Iterable<String> names) {
  for (final name in _coverNames) {
    for (final extension in _coverExtensions) {
      for (final candidate in names) {
        if (candidate.toLowerCase() == '$name$extension') return candidate;
      }
    }
  }
  return null;
}

/// A letra de [audio]: o nome é o mesmo, sem diferenciar maiúsculas, e o `.lrc`
/// vence o `.srt`.
String? findLyricsFile(String audio, Iterable<String> names) {
  final stem = p.basenameWithoutExtension(audio).toLowerCase();
  for (final extension in const ['.lrc', '.srt']) {
    final matches = [
      for (final name in names)
        if (name.toLowerCase() == '$stem$extension') name,
    ]..sort();
    if (matches.isNotEmpty) return matches.first;
  }
  return null;
}

/// Grava a miniatura. Devolve false se a imagem não dá para ler.
bool writeCoverThumb(Uint8List bytes, String path) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return false;
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final square = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final thumb = side > coverThumbSize
      ? img.copyResize(square, width: coverThumbSize, height: coverThumbSize)
      : square;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodeJpg(thumb, quality: 85));
  return true;
}

/// Os arquivos de áudio da pasta, em ordem, para os álbuns aparecerem inteiros.
/// Uma subpasta sem permissão fica de fora, sem parar o resto.
// A lixeira de um disco (.Trash-1000) também é uma pasta oculta
bool _isHidden(String relative) =>
    p.split(relative).any((part) => part.startsWith('.'));

Future<List<String>> _listAudio(
  String folder,
  ScanControl control, {
  Map<String, String>? cues,
}) async {
  final found = <String>[];
  final lister = Directory(folder)
      .list(recursive: true, followLinks: false)
      .handleError((Object e) {
        debugPrint('🎵 não deu para listar: $e');
      });
  await for (final entity in lister) {
    if (control.cancelled) break;
    if (entity is File && p.extension(entity.path).toLowerCase() == '.cue') {
      cues?[entity.path.toLowerCase()] = entity.path;
    }
    if (entity is File &&
        audioExtensions.contains(p.extension(entity.path).toLowerCase()) &&
        !_isHidden(p.relative(entity.path, from: folder))) {
      found.add(entity.path);
    }
  }
  return found..sort();
}

/// As faixas de cue sheet que o banco conhece, por arquivo de verdade.
Map<String, List<String>> _cueRows(Map<String, (int, int)> known) {
  final out = <String, List<String>>{};
  for (final path in known.keys) {
    final ref = CueRef.parse(path);
    if (ref != null) out.putIfAbsent(ref.file, () => []).add(path);
  }
  return out;
}

/// A data que vale para as faixas de uma cue sheet: a do áudio ou a do texto.
int _cueStamp(int audio, String? cue) {
  if (cue == null) return audio;
  final stat = File(cue).statSync();
  final text = stat.modified.millisecondsSinceEpoch;
  return text > audio ? text : audio;
}

/// O que mudou numa pasta desde a última leitura, sem ler nenhuma tag.
@immutable
class FolderCheck {
  /// Arquivos novos, alterados e removidos.
  final int changes;

  /// A pasta não está lá, ou está vazia e a biblioteca conhece faixas dela: o
  /// ponto de montagem de um disco desligado é uma pasta vazia.
  final bool unavailable;

  const FolderCheck({this.changes = 0, this.unavailable = false});
}

/// Compara o que está na pasta com o que o banco lembra.
Future<FolderCheck> checkFolder(LibraryDb db, MusicFolder folder) async {
  if (!Directory(folder.path).existsSync()) {
    return const FolderCheck(unavailable: true);
  }
  final cues = <String, String>{};
  final files = await _listAudio(folder.path, ScanControl(), cues: cues);
  final known = db.knownFiles(folder.id);
  final cueRows = _cueRows(known);
  if (files.isEmpty && known.isNotEmpty) {
    return const FolderCheck(unavailable: true);
  }
  final gone = known.keys.toSet();
  var changes = 0;
  for (final path in files) {
    gone.remove(path);
    final stat = File(path).statSync();
    if (stat.type == FileSystemEntityType.notFound) continue;
    final cue = findCueFile(path, cues);
    final rows = cueRows[path];
    if (rows != null || cue != null) {
      gone.removeAll(rows ?? const []);
      gone.remove(path);
      final stamp = _cueStamp(stat.modified.millisecondsSinceEpoch, cue);
      if (rows == null || known[rows.first]!.$1 != stamp) changes++;
      continue;
    }
    final old = known[path];
    if (old == null ||
        old.$1 != stat.modified.millisecondsSinceEpoch ||
        old.$2 != stat.size) {
      changes++;
    }
  }
  return FolderCheck(changes: changes + gone.length);
}

/// As faixas que [sheet] tira de [path]. Sem nada dela, valem as tags do arquivo.
List<ScannedTrack> cueTracks(
  CueSheet sheet,
  String path,
  FileTags tags,
  int size,
  int stamp,
  String dir,
) {
  final out = <ScannedTrack>[];
  final albumArtist = sheet.performer ?? tags.albumArtist ?? tags.artist ?? '';
  for (final (i, track) in sheet.tracks.indexed) {
    final end = i + 1 < sheet.tracks.length
        ? sheet.tracks[i + 1].startMs
        : tags.durationMs;
    final length = end - track.startMs;
    if (length <= 0) continue;
    out.add(
      ScannedTrack(
        path: CueRef(path, track.number, track.startMs, length).path,
        title:
            track.title ?? '${tags.album ?? p.basename(dir)} ${track.number}',
        artist: track.performer ?? sheet.performer ?? tags.artist ?? '',
        albumArtist: albumArtist,
        album: sheet.title ?? tags.album ?? p.basename(dir),
        trackNumber: track.number,
        discNumber: tags.discNumber,
        year: sheet.year ?? tags.year,
        genre: sheet.genre ?? tags.genre,
        durationMs: length,
        sampleRate: tags.sampleRate,
        bitrate: tags.bitrate,
        // O arquivo conta uma vez só no tamanho da biblioteca
        size: i == 0 ? size : 0,
        mtime: stamp,
      ),
    );
  }
  return out;
}

/// Tira a capa do álbum, se ele não tiver. Devolve quantas capas novas.
int _cover(
  LibraryDb db,
  int albumId,
  FileTags tags,
  String coverDir,
  int version,
  String dir,
  List<String> dirNames,
) {
  if (db.albumHasCover(albumId)) return 0;
  // Um nome por versão: o cache de imagens do Flutter é pelo caminho, e a capa
  // muda quando o editor de tags grava outra
  final thumb = p.join(coverDir, '$albumId-$version.jpg');
  final coverFile = findCoverFile(dirNames);
  try {
    if (tags.cover != null && writeCoverThumb(tags.cover!, thumb)) {
      db.setAlbumCover(albumId, thumb, 'embedded');
      return 1;
    }
    if (coverFile != null &&
        writeCoverThumb(
          File(p.join(dir, coverFile)).readAsBytesSync(),
          thumb,
        )) {
      db.setAlbumCover(albumId, thumb, coverFile);
      return 1;
    }
  } catch (e) {
    debugPrint('🎵 capa ilegível em $dir: $e');
  }
  return 0;
}

/// Lê as pastas e grava em [db]. Só relê o que mudou de data ou de tamanho. No
/// fim, tira do banco o que sumiu, a não ser que tenham cancelado ou que a pasta
/// inteira não esteja lá (um disco desligado não apaga a biblioteca dele).
Future<void> scanFolders({
  required LibraryDb db,
  required List<MusicFolder> folders,
  required String coverDir,
  required ScanControl control,
  required void Function(ScanProgress) onProgress,
  TagReader readTags = readFileTags,
  int Function() now = _now,
}) async {
  var total = 0;
  var done = 0;
  var tracks = 0;
  var covers = 0;
  var skipped = 0;
  var missing = 0;
  final albums = <int>{};
  String? current;

  ScanProgress progress({bool finished = false}) => ScanProgress(
    total: total,
    done: done,
    currentFolder: current,
    albums: albums.length,
    tracks: tracks,
    covers: covers,
    skipped: skipped,
    missingFolders: missing,
    paused: control.paused,
    finished: finished,
  );

  // Listar antes de ler, para o progresso saber o tamanho
  final listings = <(MusicFolder, List<String>)>[];
  final cues = <String, String>{};
  for (final folder in folders) {
    current = folder.path;
    onProgress(progress());
    if (!Directory(folder.path).existsSync()) {
      missing++;
      continue;
    }
    final files = await _listAudio(folder.path, control, cues: cues);
    if (files.isEmpty &&
        !control.cancelled &&
        db.knownFiles(folder.id).isNotEmpty) {
      missing++;
      continue;
    }
    total += files.length;
    listings.add((folder, files));
    await control.checkpoint();
  }

  var open = false;
  var batch = 0;
  final clock = Stopwatch()..start();
  void flush() {
    if (open) db.commit();
    open = false;
    batch = 0;
    clock.reset();
    onProgress(progress());
  }

  // Os nomes de cada pasta, uma vez só
  final names = <String, List<String>>{};
  List<String> namesIn(String dir) => names.putIfAbsent(dir, () {
    try {
      return [
        for (final entity in Directory(dir).listSync()) p.basename(entity.path),
      ];
    } on FileSystemException {
      return const [];
    }
  });

  for (final (folder, files) in listings) {
    if (control.cancelled) break;
    final known = db.knownFiles(folder.id);
    final knownLyrics = db.knownLyrics(folder.id);
    final cueRows = _cueRows(known);
    final gone = known.keys.toSet();
    for (final path in files) {
      gone.remove(path);
      if (control.cancelled) break;
      if (control.paused) flush();
      await control.checkpoint();
      if (control.cancelled) break;
      current = p.dirname(path);
      final file = File(path);
      final stat = file.statSync();
      if (stat.type == FileSystemEntityType.notFound) {
        skipped++;
        done++;
        continue;
      }
      final mtime = stat.modified.millisecondsSinceEpoch;
      final cue = findCueFile(path, cues);
      final rows = cueRows[path];
      final stamp = _cueStamp(mtime, cue);
      // A cue sheet não mudou: as faixas dela continuam
      if (rows != null && known[rows.first]!.$1 == stamp) {
        gone.removeAll(rows);
        tracks += rows.length;
        done++;
        if (clock.elapsed > _batchTime) flush();
        continue;
      }
      final old = known[path];
      if (cue == null &&
          rows == null &&
          old != null &&
          old.$1 == mtime &&
          old.$2 == stat.size) {
        // A letra pode chegar ou sair sem a música mudar
        final dir = p.dirname(path);
        final lyrics = findLyricsFile(path, namesIn(dir));
        final lyricsPath = lyrics == null ? null : p.join(dir, lyrics);
        if (lyricsPath != knownLyrics[path]) {
          db.setLyricsPath(path, lyricsPath);
        }
        tracks++;
        done++;
        // Sem nada a gravar, o progresso ainda precisa andar
        if (clock.elapsed > _batchTime) flush();
        continue;
      }
      if (!open) {
        db.begin();
        open = true;
      }
      // Uma tag ilegível não impede de tocar: a faixa fica com o nome do arquivo
      FileTags tags;
      try {
        tags = readTags(file);
      } catch (e) {
        debugPrint('🎵 sem tags em $path: $e');
        tags = const FileTags();
      }
      final dir = p.dirname(path);
      final dirNames = namesIn(dir);
      final sheet = cue != null ? readCueFile(cue) : readEmbeddedCue(path);
      if (sheet != null && tags.durationMs > 0) {
        final parts = cueTracks(sheet, path, tags, stat.size, stamp, dir);
        if (parts.isNotEmpty) {
          // O arquivo inteiro, que estava na biblioteca, dá lugar às faixas
          if (known.containsKey(path)) gone.add(path);
          for (final part in parts) {
            gone.remove(part.path);
            final albumId = db.upsertTrack(part, folder.id, now());
            albums.add(albumId);
            tracks++;
            covers += _cover(db, albumId, tags, coverDir, stamp, dir, dirNames);
          }
          done++;
          batch++;
          if (batch >= _batchFiles || clock.elapsed > _batchTime) flush();
          continue;
        }
      }
      final lyrics = findLyricsFile(path, dirNames);
      final artist = tags.artist ?? '';
      final albumId = db.upsertTrack(
        ScannedTrack(
          path: path,
          title: tags.title ?? p.basenameWithoutExtension(path),
          artist: artist,
          albumArtist: tags.albumArtist ?? artist,
          album: tags.album ?? p.basename(dir),
          trackNumber: tags.trackNumber,
          discNumber: tags.discNumber,
          year: tags.year,
          genre: tags.genre,
          durationMs: tags.durationMs,
          sampleRate: tags.sampleRate,
          bitrate: tags.bitrate,
          size: stat.size,
          mtime: mtime,
          lyricsPath: lyrics == null ? null : p.join(dir, lyrics),
          embeddedLyrics: tags.embeddedLyrics,
          composer: tags.composer,
          comment: tags.comment,
        ),
        folder.id,
        now(),
      );
      albums.add(albumId);
      tracks++;
      done++;
      covers += _cover(db, albumId, tags, coverDir, mtime, dir, dirNames);
      batch++;
      if (batch >= _batchFiles || clock.elapsed > _batchTime) flush();
    }
    if (!control.cancelled) {
      if (!open) {
        db.begin();
        open = true;
      }
      db.removeTracks(gone);
      db.markScanned(folder.id, now());
    }
  }
  if (!open) {
    db.begin();
    open = true;
  }
  for (final cover in db.removeOrphans()) {
    try {
      File(cover).deleteSync();
    } on FileSystemException catch (e) {
      debugPrint('🎵 capa velha ficou: $e');
    }
  }
  flush();
  onProgress(progress(finished: true));
}

int _now() => DateTime.now().millisecondsSinceEpoch;

/// Uma leitura em andamento.
abstract interface class ScanSession {
  Stream<ScanProgress> get progress;
  void pause();
  void resume();
  void cancel();
}

abstract interface class LibraryScanner {
  ScanSession start(List<MusicFolder> folders);

  /// O que mudou em cada pasta, por id. Fora do isolate do banco, porque listar
  /// um disco lento seguraria as consultas.
  Future<Map<int, FolderCheck>> check(List<MusicFolder> folders);

  /// Se a pasta está lá. Sem bloquear: um disco que sumiu pode demorar a responder.
  Future<bool> folderExists(String path);
}

class IsolateScanner implements LibraryScanner {
  final String dbPath;
  final String coverDir;

  IsolateScanner({required this.dbPath, required this.coverDir});

  @override
  ScanSession start(List<MusicFolder> folders) =>
      _IsolateSession(dbPath, coverDir, folders);

  @override
  Future<bool> folderExists(String path) => Directory(path).exists();

  @override
  Future<Map<int, FolderCheck>> check(List<MusicFolder> folders) {
    final path = dbPath;
    return Isolate.run(() async {
      final db = LibraryDb.open(path);
      try {
        return {
          for (final folder in folders)
            folder.id: await checkFolder(db, folder),
        };
      } finally {
        db.close();
      }
    }, debugName: 'psito-player-check');
  }
}

class _IsolateSession implements ScanSession {
  final _progress = StreamController<ScanProgress>();
  final _commands = Completer<SendPort>();

  _IsolateSession(String dbPath, String coverDir, List<MusicFolder> folders) {
    final messages = ReceivePort();
    final exit = ReceivePort();
    void finish() {
      messages.close();
      exit.close();
      unawaited(_progress.close());
    }

    messages.listen((message) {
      if (message is SendPort) {
        _commands.complete(message);
      } else if (message is ScanProgress) {
        _progress.add(message);
        if (message.finished) finish();
      }
    });
    // Se o isolate cair, a sessão termina em vez de ficar lendo para sempre
    exit.listen((_) {
      if (!_progress.isClosed) {
        _progress.add(const ScanProgress(finished: true));
        finish();
      }
    });
    unawaited(
      Isolate.spawn(
        _scanMain,
        (dbPath, coverDir, folders, messages.sendPort),
        debugName: 'psito-player-scan',
        onExit: exit.sendPort,
      ),
    );
  }

  void _send(String command) =>
      unawaited(_commands.future.then((port) => port.send(command)));

  @override
  Stream<ScanProgress> get progress => _progress.stream;

  @override
  void pause() => _send('pause');

  @override
  void resume() => _send('resume');

  @override
  void cancel() => _send('cancel');
}

Future<void> _scanMain(
  (String, String, List<MusicFolder>, SendPort) args,
) async {
  final (dbPath, coverDir, folders, messages) = args;
  final commands = ReceivePort();
  final control = ScanControl();
  commands.listen((command) {
    switch (command) {
      case 'pause':
        control.pause();
      case 'resume':
        control.resume();
      case 'cancel':
        control.cancel();
    }
  });
  messages.send(commands.sendPort);
  final db = LibraryDb.open(dbPath);
  try {
    await scanFolders(
      db: db,
      folders: folders,
      coverDir: coverDir,
      control: control,
      onProgress: messages.send,
    );
  } finally {
    db.close();
    commands.close();
  }
}

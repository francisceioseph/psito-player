// lib/src/library/library_db.dart
//
// O banco da biblioteca, em SQLite. É síncrono: quem usa o app fala com ele pelo
// LibraryStore, em outro isolate, e o scanner abre a própria conexão.
import 'dart:ffi';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'organize/file_organizer.dart';

import 'models.dart';

const _schemaVersion = 10;

@visibleForTesting
const schemaV1 = '''
CREATE TABLE folders (
  id INTEGER PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  scanned_at INTEGER
);
CREATE TABLE artists (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);
CREATE TABLE albums (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  artist_id INTEGER NOT NULL REFERENCES artists(id),
  year INTEGER,
  cover_path TEXT,
  cover_source TEXT,
  UNIQUE (title, artist_id)
);
CREATE TABLE tracks (
  id INTEGER PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,
  album_id INTEGER NOT NULL REFERENCES albums(id),
  artist_id INTEGER NOT NULL REFERENCES artists(id),
  title TEXT NOT NULL,
  track_number INTEGER,
  disc_number INTEGER,
  year INTEGER,
  genre TEXT,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  sample_rate INTEGER,
  bitrate INTEGER,
  size INTEGER NOT NULL DEFAULT 0,
  mtime INTEGER NOT NULL DEFAULT 0,
  lyrics_path TEXT,
  embedded_lyrics INTEGER NOT NULL DEFAULT 0,
  play_count INTEGER NOT NULL DEFAULT 0,
  last_played_at INTEGER,
  added_at INTEGER NOT NULL
);
CREATE INDEX tracks_album ON tracks(album_id);
CREATE INDEX tracks_folder ON tracks(folder_id);
CREATE INDEX tracks_played ON tracks(play_count);
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''';

/// As letras contam sem acento e sem diferenciar maiúsculas, o que o NOCASE do
/// SQLite não faz fora do ASCII.
const _collation = 'psito_folded';

const _ftsFillV2 = '''
  INSERT INTO tracks_fts (rowid, title, artist, album, album_artist, dir)
  SELECT NEW.id, NEW.title, a.name, al.title, aa.name, NEW.rel_dir
  FROM artists a, albums al JOIN artists aa ON aa.id = al.artist_id
  WHERE a.id = NEW.artist_id AND al.id = NEW.album_id;
''';

/// Os favoritos, a pasta de cada faixa, o formato, as playlists e a busca. As
/// playlists guardam o caminho, para sobreviver a tirar a pasta da biblioteca e
/// para levar faixas de um M3U que não estão nela.
const _schemaV2Tables =
    '''
CREATE INDEX tracks_dir ON tracks(dir);
CREATE INDEX tracks_artist ON tracks(artist_id);
CREATE INDEX tracks_genre ON tracks(genre);
CREATE INDEX tracks_favorite ON tracks(favorite) WHERE favorite = 1;
CREATE TABLE playlists (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE playlist_tracks (
  playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  path TEXT NOT NULL,
  PRIMARY KEY (playlist_id, position)
);
CREATE VIRTUAL TABLE tracks_fts USING fts5(
  title, artist, album, album_artist, dir,
  tokenize = "unicode61 remove_diacritics 2",
  prefix = '2 3'
);
INSERT INTO tracks_fts (rowid, title, artist, album, album_artist, dir)
  SELECT t.id, t.title, a.name, al.title, aa.name, t.rel_dir
  FROM tracks t
  JOIN artists a ON a.id = t.artist_id
  JOIN albums al ON al.id = t.album_id
  JOIN artists aa ON aa.id = al.artist_id;
CREATE TRIGGER tracks_fts_insert AFTER INSERT ON tracks BEGIN
  $_ftsFillV2
END;
CREATE TRIGGER tracks_fts_delete AFTER DELETE ON tracks BEGIN
  DELETE FROM tracks_fts WHERE rowid = OLD.id;
END;
CREATE TRIGGER tracks_fts_update
AFTER UPDATE OF title, artist_id, album_id, rel_dir ON tracks BEGIN
  DELETE FROM tracks_fts WHERE rowid = OLD.id;
  $_ftsFillV2
END;
''';

const _ftsFill = '''
  INSERT INTO tracks_fts (rowid, title, artist, album, album_artist, dir,
    composer, comment)
  SELECT NEW.id, NEW.title, a.name, al.title, aa.name, NEW.rel_dir,
    NEW.composer, NEW.comment
  FROM artists a, albums al JOIN artists aa ON aa.id = al.artist_id
  WHERE a.id = NEW.artist_id AND al.id = NEW.album_id;
''';

/// O compositor e o comentário, também na busca. O FTS5 não ganha colunas: a
/// tabela é refeita.
const _schemaV10 =
    '''
ALTER TABLE tracks ADD COLUMN composer TEXT;
ALTER TABLE tracks ADD COLUMN comment TEXT;
DROP TRIGGER tracks_fts_insert;
DROP TRIGGER tracks_fts_delete;
DROP TRIGGER tracks_fts_update;
DROP TABLE tracks_fts;
CREATE VIRTUAL TABLE tracks_fts USING fts5(
  title, artist, album, album_artist, dir, composer, comment,
  tokenize = "unicode61 remove_diacritics 2",
  prefix = '2 3'
);
INSERT INTO tracks_fts (rowid, title, artist, album, album_artist, dir,
    composer, comment)
  SELECT t.id, t.title, a.name, al.title, aa.name, t.rel_dir, t.composer,
    t.comment
  FROM tracks t
  JOIN artists a ON a.id = t.artist_id
  JOIN albums al ON al.id = t.album_id
  JOIN artists aa ON aa.id = al.artist_id;
CREATE TRIGGER tracks_fts_insert AFTER INSERT ON tracks BEGIN
  $_ftsFill
END;
CREATE TRIGGER tracks_fts_delete AFTER DELETE ON tracks BEGIN
  DELETE FROM tracks_fts WHERE rowid = OLD.id;
END;
CREATE TRIGGER tracks_fts_update
AFTER UPDATE OF title, artist_id, album_id, rel_dir, composer, comment
ON tracks BEGIN
  DELETE FROM tracks_fts WHERE rowid = OLD.id;
  $_ftsFill
END;
''';

const _trackColumns = '''
  t.id, t.path, t.title, a.name AS artist, t.album_id, al.title AS album,
  t.track_number, t.disc_number, t.year, t.duration_ms, t.lyrics_path,
  t.embedded_lyrics, al.cover_path, t.play_count, t.favorite, t.format, t.genre,
  t.rating, t.skip
''';

const _trackJoins = '''
  FROM tracks t
  JOIN artists a ON a.id = t.artist_id
  JOIN albums al ON al.id = t.album_id
''';

const _albumFrom = '''
  SELECT al.id, al.title, a.name AS artist, al.year, al.cover_path,
    COUNT(t.id) AS track_count, SUM(t.duration_ms) AS duration_ms,
    SUM(t.size) AS size, MIN(t.path) AS first_path, MAX(t.added_at) AS added_at,
    GROUP_CONCAT(DISTINCT t.format) AS formats
  FROM albums al
  JOIN artists a ON a.id = al.artist_id
  JOIN tracks t ON t.album_id = al.id
''';

const _albumSelect = '$_albumFrom GROUP BY al.id';

/// Do que a tela ordena para o SQL.
String _albumOrder(AlbumSort sort) => switch (sort) {
  AlbumSort.recent => 'added_at DESC, al.id DESC',
  AlbumSort.title => 'al.title COLLATE $_collation',
  AlbumSort.artist => 'a.name COLLATE $_collation, al.year, al.title',
  AlbumSort.year =>
    'al.year IS NULL, al.year DESC, al.title COLLATE $_collation',
};

String _trackOrder(TrackSort sort, bool ascending) {
  final direction = ascending ? 'ASC' : 'DESC';
  const byTitle = 't.title COLLATE $_collation';
  return switch (sort) {
    TrackSort.title => '$byTitle $direction',
    TrackSort.album =>
      'al.title COLLATE $_collation $direction, '
          'COALESCE(t.disc_number, 1), t.track_number IS NULL, t.track_number',
    TrackSort.artist => 'a.name COLLATE $_collation $direction, $byTitle',
    TrackSort.duration => 't.duration_ms $direction, $byTitle',
    TrackSort.format => 't.format $direction, $byTitle',
    TrackSort.added => 't.added_at $direction, t.id $direction',
    TrackSort.rating => 't.rating $direction, $byTitle',
    TrackSort.year => 't.year IS NULL, t.year $direction, $byTitle',
  };
}

Track _track(Row r) {
  final path = r['path'] as String;
  return Track(
    id: r['id'] as int,
    path: path,
    title: r['title'] as String,
    artist: r['artist'] as String,
    albumId: r['album_id'] as int,
    album: r['album'] as String,
    trackNumber: r['track_number'] as int?,
    discNumber: r['disc_number'] as int?,
    year: r['year'] as int?,
    duration: Duration(milliseconds: r['duration_ms'] as int),
    format: r['format'] as String,
    genre: r['genre'] as String?,
    favorite: r['favorite'] == 1,
    skip: r['skip'] == 1,
    rating: r['rating'] as int,
    lyricsPath: r['lyrics_path'] as String?,
    embeddedLyrics: r['embedded_lyrics'] == 1,
    coverPath: r['cover_path'] as String?,
    playCount: r['play_count'] as int,
  );
}

Album _album(Row r) => Album(
  id: r['id'] as int,
  title: r['title'] as String,
  artist: r['artist'] as String,
  year: r['year'] as int?,
  coverPath: r['cover_path'] as String?,
  trackCount: r['track_count'] as int,
  duration: Duration(milliseconds: r['duration_ms'] as int),
  size: r['size'] as int,
  formats:
      ((r['formats'] as String?)?.split(',') ?? const <String>[])
          .where((format) => format.isNotEmpty)
          .toList()
        ..sort(),
  folder: p.dirname(r['first_path'] as String),
);

/// O que vai para o MATCH: cada palavra é o começo de uma palavra, entre aspas
/// para o que a pessoa digita não virar sintaxe da busca.
@visibleForTesting
String ftsTerms(String query) => query
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) => '"${word.replaceAll('"', '""')}"*')
    .join(' ');

class LibraryDb {
  final Database _db;

  LibraryDb._(this._db) {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('PRAGMA busy_timeout = 5000');
    _db.createCollation(name: _collation, function: compareFolded);
    _migrate();
  }

  void _migrate() {
    if (_db.userVersion >= _schemaVersion) return;
    _db.execute('BEGIN IMMEDIATE');
    // Com o banco já travado: outra conexão pode ter passado na frente
    final from = _db.userVersion;
    if (from < 1) _db.execute(schemaV1);
    if (from < 2) _toV2();
    if (from < 3) _toV3();
    if (from < 4) _toV4();
    if (from < 5) _toV5();
    if (from < 6) _toV6();
    if (from < 7) _toV7();
    if (from < 8) _toV8();
    if (from < 9) _toV9();
    if (from < 10) _db.execute(_schemaV10);
    _db.userVersion = _schemaVersion;
    _db.execute('COMMIT');
  }

  void _toV2() {
    _db.execute('''
      ALTER TABLE tracks ADD COLUMN favorite INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE tracks ADD COLUMN dir TEXT NOT NULL DEFAULT '';
      ALTER TABLE tracks ADD COLUMN rel_dir TEXT NOT NULL DEFAULT '';
      ALTER TABLE tracks ADD COLUMN format TEXT NOT NULL DEFAULT '';
    ''');
    final update = _db.prepare(
      'UPDATE tracks SET dir = ?, rel_dir = ?, format = ? WHERE id = ?',
    );
    for (final r in _db.select('''
      SELECT t.id, t.path, f.path AS folder
      FROM tracks t JOIN folders f ON f.id = t.folder_id
    ''')) {
      final path = r['path'] as String;
      update.execute([
        p.dirname(path),
        _relativeDir(path, r['folder'] as String),
        Track.formatOf(path),
        r['id'],
      ]);
    }
    update.dispose();
    _db.execute(_schemaV2Tables);
  }

  /// O ajuste da letra é pelo caminho, para valer também em quem está fora da
  /// biblioteca e voltar com a faixa.
  void _toV3() => _db.execute('''
    CREATE TABLE lyrics_offsets (
      path TEXT PRIMARY KEY,
      offset_ms INTEGER NOT NULL
    ) WITHOUT ROWID;
  ''');

  /// O que foi fixado. Sem chave estrangeira, porque aponta para três tabelas: o
  /// que sumiu da biblioteca só deixa de aparecer.
  void _toV4() => _db.execute('''
    CREATE TABLE pins (
      kind TEXT NOT NULL,
      ref INTEGER NOT NULL,
      pinned_at INTEGER NOT NULL,
      PRIMARY KEY (kind, ref)
    ) WITHOUT ROWID;
  ''');

  /// A marca de pular. Reler o arquivo não mexe nela, como no favorito.
  void _toV9() => _db.execute(
    'ALTER TABLE tracks ADD COLUMN skip INTEGER NOT NULL DEFAULT 0',
  );

  /// As regras de uma playlist inteligente, em JSON.
  void _toV8() => _db.execute('ALTER TABLE playlists ADD COLUMN rules TEXT');

  /// A capa que a pessoa escolheu para a playlist.
  void _toV7() =>
      _db.execute('ALTER TABLE playlists ADD COLUMN cover_path TEXT');

  /// A nota de cada faixa. Reler o arquivo não mexe nela, como no favorito.
  void _toV6() => _db.execute('''
    ALTER TABLE tracks ADD COLUMN rating INTEGER NOT NULL DEFAULT 0;
    CREATE INDEX tracks_rating ON tracks(rating) WHERE rating > 0;
  ''');

  /// Junta os álbuns partidos pelas participações, como `The Fame` de `Lady Gaga` e
  /// de `Lady Gaga/Colby O'Donis`. Reler os arquivos não faria isso: quem não mudou é
  /// pulado.
  void _toV5() {
    final albums = _db.select('''
      SELECT al.id, al.title, al.artist_id, al.cover_path, al.cover_source,
        al.year, a.name
      FROM albums al JOIN artists a ON a.id = al.artist_id
      ORDER BY al.id
    ''');
    final touchFts = _db.prepare(
      'UPDATE tracks SET album_id = ? WHERE album_id = ?',
    );
    for (final album in albums) {
      final name = album['name'] as String;
      final main = primaryArtist(name);
      if (main == name) continue;
      final id = album['id'] as int;
      final artist = _artist(main);
      final same = _db.select(
        'SELECT id FROM albums WHERE title = ? AND artist_id = ?',
        [album['title'], artist],
      );
      if (same.isEmpty) {
        _db.execute('UPDATE albums SET artist_id = ? WHERE id = ?', [
          artist,
          id,
        ]);
        // A busca guarda o artista do álbum: o gatilho refaz a linha
        touchFts.execute([id, id]);
        continue;
      }
      final target = same.first['id'] as int;
      _db.execute(
        '''
        UPDATE albums SET
          cover_path = COALESCE(cover_path, ?),
          cover_source = COALESCE(cover_source, ?),
          year = COALESCE(year, ?)
        WHERE id = ?
        ''',
        [album['cover_path'], album['cover_source'], album['year'], target],
      );
      touchFts.execute([target, id]);
      _db.execute(
        "UPDATE OR REPLACE pins SET ref = ? WHERE kind = 'album' AND ref = ?",
        [target, id],
      );
      _db.execute('DELETE FROM albums WHERE id = ?', [id]);
    }
    touchFts.dispose();
    _db.execute('''
      DELETE FROM artists
      WHERE id NOT IN (SELECT artist_id FROM albums)
        AND id NOT IN (SELECT artist_id FROM tracks);
    ''');
  }

  /// A pasta da faixa como a busca vê: a partir da pasta da biblioteca, com o nome
  /// dela. O resto do caminho (`/home/...`) acharia tudo.
  static String _relativeDir(String path, String folder) =>
      p.relative(p.dirname(path), from: p.dirname(folder));

  /// A biblioteca do sistema se chama assim no Debian, sem o pacote -dev. Vale
  /// por isolate.
  static void _useSystemLibrary() => open.overrideFor(
    OperatingSystem.linux,
    () => DynamicLibrary.open('libsqlite3.so.0'),
  );

  factory LibraryDb.open(String path) {
    _useSystemLibrary();
    final db = sqlite3.open(path);
    // O scanner escreve enquanto o app lê
    db.execute('PRAGMA journal_mode = WAL');
    db.execute('PRAGMA synchronous = NORMAL');
    return LibraryDb._(db);
  }

  /// Um banco já aberto, para testar a migração.
  @visibleForTesting
  factory LibraryDb.wrap(Database db) => LibraryDb._(db);

  factory LibraryDb.memory() {
    _useSystemLibrary();
    return LibraryDb._(sqlite3.openInMemory());
  }

  void close() => _db.dispose();

  void begin() => _db.execute('BEGIN IMMEDIATE');
  void commit() => _db.execute('COMMIT');

  // As pastas

  /// A pasta nova, ou a que já existia nesse caminho.
  int addFolder(String path) {
    _db.execute('INSERT OR IGNORE INTO folders (path) VALUES (?)', [path]);
    return _db.select('SELECT id FROM folders WHERE path = ?', [
          path,
        ]).first['id']
        as int;
  }

  /// Tira a pasta e as faixas dela, com o que ficar sem faixa nenhuma. Não
  /// mexe nos arquivos.
  void removeFolder(int id) {
    _db.execute('DELETE FROM folders WHERE id = ?', [id]);
    removeOrphans();
  }

  void markScanned(int id, int at) =>
      _db.execute('UPDATE folders SET scanned_at = ? WHERE id = ?', [at, id]);

  List<MusicFolder> folders() => [
    for (final r in _db.select('''
      SELECT f.id, f.path, f.scanned_at, COUNT(t.id) AS tracks,
        COUNT(DISTINCT t.album_id) AS albums, COALESCE(SUM(t.size), 0) AS size
      FROM folders f LEFT JOIN tracks t ON t.folder_id = f.id
      GROUP BY f.id ORDER BY f.path
    '''))
      MusicFolder(
        id: r['id'] as int,
        path: r['path'] as String,
        scannedAt: r['scanned_at'] as int?,
        albums: r['albums'] as int,
        tracks: r['tracks'] as int,
        size: r['size'] as int,
      ),
  ];

  // O que o scanner escreve

  /// O que já se conhece da pasta: caminho, e a data e o tamanho de quando foi
  /// lido, para não ler de novo o que não mudou.
  Map<String, (int, int)> knownFiles(int folderId) => {
    for (final r in _db.select(
      'SELECT path, mtime, size FROM tracks WHERE folder_id = ?',
      [folderId],
    ))
      r['path'] as String: (r['mtime'] as int, r['size'] as int),
  };

  /// As letras ao lado das faixas de [folderId], como a última leitura viu.
  Map<String, String?> knownLyrics(int folderId) => {
    for (final r in _db.select(
      'SELECT path, lyrics_path FROM tracks WHERE folder_id = ?',
      [folderId],
    ))
      r['path'] as String: r['lyrics_path'] as String?,
  };

  void setLyricsPath(String path, String? lyricsPath) => _db.execute(
    'UPDATE tracks SET lyrics_path = ? WHERE path = ?',
    [lyricsPath, path],
  );

  int _artist(String name) {
    _db.execute('INSERT OR IGNORE INTO artists (name) VALUES (?)', [name]);
    return _db.select('SELECT id FROM artists WHERE name = ?', [
          name,
        ]).first['id']
        as int;
  }

  /// Grava a faixa e devolve o álbum dela. Lê de novo sem perder as reproduções
  /// nem a data em que entrou.
  int upsertTrack(ScannedTrack t, int folderId, int now) {
    final folder =
        _db.select('SELECT path FROM folders WHERE id = ?', [
              folderId,
            ]).first['path']
            as String;
    final albumArtist = _artist(primaryArtist(t.albumArtist));
    _db.execute(
      'INSERT OR IGNORE INTO albums (title, artist_id, year) VALUES (?, ?, ?)',
      [t.album, albumArtist, t.year],
    );
    final albumId =
        _db.select('SELECT id FROM albums WHERE title = ? AND artist_id = ?', [
              t.album,
              albumArtist,
            ]).first['id']
            as int;
    if (t.year != null) {
      _db.execute('UPDATE albums SET year = ? WHERE id = ? AND year IS NULL', [
        t.year,
        albumId,
      ]);
    }
    _db.execute(
      '''
      INSERT INTO tracks (path, folder_id, album_id, artist_id, title,
        track_number, disc_number, year, genre, duration_ms, sample_rate,
        bitrate, size, mtime, lyrics_path, embedded_lyrics, added_at, dir,
        rel_dir, format, composer, comment)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT (path) DO UPDATE SET
        folder_id = excluded.folder_id, album_id = excluded.album_id,
        artist_id = excluded.artist_id, title = excluded.title,
        track_number = excluded.track_number,
        disc_number = excluded.disc_number, year = excluded.year,
        genre = excluded.genre, duration_ms = excluded.duration_ms,
        sample_rate = excluded.sample_rate, bitrate = excluded.bitrate,
        size = excluded.size, mtime = excluded.mtime,
        lyrics_path = excluded.lyrics_path,
        embedded_lyrics = excluded.embedded_lyrics, dir = excluded.dir,
        rel_dir = excluded.rel_dir, format = excluded.format,
        composer = excluded.composer, comment = excluded.comment
      ''',
      [
        t.path,
        folderId,
        albumId,
        _artist(t.artist),
        t.title,
        t.trackNumber,
        t.discNumber,
        t.year,
        t.genre,
        t.durationMs,
        t.sampleRate,
        t.bitrate,
        t.size,
        t.mtime,
        t.lyricsPath,
        t.embeddedLyrics ? 1 : 0,
        now,
        p.dirname(t.path),
        _relativeDir(t.path, folder),
        Track.formatOf(t.path),
        t.composer,
        t.comment,
      ],
    );
    return albumId;
  }

  bool albumHasCover(int id) =>
      _db.select('SELECT cover_path FROM albums WHERE id = ?', [
        id,
      ]).first['cover_path'] !=
      null;

  /// [source] diz de onde veio: `embedded` ou o nome do arquivo.
  void setAlbumCover(int id, String path, String source) => _db.execute(
    'UPDATE albums SET cover_path = ?, cover_source = ? WHERE id = ?',
    [path, source, id],
  );

  void removeTracks(Iterable<String> paths) {
    final statement = _db.prepare('DELETE FROM tracks WHERE path = ?');
    for (final path in paths) {
      statement.execute([path]);
    }
    statement.dispose();
  }

  /// Apaga os álbuns e artistas sem faixa, e devolve as capas que sobraram.
  /// O que o organizador precisa das faixas de [paths] ou da pasta [folderId].
  List<OrganizeItem> organizeItems({List<String>? paths, int? folderId}) {
    OrganizeItem item(Row r) => OrganizeItem(
      path: r['path'] as String,
      root: r['root'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      albumArtist: r['album_artist'] as String,
      album: r['album'] as String,
      trackNumber: r['track_number'] as int?,
      discNumber: r['disc_number'] as int?,
      multiDisc: (r['discs'] as int?) != null && r['discs'] as int > 1,
      year: r['year'] as int?,
      genre: r['genre'] as String?,
    );
    const from = '''
      SELECT t.path, f.path AS root, t.title, a.name AS artist,
        aa.name AS album_artist, al.title AS album, t.track_number,
        t.disc_number, t.year, t.genre,
        (SELECT MAX(t2.disc_number) FROM tracks t2
         WHERE t2.album_id = t.album_id) AS discs
      FROM tracks t
      JOIN folders f ON f.id = t.folder_id
      JOIN artists a ON a.id = t.artist_id
      JOIN albums al ON al.id = t.album_id
      JOIN artists aa ON aa.id = al.artist_id
    ''';
    if (folderId != null) {
      return [
        for (final r in _db.select(
          '$from WHERE t.folder_id = ? ORDER BY t.path',
          [folderId],
        ))
          item(r),
      ];
    }
    final out = <OrganizeItem>[];
    final list = paths ?? const <String>[];
    for (var i = 0; i < list.length; i += 500) {
      final part = list.sublist(i, min(i + 500, list.length));
      final marks = List.filled(part.length, '?').join(', ');
      out.addAll(_db.select('$from WHERE t.path IN ($marks)', part).map(item));
    }
    return out;
  }

  /// A faixa foi para [to]: fica o id, e com ele contagens, notas e favoritos.
  /// As playlists e o ajuste da letra, que guardam o caminho, vão junto.
  void moveTrackFile(String from, String to) {
    // Um arquivo com cue sheet: todas as faixas dele andam juntas
    final parts = [
      for (final r in _db.select(
        "SELECT path FROM tracks WHERE path >= ? AND path < ?",
        ['$from#cue:', '$from#cue;'],
      ))
        r['path'] as String,
    ];
    for (final path in parts) {
      _moveRow(path, '$to${CueRef.parse(path)!.suffix}');
    }
    if (parts.isEmpty) _moveRow(from, to);
  }

  void _moveRow(String from, String to) {
    final rows = _db.select(
      'SELECT f.path AS root FROM tracks t '
      'JOIN folders f ON f.id = t.folder_id WHERE t.path = ?',
      [from],
    );
    _db.execute('BEGIN IMMEDIATE');
    try {
      if (rows.isNotEmpty) {
        final root = rows.first['root'] as String;
        // O que estava lá não está mais: o organizador nunca passa por cima
        _db.execute('DELETE FROM tracks WHERE path = ?', [to]);
        _db.execute(
          'UPDATE tracks SET path = ?, dir = ?, rel_dir = ? WHERE path = ?',
          [to, p.dirname(to), _relativeDir(to, root), from],
        );
      }
      _db.execute('UPDATE playlist_tracks SET path = ? WHERE path = ?', [
        to,
        from,
      ]);
      _db.execute(
        'UPDATE OR REPLACE lyrics_offsets SET path = ? WHERE path = ?',
        [to, from],
      );
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void moveLyricsFile(String from, String to) => _db.execute(
    'UPDATE tracks SET lyrics_path = ? WHERE lyrics_path = ?',
    [to, from],
  );

  /// Esquece a capa embutida dos álbuns de [paths], para a próxima leitura tirar
  /// de novo, e devolve as miniaturas que ficaram velhas.
  List<String> forgetEmbeddedCovers(Iterable<String> paths) {
    final list = paths.toList();
    if (list.isEmpty) return const [];
    final marks = List.filled(list.length, '?').join(', ');
    final where =
        "cover_source = 'embedded' AND id IN "
        '(SELECT album_id FROM tracks WHERE path IN ($marks))';
    final covers = [
      for (final r in _db.select(
        'SELECT cover_path FROM albums WHERE $where',
        list,
      ))
        if (r['cover_path'] case final String path) path,
    ];
    _db.execute(
      'UPDATE albums SET cover_path = NULL, cover_source = NULL WHERE $where',
      list,
    );
    return covers;
  }

  List<String> removeOrphans() {
    final covers = [
      for (final r in _db.select('''
        SELECT cover_path FROM albums
        WHERE cover_path IS NOT NULL
          AND id NOT IN (SELECT album_id FROM tracks)
      '''))
        r['cover_path'] as String,
    ];
    _db.execute(
      'DELETE FROM albums WHERE id NOT IN (SELECT album_id FROM tracks)',
    );
    _db.execute('''
      DELETE FROM artists
      WHERE id NOT IN (SELECT artist_id FROM tracks)
        AND id NOT IN (SELECT artist_id FROM albums)
    ''');
    return covers;
  }

  // O que as telas leem

  LibraryTotals totals() {
    final r = _db.select('''
      SELECT COUNT(*) AS tracks, COUNT(DISTINCT album_id) AS albums,
        COALESCE(SUM(size), 0) AS size,
        COALESCE(SUM(duration_ms), 0) AS duration_ms
      FROM tracks
    ''').first;
    return LibraryTotals(
      albums: r['albums'] as int,
      tracks: r['tracks'] as int,
      size: r['size'] as int,
      duration: Duration(milliseconds: r['duration_ms'] as int),
    );
  }

  List<Album> albums([AlbumSort sort = AlbumSort.title]) => [
    for (final r in _db.select('$_albumSelect ORDER BY ${_albumOrder(sort)}'))
      _album(r),
  ];

  List<Album> recentAlbums(int limit) => [
    for (final r in _db.select(
      // Os álbuns de verdade antes das faixas soltas
      '$_albumSelect ORDER BY track_count > 1 DESC, added_at DESC, al.id DESC '
      'LIMIT ?',
      [limit],
    ))
      _album(r),
  ];

  List<Track> albumTracks(int albumId) => [
    for (final r in _db.select(
      '''
      SELECT $_trackColumns $_trackJoins WHERE t.album_id = ?
      ORDER BY COALESCE(t.disc_number, 1), t.track_number IS NULL,
        t.track_number, t.path
      ''',
      [albumId],
    ))
      _track(r),
  ];

  /// Só as que já tocaram.
  List<Track> mostPlayed(int limit) => [
    for (final r in _db.select(
      '''
      SELECT $_trackColumns $_trackJoins WHERE t.play_count > 0
      ORDER BY t.play_count DESC, t.last_played_at DESC LIMIT ?
      ''',
      [limit],
    ))
      _track(r),
  ];

  List<Track> randomTracks(int limit) => [
    for (final r in _db.select(
      'SELECT $_trackColumns $_trackJoins WHERE t.skip = 0 '
      'ORDER BY RANDOM() LIMIT ?',
      [limit],
    ))
      _track(r),
  ];

  /// As faixas que [query] pede. O que ela não restringe, não entra no WHERE.
  List<Track> tracks([TrackQuery query = const TrackQuery()]) {
    final where = <String>[];
    final args = <Object?>[];
    void filter(String clause, Object? arg) {
      where.add(clause);
      args.add(arg);
    }

    if (query.favorites) where.add('t.favorite = 1');
    if (query.skipped) where.add('t.skip = 1');
    if (query.withLyrics) {
      where.add('(t.lyrics_path IS NOT NULL OR t.embedded_lyrics = 1)');
    }
    if (query.format != null) filter('t.format = ?', query.format);
    if (query.artistId != null) filter('t.artist_id = ?', query.artistId);
    if (query.dir != null) filter('t.dir = ?', query.dir);
    if (query.singles) {
      where.add(
        't.album_id IN '
        '(SELECT album_id FROM tracks GROUP BY album_id HAVING COUNT(*) = 1)',
      );
    }
    if (query.genre != null) {
      filter("TRIM(COALESCE(t.genre, '')) = ?", query.genre);
    }
    final clause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final order = _trackOrder(query.sort, query.ascending);
    final found = [
      for (final r in _db.select(
        'SELECT $_trackColumns $_trackJoins $clause ORDER BY $order',
        args,
      ))
        _track(r),
    ];
    return query.duplicates ? duplicateTracks(found) : found;
  }

  /// Os formatos que existem, para os filtros.
  List<String> formats() => [
    for (final r in _db.select(
      "SELECT DISTINCT format FROM tracks WHERE format <> '' ORDER BY format",
    ))
      r['format'] as String,
  ];

  /// Quem está nas tags das faixas. O artista do álbum, como "Vários", agrupa o
  /// álbum e não vira um artista aqui.
  List<Artist> artists() => [
    for (final r in _db.select('''
      SELECT a.id, a.name, COUNT(*) AS tracks, COUNT(DISTINCT t.album_id) AS albums
      FROM tracks t JOIN artists a ON a.id = t.artist_id
      GROUP BY a.id ORDER BY a.name = '', a.name COLLATE $_collation
    '''))
      _artistFrom(r),
  ];

  Artist _artistFrom(Row r) => Artist(
    id: r['id'] as int,
    name: r['name'] as String,
    albums: r['albums'] as int,
    tracks: r['tracks'] as int,
  );

  /// Os álbuns em que o artista toca, mesmo que o álbum seja de outro.
  List<Album> artistAlbums(int artistId) => [
    for (final r in _db.select(
      '''
      $_albumFrom
      WHERE al.id IN (SELECT album_id FROM tracks WHERE artist_id = ?)
      GROUP BY al.id ORDER BY al.year IS NULL, al.year DESC
      ''',
      [artistId],
    ))
      _album(r),
  ];

  /// O nome vazio são as faixas sem gênero.
  List<Genre> genres() => [
    for (final r in _db.select('''
      SELECT TRIM(COALESCE(genre, '')) AS name, COUNT(*) AS tracks
      FROM tracks GROUP BY 1 ORDER BY name = '', tracks DESC
    '''))
      Genre(name: r['name'] as String, tracks: r['tracks'] as int),
  ];

  /// As pastas que têm música de verdade, não só as que foram adicionadas.
  List<MusicDir> dirs() => [
    for (final r in _db.select('''
      SELECT dir, COUNT(*) AS tracks, COUNT(DISTINCT album_id) AS albums
      FROM tracks GROUP BY dir ORDER BY dir COLLATE $_collation
    '''))
      _dirFrom(r),
  ];

  MusicDir _dirFrom(Row r) => MusicDir(
    path: r['dir'] as String,
    albums: r['albums'] as int,
    tracks: r['tracks'] as int,
  );

  void setFavorite(int trackId, bool favorite) => _db.execute(
    'UPDATE tracks SET favorite = ? WHERE id = ?',
    [favorite ? 1 : 0, trackId],
  );

  void setSkip(int trackId, bool skip) => _db.execute(
    'UPDATE tracks SET skip = ? WHERE id = ?',
    [skip ? 1 : 0, trackId],
  );

  void setRating(int trackId, int rating) => _db.execute(
    'UPDATE tracks SET rating = ? WHERE id = ?',
    [rating.clamp(0, 5), trackId],
  );

  // As playlists

  static const mostPlayedSize = 50;
  static const recentlyAddedSize = 30;
  static const topRatedSize = 50;

  int createPlaylist(String name, int now, [List<String> paths = const []]) {
    _db.execute(
      'INSERT INTO playlists (name, created_at, updated_at) VALUES (?, ?, ?)',
      [name, now, now],
    );
    final id = _db.lastInsertRowId;
    addToPlaylist(id, paths, now);
    return id;
  }

  void renamePlaylist(int id, String name, int now) => _db.execute(
    'UPDATE playlists SET name = ?, updated_at = ? WHERE id = ?',
    [name, now, id],
  );

  void deletePlaylist(int id) =>
      _db.execute('DELETE FROM playlists WHERE id = ?', [id]);

  /// Null volta às capas dos álbuns.
  void setPlaylistCover(int id, String? path, int now) => _db.execute(
    'UPDATE playlists SET cover_path = ?, updated_at = ? WHERE id = ?',
    [path, now, id],
  );

  void addToPlaylist(int id, List<String> paths, int now) {
    if (paths.isEmpty) return;
    final next =
        _db
                .select(
                  '''
          SELECT COALESCE(MAX(position) + 1, 0) AS next
          FROM playlist_tracks WHERE playlist_id = ?
          ''',
                  [id],
                )
                .first['next']
            as int;
    _rewrite(id, paths, now, from: next);
  }

  void _rewrite(int id, List<String> paths, int now, {int from = 0}) {
    _db.execute('BEGIN');
    if (from == 0) {
      _db.execute('DELETE FROM playlist_tracks WHERE playlist_id = ?', [id]);
    }
    final insert = _db.prepare(
      'INSERT INTO playlist_tracks (playlist_id, position, path) VALUES (?, ?, ?)',
    );
    for (var i = 0; i < paths.length; i++) {
      insert.execute([id, from + i, paths[i]]);
    }
    insert.dispose();
    _db.execute('UPDATE playlists SET updated_at = ? WHERE id = ?', [now, id]);
    _db.execute('COMMIT');
  }

  List<String> _playlistPaths(int id) => [
    for (final r in _db.select(
      'SELECT path FROM playlist_tracks WHERE playlist_id = ? ORDER BY position',
      [id],
    ))
      r['path'] as String,
  ];

  void removeFromPlaylist(int id, int index, int now) =>
      _rewrite(id, _playlistPaths(id)..removeAt(index), now);

  /// Depois de mover, a faixa fica em [to].
  void setPlaylistPaths(int id, List<String> paths, int now) =>
      _rewrite(id, paths, now);

  void movePlaylistTrack(int id, int from, int to, int now) {
    final paths = _playlistPaths(id);
    paths.insert(to, paths.removeAt(from));
    _rewrite(id, paths, now);
  }

  int createSmartPlaylist(String name, SmartRules rules, int now) {
    _db.execute(
      '''
      INSERT INTO playlists (name, created_at, updated_at, rules)
      VALUES (?, ?, ?, ?)
      ''',
      [name, now, now, rules.encode()],
    );
    return _db.lastInsertRowId;
  }

  void setPlaylistRules(int id, SmartRules rules, int now) => _db.execute(
    'UPDATE playlists SET rules = ?, updated_at = ? WHERE id = ?',
    [rules.encode(), now, id],
  );

  /// A condição das regras. Sem nenhuma, nada entra.
  static (String, List<Object?>) _smartWhere(SmartRules rules) {
    final clauses = <String>[];
    final args = <Object?>[];
    for (final rule in rules.rules) {
      final String column;
      final Object value;
      switch (rule.field) {
        case SmartField.genre:
          column = "TRIM(COALESCE(t.genre, ''))";
          value = rule.text;
        case SmartField.year:
          column = 't.year';
          value = rule.number;
        case SmartField.rating:
          column = 't.rating';
          value = rule.number;
      }
      final compare = switch (rule.op) {
        SmartOp.equals => '=',
        SmartOp.notEquals => '<>',
        SmartOp.atLeast => '>=',
        SmartOp.atMost => '<=',
      };
      final collate = rule.field == SmartField.genre
          ? ' COLLATE $_collation'
          : '';
      // "Nota no máximo 2" fala das que têm nota: as sem nota não são ruins
      final rated = rule.field == SmartField.rating ? 't.rating > 0 AND ' : '';
      clauses.add('($rated$column $compare ?$collate)');
      args.add(value);
    }
    if (clauses.isEmpty) return ('0', args);
    return (clauses.join(rules.matchAll ? ' AND ' : ' OR '), args);
  }

  List<Track> smartTracks(SmartRules rules) {
    final (where, args) = _smartWhere(rules);
    final order = _trackOrder(rules.sort, rules.ascending);
    return [
      for (final r in _db.select(
        '''
        SELECT $_trackColumns $_trackJoins WHERE $where ORDER BY $order LIMIT ?
        ''',
        [...args, rules.limit ?? -1],
      ))
        _track(r),
    ];
  }

  /// Quantas faixas as regras pegam, e quanto duram. Sem montar as faixas: isto
  /// roda a cada vez que a biblioteca recarrega.
  ({int tracks, Duration duration}) smartTotals(SmartRules rules) {
    final (where, args) = _smartWhere(rules);
    final order = _trackOrder(rules.sort, rules.ascending);
    final r = _db
        .select(
          '''
      SELECT COUNT(*) AS tracks, COALESCE(SUM(duration_ms), 0) AS duration_ms
      FROM (
        SELECT t.duration_ms $_trackJoins WHERE $where ORDER BY $order LIMIT ?
      )
      ''',
          [...args, rules.limit ?? -1],
        )
        .first;
    return (
      tracks: r['tracks'] as int,
      duration: Duration(milliseconds: r['duration_ms'] as int),
    );
  }

  List<({String? path, String seed})> _smartCovers(SmartRules rules) {
    final (where, args) = _smartWhere(rules);
    final order = _trackOrder(rules.sort, rules.ascending);
    return [
      for (final r in _db.select(
        '''
        WITH picked AS (
          SELECT t.album_id AS album, ROW_NUMBER() OVER (ORDER BY $order) AS at
          $_trackJoins WHERE $where ORDER BY $order LIMIT ?
        )
        SELECT al.cover_path, al.title, aa.name
        FROM picked
        JOIN albums al ON al.id = picked.album
        JOIN artists aa ON aa.id = al.artist_id
        WHERE al.cover_path IS NOT NULL
        GROUP BY al.id ORDER BY MIN(at) LIMIT 4
        ''',
        [...args, rules.limit ?? -1],
      ))
        (path: r['cover_path'] as String?, seed: '${r['title']}|${r['name']}'),
    ];
  }

  Playlist _smartPlaylist(Row r, SmartRules rules) {
    final totals = smartTotals(rules);
    final custom = r['cover_path'] as String?;
    return Playlist(
      id: r['id'] as int,
      name: r['name'] as String,
      trackCount: totals.tracks,
      duration: totals.duration,
      updatedAt: r['updated_at'] as int,
      customCover: custom,
      rules: rules,
      covers: custom != null
          ? [(path: custom, seed: r['name'] as String)]
          : _smartCovers(rules),
    );
  }

  List<Playlist> playlists() {
    final covers = _db.prepare('''
      SELECT al.cover_path, al.title, aa.name
      FROM playlist_tracks pt
      JOIN tracks t ON t.path = pt.path
      JOIN albums al ON al.id = t.album_id
      JOIN artists aa ON aa.id = al.artist_id
      WHERE pt.playlist_id = ? AND al.cover_path IS NOT NULL
      GROUP BY al.id ORDER BY MIN(pt.position) LIMIT 4
    ''');
    final found = [
      for (final r in _db.select('''
        SELECT p.id, p.name, p.cover_path, p.updated_at, p.rules,
          COUNT(pt.path) AS tracks,
          COALESCE(SUM(t.duration_ms), 0) AS duration_ms
        FROM playlists p
        LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
        LEFT JOIN tracks t ON t.path = pt.path
        GROUP BY p.id
      '''))
        if (r['rules'] case final String rules)
          _smartPlaylist(r, SmartRules.decode(rules))
        else
          Playlist(
            id: r['id'] as int,
            name: r['name'] as String,
            trackCount: r['tracks'] as int,
            duration: Duration(milliseconds: r['duration_ms'] as int),
            updatedAt: r['updated_at'] as int,
            customCover: r['cover_path'] as String?,
            covers: r['cover_path'] != null
                ? [
                    (
                      path: r['cover_path'] as String?,
                      seed: r['name'] as String,
                    ),
                  ]
                : [
                    for (final c in covers.select([r['id']]))
                      (
                        path: c['cover_path'] as String?,
                        seed: '${c['title']}|${c['name']}',
                      ),
                  ],
          ),
    ];
    covers.dispose();
    return found;
  }

  List<Track> playlistTracks(int id) => [
    for (final r in _db.select(
      '''
      SELECT pt.path AS entry, $_trackColumns
      FROM playlist_tracks pt
      LEFT JOIN tracks t ON t.path = pt.path
      LEFT JOIN artists a ON a.id = t.artist_id
      LEFT JOIN albums al ON al.id = t.album_id
      WHERE pt.playlist_id = ? ORDER BY pt.position
      ''',
      [id],
    ))
      r['id'] == null ? Track.fromPath(r['entry'] as String) : _track(r),
  ];

  List<Track> favorites() => tracks(const TrackQuery(favorites: true));

  List<Track> recentlyAdded(int limit) => [
    for (final r in _db.select(
      'SELECT $_trackColumns $_trackJoins '
      'ORDER BY t.added_at DESC, t.id DESC LIMIT ?',
      [limit],
    ))
      _track(r),
  ];

  /// As de 4 estrelas para cima, as melhores primeiro.
  List<Track> topRated(int limit) => [
    for (final r in _db.select(
      '''
      SELECT $_trackColumns $_trackJoins WHERE t.rating >= 4
      ORDER BY t.rating DESC, t.title COLLATE $_collation LIMIT ?
      ''',
      [limit],
    ))
      _track(r),
  ];

  /// As automáticas, com o que têm agora.
  List<Playlist> autoPlaylists() {
    Playlist summary(PlaylistKind kind, List<Track> tracks) => Playlist(
      id: 0,
      kind: kind,
      trackCount: tracks.length,
      duration: tracks.fold(Duration.zero, (sum, t) => sum + t.duration),
    );
    final top = topRated(topRatedSize);
    return [
      summary(PlaylistKind.favorites, favorites()),
      summary(PlaylistKind.mostPlayed, mostPlayed(mostPlayedSize)),
      summary(PlaylistKind.recentlyAdded, recentlyAdded(recentlyAddedSize)),
      // Só depois da primeira nota, para quem não dá nota não ver uma lista vazia
      if (top.isNotEmpty) summary(PlaylistKind.topRated, top),
    ];
  }

  // Os mixes

  /// Até quantas faixas um mix leva.
  static const mixSize = 50;

  /// Quantas faixas um gênero precisa para ter um mix.
  static const mixMinTracks = 10;
  static const mixGenres = 6;

  /// Uma ordem que parece ao acaso e é a mesma durante o dia.
  static String _dayOrder(int day) =>
      '(t.id * ${(day % 9972 + 1) * 48271 % 9973} % 9973)';

  /// Metade do que você já ouve e metade do que ainda não ouviu, intercaladas.
  List<Track> dailyMix(int day) {
    List<Track> pick(String where, int limit) => [
      for (final r in _db.select(
        'SELECT $_trackColumns $_trackJoins WHERE $where '
        'ORDER BY ${_dayOrder(day)} LIMIT ?',
        [limit],
      ))
        _track(r),
    ];
    // Uma estrela é a pessoa dizendo que não quer ouvir
    final known = pick(
      't.skip = 0 AND t.rating != 1 AND '
      '(t.play_count > 0 OR t.favorite = 1 OR t.rating > 1)',
      mixSize ~/ 2,
    );
    final fresh = pick(
      't.skip = 0 AND t.rating = 0 AND t.play_count = 0 AND t.favorite = 0',
      mixSize - known.length,
    );
    return [
      for (var i = 0; i < max(known.length, fresh.length); i++) ...[
        if (i < known.length) known[i],
        if (i < fresh.length) fresh[i],
      ],
    ];
  }

  /// O gênero, com as favoritas e as mais ouvidas puxadas para o começo.
  List<Track> genreMix(String genre, int day) => [
    for (final r in _db.select(
      '''
      SELECT $_trackColumns $_trackJoins
      WHERE TRIM(COALESCE(t.genre, '')) = ? AND t.rating != 1 AND t.skip = 0
      ORDER BY ${_dayOrder(day)} - t.favorite * 3000 - MIN(t.play_count, 3) * 1000
        - t.rating * 1000
      LIMIT ?
      ''',
      [genre, mixSize],
    ))
      _track(r),
  ];

  /// A próxima leva do mix dinâmico: ao acaso, puxando para as faixas com nota, as
  /// favoritas, as já ouvidas e as do mesmo gênero de [genre]. Sem as de uma
  /// estrela. O que está em [exclude] só volta se não sobrar mais nada.
  List<Track> dynamicMixBatch(
    int count, {
    List<String> exclude = const [],
    String? genre,
  }) {
    List<Track> pick(List<String> left) => [
      for (final r in _db.select(
        '''
        SELECT $_trackColumns $_trackJoins
        WHERE t.rating != 1 AND t.skip = 0
          AND t.path NOT IN (SELECT value FROM json_each(?))
        ORDER BY ABS(RANDOM() % 1000) - t.rating * 100 - t.favorite * 200
          - MIN(t.play_count, 3) * 50
          - (TRIM(COALESCE(t.genre, '')) = ?) * 300
        LIMIT ?
        ''',
        [jsonEncode(left), genre ?? '', count],
      ))
        _track(r),
    ];
    final tracks = pick(exclude);
    return tracks.isEmpty && exclude.isNotEmpty ? pick(const []) : tracks;
  }

  /// Os mixes de hoje: o do dia, e um por gênero com faixas o bastante.
  List<Playlist> mixes(int day) {
    Playlist summary(PlaylistKind kind, String name, List<Track> tracks) {
      final seen = <int>{};
      return Playlist(
        id: 0,
        kind: kind,
        name: name,
        trackCount: tracks.length,
        duration: tracks.fold(Duration.zero, (sum, t) => sum + t.duration),
        covers: [
          for (final t in tracks)
            if (t.coverPath != null && seen.length < 4 && seen.add(t.albumId))
              (path: t.coverPath, seed: '${t.album}|${t.artist}'),
        ],
      );
    }

    final daily = dailyMix(day);
    if (daily.length < mixMinTracks) return const [];
    return [
      summary(PlaylistKind.dailyMix, '', daily),
      for (final genre
          in genres()
              .where((g) => g.name.isNotEmpty && g.tracks >= mixMinTracks)
              .take(mixGenres))
        summary(PlaylistKind.genreMix, genre.name, genreMix(genre.name, day)),
    ];
  }

  // Os fixados

  void pin(PinKind kind, int ref, int now) => _db.execute(
    'INSERT OR REPLACE INTO pins (kind, ref, pinned_at) VALUES (?, ?, ?)',
    [kind.name, ref, now],
  );

  void unpin(PinKind kind, int ref) => _db.execute(
    'DELETE FROM pins WHERE kind = ? AND ref = ?',
    [kind.name, ref],
  );

  /// Os mais novos primeiro.
  List<(PinKind, int)> pins() => [
    for (final r in _db.select(
      'SELECT kind, ref FROM pins ORDER BY pinned_at DESC',
    ))
      if (PinKind.values.asNameMap()[r['kind']] case final kind?)
        (kind, r['ref'] as int),
  ];

  // A busca

  /// O que casa com [query], em cada grupo. As músicas vêm por relevância, com o
  /// título pesando mais.
  SearchResults search(String query, {int limit = 200}) {
    final terms = ftsTerms(query);
    if (terms.isEmpty) return const SearchResults();
    final inSongs =
        '{title artist album album_artist composer comment} : ($terms)';
    final tracks = [
      for (final r in _db.select(
        '''
        SELECT $_trackColumns
        FROM tracks_fts f
        JOIN tracks t ON t.id = f.rowid
        JOIN artists a ON a.id = t.artist_id
        JOIN albums al ON al.id = t.album_id
        WHERE tracks_fts MATCH ?
        ORDER BY bm25(tracks_fts, 10.0, 5.0, 5.0, 2.0, 0.0, 2.0, 1.0), t.id
        LIMIT ?
        ''',
        [inSongs, limit],
      ))
        _track(r),
    ];
    final albums = [
      for (final r in _db.select(
        '''
        $_albumFrom
        WHERE al.id IN (
          SELECT t2.album_id FROM tracks_fts f
          JOIN tracks t2 ON t2.id = f.rowid
          WHERE tracks_fts MATCH ?
        )
        GROUP BY al.id ORDER BY al.title COLLATE $_collation LIMIT ?
        ''',
        ['{album album_artist} : ($terms)', limit],
      ))
        _album(r),
    ];
    final artists = [
      for (final r in _db.select(
        '''
        SELECT a.id, a.name, COUNT(*) AS tracks, COUNT(DISTINCT t.album_id) AS albums
        FROM tracks t JOIN artists a ON a.id = t.artist_id
        WHERE a.id IN (
          SELECT t2.artist_id FROM tracks_fts f
          JOIN tracks t2 ON t2.id = f.rowid
          WHERE tracks_fts MATCH ?
        )
        GROUP BY a.id ORDER BY tracks DESC, a.name COLLATE $_collation LIMIT ?
        ''',
        ['{artist} : ($terms)', limit],
      ))
        _artistFrom(r),
    ];
    final dirs = [
      for (final r in _db.select(
        '''
        SELECT dir, COUNT(*) AS tracks, COUNT(DISTINCT album_id) AS albums
        FROM tracks
        WHERE dir IN (
          SELECT t2.dir FROM tracks_fts f
          JOIN tracks t2 ON t2.id = f.rowid
          WHERE tracks_fts MATCH ?
        )
        GROUP BY dir ORDER BY dir COLLATE $_collation LIMIT ?
        ''',
        ['{dir} : ($terms)', limit],
      ))
        _dirFrom(r),
    ];
    return SearchResults(
      query: query,
      tracks: tracks,
      albums: albums,
      artists: artists,
      dirs: dirs,
    );
  }

  /// As faixas nestes caminhos que estão na biblioteca, por caminho.
  Map<String, Track> tracksAt(List<String> paths) {
    final statement = _db.prepare(
      'SELECT $_trackColumns $_trackJoins WHERE t.path = ?',
    );
    final found = <String, Track>{};
    for (final path in paths) {
      final rows = statement.select([path]);
      if (rows.isNotEmpty) found[path] = _track(rows.first);
    }
    statement.dispose();
    return found;
  }

  /// O que o painel Capa conta além do que a [Track] já tem. Null fora da
  /// biblioteca.
  TrackDetails? trackDetails(String path) {
    final rows = _db.select(
      '''
      SELECT t.sample_rate, t.bitrate, al.cover_source
      FROM tracks t JOIN albums al ON al.id = t.album_id
      WHERE t.path = ?
      ''',
      [path],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return TrackDetails(
      sampleRate: r['sample_rate'] as int?,
      bitrate: r['bitrate'] as int?,
      coverSource: r['cover_source'] as String?,
    );
  }

  /// Em milissegundos. Positivo adianta a letra, como o `[offset]` do LRC.
  int lyricsOffset(String path) {
    final rows = _db.select(
      'SELECT offset_ms FROM lyrics_offsets WHERE path = ?',
      [path],
    );
    return rows.isEmpty ? 0 : rows.first['offset_ms'] as int;
  }

  void setLyricsOffset(String path, int offsetMs) => offsetMs == 0
      ? _db.execute('DELETE FROM lyrics_offsets WHERE path = ?', [path])
      : _db.execute(
          'INSERT OR REPLACE INTO lyrics_offsets (path, offset_ms) '
          'VALUES (?, ?)',
          [path, offsetMs],
        );

  void recordPlay(int trackId, int at) => _db.execute(
    '''
    UPDATE tracks SET play_count = play_count + 1, last_played_at = ?
    WHERE id = ?
    ''',
    [at, trackId],
  );

  // As preferências

  String? setting(String key) {
    final rows = _db.select('SELECT value FROM settings WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  void setSetting(String key, String value) => _db.execute(
    'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
    [key, value],
  );
}

// lib/src/library/models.dart
//
// O que a biblioteca guarda, como o resto do app vê. Tudo imutável e sem nada
// além de dados, para atravessar de um isolate para o outro.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Uma faixa. O [id] 0 é um arquivo fora da biblioteca, aberto de fora.
@immutable
class Track {
  final int id;
  final String path;
  final String title;

  /// Vazio quando a tag não diz.
  final String artist;
  final int albumId;
  final String album;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final Duration duration;

  /// A extensão em maiúsculas, como `FLAC`.
  final String format;

  /// O `.lrc` ou `.srt` ao lado da música.
  final String? lyricsPath;
  final bool embeddedLyrics;
  final String? coverPath;
  final int playCount;
  final String? genre;
  final bool favorite;

  /// De 1 a 5, e 0 sem nota.
  final int rating;

  /// Fica de fora quando uma lista toca, mas toca se for escolhida.
  final bool skip;

  const Track({
    this.id = 0,
    required this.path,
    required this.title,
    this.artist = '',
    this.albumId = 0,
    this.album = '',
    this.trackNumber,
    this.discNumber,
    this.year,
    this.duration = Duration.zero,
    required this.format,
    this.lyricsPath,
    this.embeddedLyrics = false,
    this.coverPath,
    this.playCount = 0,
    this.genre,
    this.favorite = false,
    this.rating = 0,
    this.skip = false,
  });

  Track withMarks({bool? favorite, int? rating, bool? skip}) => Track(
    id: id,
    path: path,
    title: title,
    artist: artist,
    albumId: albumId,
    album: album,
    trackNumber: trackNumber,
    discNumber: discNumber,
    year: year,
    duration: duration,
    format: format,
    lyricsPath: lyricsPath,
    embeddedLyrics: embeddedLyrics,
    coverPath: coverPath,
    playCount: playCount,
    genre: genre,
    favorite: favorite ?? this.favorite,
    rating: rating ?? this.rating,
    skip: skip ?? this.skip,
  );

  /// Um arquivo de que só se sabe o caminho.
  factory Track.fromPath(String path) => Track(
    path: path,
    title: p.basenameWithoutExtension(path),
    format: formatOf(path),
  );

  bool get hasLyrics => lyricsPath != null || embeddedLyrics;

  static String formatOf(String path) =>
      p.extension(path).replaceFirst('.', '').toUpperCase();
}

@immutable
class Album {
  final int id;
  final String title;

  /// Vazio quando a tag não diz.
  final String artist;
  final int? year;
  final String? coverPath;
  final int trackCount;
  final Duration duration;
  final int size;

  /// Os formatos das faixas, em maiúsculas.
  final List<String> formats;

  /// A pasta da primeira faixa.
  final String folder;

  const Album({
    required this.id,
    required this.title,
    this.artist = '',
    this.year,
    this.coverPath,
    this.trackCount = 0,
    this.duration = Duration.zero,
    this.size = 0,
    this.formats = const [],
    this.folder = '',
  });
}

/// Uma pasta da biblioteca.
@immutable
class MusicFolder {
  final int id;
  final String path;

  /// Em milissegundos desde a época, ou null antes da primeira leitura.
  final int? scannedAt;
  final int albums;
  final int tracks;
  final int size;

  const MusicFolder({
    required this.id,
    required this.path,
    this.scannedAt,
    this.albums = 0,
    this.tracks = 0,
    this.size = 0,
  });
}

@immutable
class LibraryTotals {
  final int albums;
  final int tracks;
  final int size;
  final Duration duration;

  const LibraryTotals({
    this.albums = 0,
    this.tracks = 0,
    this.size = 0,
    this.duration = Duration.zero,
  });
}

@immutable
class Artist {
  final int id;

  /// Vazio quando a tag não diz.
  final String name;
  final int albums;
  final int tracks;

  const Artist({
    required this.id,
    required this.name,
    this.albums = 0,
    this.tracks = 0,
  });
}

@immutable
class Genre {
  /// Vazio são as faixas sem gênero.
  final String name;
  final int tracks;

  const Genre({required this.name, this.tracks = 0});
}

/// Uma pasta com música dentro, em qualquer nível de uma pasta da biblioteca.
@immutable
class MusicDir {
  final String path;
  final int albums;
  final int tracks;

  const MusicDir({required this.path, this.albums = 0, this.tracks = 0});
}

enum PlaylistKind {
  manual,
  favorites,
  mostPlayed,
  recentlyAdded,
  topRated,
  dailyMix,
  genreMix,
}

/// O que uma regra de playlist inteligente olha.
enum SmartField { genre, year, rating }

/// Como ela compara.
enum SmartOp { equals, notEquals, atLeast, atMost }

/// Uma regra: gênero é "Rock", ano no mínimo 1990, nota no mínimo 4.
@immutable
class SmartRule {
  final SmartField field;
  final SmartOp op;

  /// O gênero.
  final String text;

  /// O ano ou a nota.
  final int number;

  const SmartRule(this.field, this.op, {this.text = '', this.number = 0});

  /// As comparações que fazem sentido em [field].
  static List<SmartOp> opsFor(SmartField field) => switch (field) {
    SmartField.genre => const [SmartOp.equals, SmartOp.notEquals],
    _ => const [SmartOp.equals, SmartOp.atLeast, SmartOp.atMost],
  };

  bool get valid => switch (field) {
    SmartField.genre => text.isNotEmpty,
    SmartField.year => number > 0,
    SmartField.rating => number >= 1 && number <= 5,
  };

  Map<String, Object> toJson() => {
    'field': field.name,
    'op': op.name,
    if (field == SmartField.genre) 'text': text else 'number': number,
  };

  /// Null se não dá para entender, para uma regra ruim não mudar o que entra.
  static SmartRule? fromJson(Object? json) {
    if (json is! Map) return null;
    final field = SmartField.values.asNameMap()[json['field']];
    final op = SmartOp.values.asNameMap()[json['op']];
    if (field == null || op == null) return null;
    final text = json['text'];
    final number = json['number'];
    return SmartRule(
      field,
      op,
      text: text is String ? text : '',
      number: number is int ? number : 0,
    );
  }
}

/// O que define uma playlist inteligente: quem entra, em que ordem e quantas.
@immutable
class SmartRules {
  final List<SmartRule> rules;

  /// Todas as regras, ou qualquer uma.
  final bool matchAll;
  final TrackSort sort;
  final bool ascending;

  /// Null sem limite.
  final int? limit;

  const SmartRules({
    required this.rules,
    this.matchAll = true,
    this.sort = TrackSort.title,
    this.ascending = true,
    this.limit,
  });

  bool get valid =>
      rules.isNotEmpty &&
      rules.every((rule) => rule.valid) &&
      (limit == null || limit! > 0);

  String encode() => jsonEncode({
    'rules': [for (final rule in rules) rule.toJson()],
    'matchAll': matchAll,
    'sort': sort.name,
    'ascending': ascending,
    if (limit != null) 'limit': limit,
  });

  /// Sem regra que se entenda, nenhuma faixa entra.
  factory SmartRules.decode(String text) {
    Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      json = null;
    }
    if (json is! Map) return const SmartRules(rules: []);
    final rules = json['rules'];
    final limit = json['limit'];
    return SmartRules(
      rules: rules is List
          ? rules.map(SmartRule.fromJson).nonNulls.toList()
          : const [],
      matchAll: json['matchAll'] != false,
      sort: TrackSort.values.asNameMap()[json['sort']] ?? TrackSort.title,
      ascending: json['ascending'] != false,
      limit: limit is int ? limit : null,
    );
  }
}

/// O que pode ser fixado.
enum PinKind { album, artist, playlist }

@immutable
class Playlist {
  /// 0 nas automáticas.
  final int id;
  final PlaylistKind kind;

  /// Vazio nas automáticas, que têm o nome na tela.
  final String name;
  final int trackCount;
  final Duration duration;
  final int updatedAt;

  /// As capas do mosaico, até quatro, só as que existem. Com a capa escolhida,
  /// só ela.
  final List<({String? path, String seed})> covers;

  /// A capa que a pessoa escolheu, se escolheu.
  final String? customCover;

  /// As regras, numa playlist inteligente.
  final SmartRules? rules;

  const Playlist({
    required this.id,
    this.kind = PlaylistKind.manual,
    this.name = '',
    this.trackCount = 0,
    this.duration = Duration.zero,
    this.updatedAt = 0,
    this.covers = const [],
    this.customCover,
    this.rules,
  });

  /// As faixas vêm das regras: não se escolhe nem se reordena à mão.
  bool get smart => rules != null;

  bool get automatic => kind != PlaylistKind.manual;

  /// Muda a cada dia, e mostra as capas das faixas.
  bool get mix =>
      kind == PlaylistKind.dailyMix || kind == PlaylistKind.genreMix;
}

enum AlbumSort { recent, title, artist, year }

enum TrackSort { title, album, artist, duration, format, added, rating, year }

/// Que faixas e em que ordem.
@immutable
class TrackQuery {
  final TrackSort sort;
  final bool ascending;
  final bool favorites;
  final bool withLyrics;
  final String? format;
  final int? artistId;

  /// O vazio são as sem gênero.
  final String? genre;
  final String? dir;

  /// Só as faixas sozinhas no álbum delas.
  final bool singles;

  /// Só as marcadas para pular.
  final bool skipped;

  /// Só as que parecem repetidas, uma perto da outra.
  final bool duplicates;

  const TrackQuery({
    this.sort = TrackSort.title,
    this.ascending = true,
    this.favorites = false,
    this.withLyrics = false,
    this.format,
    this.artistId,
    this.genre,
    this.dir,
    this.singles = false,
    this.skipped = false,
    this.duplicates = false,
  });

  TrackQuery sortedBy(TrackSort sort, bool ascending) => TrackQuery(
    sort: sort,
    ascending: ascending,
    favorites: favorites,
    withLyrics: withLyrics,
    format: format,
    artistId: artistId,
    genre: genre,
    dir: dir,
    singles: singles,
    skipped: skipped,
    duplicates: duplicates,
  );

  /// Os filtros da tela de músicas, um de cada vez.
  TrackQuery filtered({
    bool favorites = false,
    bool withLyrics = false,
    String? format,
    bool skipped = false,
    bool duplicates = false,
  }) => TrackQuery(
    sort: sort,
    ascending: ascending,
    favorites: favorites,
    withLyrics: withLyrics,
    format: format,
    artistId: artistId,
    genre: genre,
    dir: dir,
    singles: singles,
    skipped: skipped,
    duplicates: duplicates,
  );
}

/// O que só o painel Capa precisa saber de uma faixa.
@immutable
class TrackDetails {
  final int? sampleRate;

  /// Em bits por segundo.
  final int? bitrate;

  /// `embedded` ou o nome do arquivo, como `cover.jpg`. Null sem capa.
  final String? coverSource;

  const TrackDetails({this.sampleRate, this.bitrate, this.coverSource});
}

@immutable
class SearchResults {
  final String query;
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<MusicDir> dirs;

  const SearchResults({
    this.query = '',
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.dirs = const [],
  });

  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && dirs.isEmpty;

  /// O nome que tem as mesmas palavras da busca é o que a pessoa quis dizer. Sem
  /// nenhum assim, vale o artista, depois o álbum, depois a música.
  Object? get best {
    final words = _foldedWords(query);
    // O mesmo nome, ou o começo dele enquanto a pessoa digita
    bool exact(String name) {
      final own = _foldedWords(name);
      if (own.length != words.length) return false;
      for (var i = 0; i < own.length; i++) {
        if (!own[i].startsWith(words[i])) return false;
      }
      return true;
    }

    return artists.where((a) => exact(a.name)).firstOrNull ??
        albums.where((a) => exact(a.title)).firstOrNull ??
        tracks.where((t) => exact(t.title)).firstOrNull ??
        artists.firstOrNull ??
        albums.firstOrNull ??
        tracks.firstOrNull;
  }
}

List<String> _foldedWords(String text) => [
  for (final word in text.trim().split(RegExp(r'\s+')))
    String.fromCharCodes(word.codeUnits.map(_folded)),
];

/// Compara sem acento e sem diferenciar maiúsculas, sem criar texto: roda em
/// cada comparação de uma ordenação grande.
/// O artista principal de um crédito como `Lady Gaga/Beyoncé` ou `A feat. B`, que é
/// quem agrupa o álbum: sem isto, cada participação vira um álbum à parte. A vírgula e
/// o `&` não contam, porque fazem parte de nomes (`Simon & Garfunkel`).
String primaryArtist(String credit) {
  final main = credit
      .split(RegExp(r'\s+(?:feat\.?|ft\.?|featuring)\s+', caseSensitive: false))
      .first;
  final parts = main.split(RegExp(r'\s*[;/]\s*'));
  // Pedaços curtos são um nome só, como AC/DC
  if (parts.length < 2 || (parts[0].length < 3 && parts[1].length < 3)) {
    return main.trim();
  }
  return parts.first.trim();
}

/// A tela das faixas sozinhas no álbum, na pilha do que está aberto.
class SinglesEntry {
  const SinglesEntry();
}

/// O texto sem acentos nem maiúsculas, para comparar com o que se digita.
String foldedText(String text) =>
    String.fromCharCodes(text.codeUnits.map(_folded));

/// Quanto a duração pode variar entre duas cópias da mesma gravação. Mais do que
/// isso, costuma ser outra versão, como ao vivo.
const duplicateTolerance = Duration(seconds: 3);

/// As faixas com o mesmo título e o mesmo artista, sem ligar para maiúsculas e
/// acentos, e com a duração quase igual. Cada grupo fica junto, no lugar da primeira.
List<Track> duplicateTracks(Iterable<Track> tracks) {
  String key(String text) => String.fromCharCodes(text.codeUnits.map(_folded));
  final byName = <String, List<Track>>{};
  for (final track in tracks) {
    (byName['${key(track.title)}\u0000${key(track.artist)}'] ??= []).add(track);
  }
  final position = <Track, int>{};
  for (final (i, track) in tracks.indexed) {
    position[track] = i;
  }
  final groups = <List<Track>>[];
  for (final same in byName.values) {
    if (same.length < 2) continue;
    final sorted = same.toList()
      ..sort((a, b) => a.duration.compareTo(b.duration));
    var group = [sorted.first];
    for (final track in sorted.skip(1)) {
      if (track.duration - group.last.duration > duplicateTolerance) {
        if (group.length > 1) groups.add(group);
        group = [];
      }
      group.add(track);
    }
    if (group.length > 1) groups.add(group);
  }
  int first(List<Track> group) =>
      group.map((t) => position[t]!).reduce((a, b) => a < b ? a : b);
  groups.sort((a, b) => first(a).compareTo(first(b)));
  return [for (final group in groups) ...group];
}

int compareFolded(String? a, String? b) {
  final x = a ?? '';
  final y = b ?? '';
  final shared = x.length < y.length ? x.length : y.length;
  for (var i = 0; i < shared; i++) {
    final diff = _folded(x.codeUnitAt(i)) - _folded(y.codeUnitAt(i));
    if (diff != 0) return diff;
  }
  return x.length - y.length;
}

// De U+00C0 a U+00FF, a letra sem acento. O resto continua como está.
const _latin1Folded =
    'aaaaaaaceeeeiiiidnooooo\u00d7ouuuuy\u00fe\u00df'
    'aaaaaaaceeeeiiiidnooooo\u00f7ouuuuy\u00fey';

int _folded(int unit) {
  if (unit >= 0x41 && unit <= 0x5a) return unit + 0x20;
  if (unit >= 0xc0 && unit <= 0xff) {
    return _latin1Folded.codeUnitAt(unit - 0xc0);
  }
  return unit;
}

/// O que o scanner tira de um arquivo.
@immutable
class ScannedTrack {
  final String path;
  final String title;
  final String artist;

  /// Quem agrupa o álbum: o artista do álbum ou, sem ele, o da faixa.
  final String albumArtist;
  final String album;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final int durationMs;
  final int? sampleRate;
  final int? bitrate;
  final int size;
  final int mtime;
  final String? lyricsPath;
  final bool embeddedLyrics;
  final String? composer;
  final String? comment;

  const ScannedTrack({
    required this.path,
    required this.title,
    this.artist = '',
    this.albumArtist = '',
    this.album = '',
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.durationMs = 0,
    this.sampleRate,
    this.bitrate,
    this.size = 0,
    this.mtime = 0,
    this.lyricsPath,
    this.embeddedLyrics = false,
    this.composer,
    this.comment,
  });
}

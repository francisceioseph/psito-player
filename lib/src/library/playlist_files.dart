// lib/src/library/playlist_files.dart
//
// Os formatos de playlist além do M3U: XSPF e PLS. Quem escolhe o formato é a
// extensão do arquivo.
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'm3u.dart';
import 'models.dart';

enum PlaylistFormat {
  m3u8('M3U8'),
  xspf('XSPF'),
  pls('PLS');

  /// O nome do formato, igual em qualquer idioma.
  final String label;

  const PlaylistFormat(this.label);
}

/// Lê conforme a extensão de [path]. Qualquer outra é tratada como M3U.
M3uEntries parsePlaylist(Uint8List bytes, String path) {
  final base = p.dirname(path);
  return switch (p.extension(path).toLowerCase()) {
    '.xspf' => parseXspf(bytes, base),
    '.pls' => parsePls(bytes, base),
    _ => parseM3u(bytes, base),
  };
}

/// Escreve conforme a extensão de [path]. Qualquer outra é M3U.
String writePlaylist(List<Track> tracks, String path) =>
    switch (p.extension(path).toLowerCase()) {
      '.xspf' => writeXspf(tracks),
      '.pls' => writePls(tracks),
      _ => writeM3u(tracks),
    };

final _plsFile = RegExp(r'^file\d+\s*=\s*(.*)$', caseSensitive: false);

M3uEntries parsePls(Uint8List bytes, String base) {
  final paths = <String>[];
  var remote = 0;
  for (final line in decodePlaylistText(bytes).split(RegExp(r'\r?\n'))) {
    final file = _plsFile.firstMatch(line.trim())?[1]?.trim();
    if (file == null || file.isEmpty) continue;
    final path = resolvePlaylistEntry(file, base);
    if (path == null) {
      remote++;
    } else {
      paths.add(path);
    }
  }
  return M3uEntries(paths, remote: remote);
}

String writePls(List<Track> tracks) {
  final out = StringBuffer('[playlist]\n');
  for (final (i, track) in tracks.indexed) {
    final n = i + 1;
    final who = track.artist.isEmpty
        ? track.title
        : '${track.artist} - ${track.title}';
    out
      ..writeln('File$n=${track.path}')
      ..writeln('Title$n=$who')
      ..writeln('Length$n=${track.duration.inSeconds}');
  }
  out
    ..writeln('NumberOfEntries=${tracks.length}')
    ..writeln('Version=2');
  return out.toString();
}

final _xspfTrack = RegExp(
  r'<track\b[^>]*>(.*?)</track>',
  caseSensitive: false,
  dotAll: true,
);
final _xspfLocation = RegExp(
  r'<location\b[^>]*>(.*?)</location>',
  caseSensitive: false,
  dotAll: true,
);
final _xmlEntity = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);');
final _xmlComment = RegExp(r'<!--.*?-->', dotAll: true);

String _xmlDecode(String text) => text.replaceAllMapped(_xmlEntity, (m) {
  final name = m[1]!;
  return switch (name) {
    'amp' => '&',
    'lt' => '<',
    'gt' => '>',
    'quot' => '"',
    'apos' => "'",
    _ => String.fromCharCode(
      name.startsWith('#x')
          ? int.parse(name.substring(2), radix: 16)
          : int.parse(name.substring(1)),
    ),
  };
});

String _xmlEncode(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Só o que o XSPF usa, sem um leitor de XML inteiro: a primeira `location` de cada
/// `track`. É um URI, então um caminho relativo vem com os `%20`.
M3uEntries parseXspf(Uint8List bytes, String base) {
  final paths = <String>[];
  var remote = 0;
  final text = decodePlaylistText(bytes).replaceAll(_xmlComment, '');
  for (final track in _xspfTrack.allMatches(text)) {
    var location = _xspfLocation.firstMatch(track[1]!)?[1]?.trim();
    if (location == null || location.isEmpty) continue;
    if (location.startsWith('<![CDATA[') && location.endsWith(']]>')) {
      location = location.substring(9, location.length - 3);
    } else {
      location = _xmlDecode(location);
    }
    final String entry;
    try {
      entry = location.contains(':') ? location : Uri.decodeFull(location);
    } on ArgumentError {
      remote++;
      continue;
    }
    final path = resolvePlaylistEntry(entry, base);
    if (path == null) {
      remote++;
    } else {
      paths.add(path);
    }
  }
  return M3uEntries(paths, remote: remote);
}

String writeXspf(List<Track> tracks) {
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<playlist version="1" xmlns="http://xspf.org/ns/0/">')
    ..writeln('  <trackList>');
  for (final track in tracks) {
    out
      ..writeln('    <track>')
      ..writeln(
        '      <location>${_xmlEncode(Uri.file(track.path).toString())}</location>',
      )
      ..writeln('      <title>${_xmlEncode(track.title)}</title>');
    if (track.artist.isNotEmpty) {
      out.writeln('      <creator>${_xmlEncode(track.artist)}</creator>');
    }
    if (track.album.isNotEmpty) {
      out.writeln('      <album>${_xmlEncode(track.album)}</album>');
    }
    out
      ..writeln('      <duration>${track.duration.inMilliseconds}</duration>')
      ..writeln('    </track>');
  }
  out
    ..writeln('  </trackList>')
    ..writeln('</playlist>');
  return out.toString();
}

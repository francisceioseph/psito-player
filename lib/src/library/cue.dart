// lib/src/library/cue.dart
//
// As cue sheets: um arquivo de áudio inteiro, e um texto dizendo onde começa cada
// faixa. Só o texto: quem liga isto à biblioteca é o scanner.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../lyrics/lyrics_parser.dart' show decodeLyrics;
import 'tag_edit/flac.dart';

class CueSheetTrack {
  final int number;
  final String? title;
  final String? performer;
  final int startMs;

  const CueSheetTrack({
    required this.number,
    required this.startMs,
    this.title,
    this.performer,
  });
}

class CueSheet {
  final String? title;
  final String? performer;
  final String? genre;
  final int? year;
  final int fileCount;
  final List<CueSheetTrack> tracks;

  const CueSheet({
    this.title,
    this.performer,
    this.genre,
    this.year,
    this.fileCount = 1,
    this.tracks = const [],
  });

  /// Serve se é um arquivo só, com mais de uma faixa, em ordem.
  bool get usable {
    if (fileCount != 1 || tracks.length < 2) return false;
    for (var i = 1; i < tracks.length; i++) {
      if (tracks[i].startMs <= tracks[i - 1].startMs) return false;
    }
    return true;
  }
}

final _quoted = RegExp(r'^"(.*)"');
final _index = RegExp(r'^(\d+):(\d{1,2}):(\d{1,2})$');

String _value(String rest) {
  final text = rest.trim();
  return _quoted.firstMatch(text)?.group(1)?.trim() ?? text;
}

/// Lê o texto de uma cue sheet. O que não se entende fica de fora.
CueSheet parseCueSheet(String text) {
  String? title;
  String? performer;
  String? genre;
  int? year;
  var files = 0;
  final tracks = <CueSheetTrack>[];
  int? number;
  String? trackTitle;
  String? trackPerformer;
  int? start;

  void close() {
    if (number != null && start != null) {
      tracks.add(
        CueSheetTrack(
          number: number!,
          startMs: start!,
          title: trackTitle,
          performer: trackPerformer,
        ),
      );
    }
    number = null;
    trackTitle = null;
    trackPerformer = null;
    start = null;
  }

  for (final raw in const LineSplitter().convert(text.replaceFirst('﻿', ''))) {
    final line = raw.trim();
    final space = line.indexOf(RegExp(r'\s'));
    if (space < 0) continue;
    final command = line.substring(0, space).toUpperCase();
    final rest = line.substring(space + 1).trim();
    switch (command) {
      case 'FILE':
        files++;
      case 'TRACK':
        close();
        final parts = rest.split(RegExp(r'\s+'));
        if (parts.length >= 2 && parts[1].toUpperCase() == 'AUDIO') {
          number = int.tryParse(parts[0]);
        }
      case 'TITLE':
        if (number != null) {
          trackTitle = _value(rest);
        } else if (tracks.isEmpty) {
          title = _value(rest);
        }
      case 'PERFORMER':
        if (number != null) {
          trackPerformer = _value(rest);
        } else if (tracks.isEmpty) {
          performer = _value(rest);
        }
      case 'INDEX':
        final parts = rest.split(RegExp(r'\s+'));
        final mark = parts.length == 2 ? _index.firstMatch(parts[1]) : null;
        if (mark != null && int.tryParse(parts[0]) == 1) {
          final frames =
              int.parse(mark[1]!) * 60 * 75 +
              int.parse(mark[2]!) * 75 +
              int.parse(mark[3]!);
          start = frames * 1000 ~/ 75;
        }
      case 'REM':
        final space2 = rest.indexOf(RegExp(r'\s'));
        if (space2 < 0) break;
        final key = rest.substring(0, space2).toUpperCase();
        final value = _value(rest.substring(space2 + 1));
        if (key == 'GENRE') genre = value;
        if (key == 'DATE') {
          year = int.tryParse(RegExp(r'\d{4}').stringMatch(value) ?? '');
        }
    }
  }
  close();
  return CueSheet(
    title: title,
    performer: performer,
    genre: genre,
    year: year,
    fileCount: files == 0 ? 1 : files,
    tracks: tracks,
  );
}

/// A cue sheet de [audio], entre as de [cues] (por caminho em minúsculas):
/// `disco.cue` ou `disco.flac.cue`, ao lado dele.
String? findCueFile(String audio, Map<String, String> cues) =>
    cues['${p.withoutExtension(audio)}.cue'.toLowerCase()] ??
    cues['$audio.cue'.toLowerCase()];

/// A cue sheet do arquivo, ou nula se ela não servir.
CueSheet? readCueFile(String path) {
  try {
    final bytes = Uint8List.fromList(File(path).readAsBytesSync());
    final text = decodeLyrics(bytes);
    if (text == null) return null;
    final sheet = parseCueSheet(text);
    return sheet.usable ? sheet : null;
  } on FileSystemException {
    return null;
  }
}

/// A cue sheet guardada nos comentários de um FLAC (`CUESHEET`), ou nula.
CueSheet? readEmbeddedCue(String audio) {
  if (p.extension(audio).toLowerCase() != '.flac') return null;
  RandomAccessFile? file;
  try {
    file = File(audio).openSync();
    final comments = flacComments(file);
    final values = comments?.valuesOf(const ['CUESHEET']) ?? const <String>[];
    if (values.isEmpty) return null;
    final sheet = parseCueSheet(values.first);
    return sheet.usable ? sheet : null;
  } catch (_) {
    return null;
  } finally {
    file?.closeSync();
  }
}

// lib/src/lyrics/lyrics.dart
//
// A letra de uma faixa, já lida e em ordem de tempo. Só dados, para atravessar de
// um isolate para o outro.
import 'package:flutter/foundation.dart';

/// Um pedaço de uma linha com tempo próprio, do LRC estendido.
@immutable
class LyricWord {
  final Duration time;

  /// Com os espaços: juntos, os pedaços dão o texto da linha.
  final String text;

  const LyricWord(this.time, this.text);

  @override
  bool operator ==(Object other) =>
      other is LyricWord && other.time == time && other.text == text;

  @override
  int get hashCode => Object.hash(time, text);
}

@immutable
class LyricLine {
  /// Na letra sem tempo, zero.
  final Duration time;

  /// Vazio é uma pausa: um trecho sem canto, ou o espaço entre estrofes.
  final String text;

  /// Os pedaços com tempo, ou vazio numa linha comum.
  final List<LyricWord> words;

  const LyricLine(this.time, this.text, [this.words = const []]);

  /// O pedaço que vale em [position], ou -1 antes do primeiro.
  int wordAt(Duration position) {
    var found = -1;
    for (var i = 0; i < words.length; i++) {
      if (words[i].time > position) break;
      found = i;
    }
    return found;
  }

  @override
  bool operator ==(Object other) =>
      other is LyricLine &&
      other.time == time &&
      other.text == text &&
      listEquals(other.words, words);

  @override
  int get hashCode => Object.hash(time, text, Object.hashAll(words));

  @override
  String toString() => '[$time] $text';
}

@immutable
class Lyrics {
  final List<LyricLine> lines;
  final bool synced;

  /// O arquivo de onde veio, como `Correnteza.srt`. Null é a letra das tags.
  final String? fileName;

  const Lyrics({required this.lines, required this.synced, this.fileName});

  Lyrics from(String? fileName) =>
      Lyrics(lines: lines, synced: synced, fileName: fileName);

  /// A linha que vale em [position], ou -1 antes da primeira.
  int lineAt(Duration position) {
    if (!synced) return -1;
    var low = 0;
    var high = lines.length - 1;
    var found = -1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      if (lines[middle].time <= position) {
        found = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return found;
  }
}

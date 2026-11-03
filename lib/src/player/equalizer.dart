// lib/src/player/equalizer.dart
//
// O equalizador: as bandas, as predefinições e o filtro que o mpv recebe.
import 'dart:math';

import 'package:flutter/foundation.dart';

/// O centro de cada banda, em Hz, uma oitava de distância entre elas.
const equalizerBands = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

/// Até onde cada banda vai, para cima e para baixo, em dB.
const equalizerMaxGain = 12.0;

final flatEqualizer = List<double>.unmodifiable(
  List.filled(equalizerBands.length, 0.0),
);

enum EqualizerPreset {
  flat([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  rock([5, 4, 2, -1, -2, -1, 1, 3, 4, 5]),
  pop([-1, 1, 3, 4, 3, 0, -1, -1, 1, 2]),
  jazz([3, 2, 1, 2, -1, -1, 0, 1, 2, 3]),
  classical([4, 3, 2, 1, -1, -1, 0, 2, 3, 4]),
  electronic([5, 4, 1, 0, -2, 1, 0, 1, 4, 5]),
  bass([6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
  treble([0, 0, 0, 0, 0, 0, 2, 4, 5, 6]),
  vocal([-2, -3, -2, 1, 3, 4, 3, 2, 0, -1]);

  final List<double> gains;

  const EqualizerPreset(this.gains);

  /// A predefinição com esses ganhos, ou null se foram ajustados à mão.
  static EqualizerPreset? of(List<double> gains) {
    for (final preset in values) {
      if (listEquals(preset.gains, gains)) return preset;
    }
    return null;
  }
}

/// Quanto baixar o sinal para os ganhos não estourarem.
///
/// Os filtros têm uma oitava de largura e se somam: a banda vizinha empresta
/// quase um terço do ganho dela, conforme a resposta calculada dos filtros.
@visibleForTesting
double equalizerHeadroom(List<double> gains) {
  var headroom = 0.0;
  for (var i = 0; i < gains.length; i++) {
    final before = i == 0 ? 0.0 : max(0.0, gains[i - 1]);
    final after = i == gains.length - 1 ? 0.0 : max(0.0, gains[i + 1]);
    headroom = max(headroom, gains[i] + 0.3 * (before + after));
  }
  return headroom;
}

/// O valor do `af` do mpv. Vazio, com tudo em zero, tira o filtro, e a música
/// sai sem passar por ele.
String equalizerFilter(List<double> gains) {
  if (gains.every((g) => g == 0)) return '';
  return 'lavfi=[${['volume=${(-equalizerHeadroom(gains)).toStringAsFixed(1)}dB', for (var i = 0; i < gains.length; i++)
    if (gains[i] != 0) 'equalizer=f=${equalizerBands[i]}:t=o:w=1:'
          'g=${gains[i].toStringAsFixed(1)}'].join(',')}]';
}

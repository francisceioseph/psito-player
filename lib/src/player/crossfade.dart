// lib/src/player/crossfade.dart
//
// As contas do cruzamento de faixas, sem nada de som: quando começa e quanto dura.
import 'dart:math';

/// Quanto antes o outro tocador abre o arquivo, para estar pronto na hora.
const crossfadeLead = Duration(milliseconds: 1500);

/// A troca entre os dois tocadores, com a mesma faixa nos dois. Sem ela, os
/// milissegundos de diferença entre eles dariam para ouvir.
const crossfadeHandover = Duration(milliseconds: 350);

/// O fim da troca, com o tocador principal já calado.
const crossfadeSettle = Duration(milliseconds: 200);

/// Menos do que isto não soa como cruzamento, só como um corte estranho.
const crossfadeMinimum = Duration(seconds: 1);

/// Quanto dura o fade ao pausar e ao continuar.
const pauseFade = Duration(milliseconds: 250);

/// O plano de um cruzamento: a partir de [start], e por [fade].
typedef CrossfadePlan = ({Duration start, Duration fade});

/// O plano para uma faixa de [duration], ou null se não dá para cruzar. Numa faixa
/// curta, o cruzamento ocupa no máximo um terço dela. Depois de um salto para
/// perto do fim, ele começa logo depois de [position] e usa o que sobrou.
CrossfadePlan? planCrossfade({
  required Duration position,
  required Duration duration,
  required Duration length,
}) {
  if (length <= Duration.zero || duration <= Duration.zero) return null;
  final limit = duration ~/ 3;
  final wanted = length < limit ? length : limit;
  final earliest = duration - wanted - crossfadeHandover;
  final soonest = position + const Duration(milliseconds: 300);
  final start = earliest > soonest ? earliest : soonest;
  final fade = duration - start - crossfadeHandover;
  if (fade < crossfadeMinimum) return null;
  return (start: start, fade: fade);
}

/// O volume de quem entra, de 0 a 1, com a potência somada constante: sem o buraco
/// no meio que a reta dá.
double fadeIn(double t) => sin(t.clamp(0.0, 1.0) * pi / 2);

/// O volume de quem sai.
double fadeOut(double t) => cos(t.clamp(0.0, 1.0) * pi / 2);

/// O número que vai para o `volume` do mpv, que é uma curva cúbica, para dar a
/// amplitude [gain] em cima do volume da pessoa.
double mpvVolume(double volume, double gain) =>
    volume * 100 * pow(gain.clamp(0.0, 1.0), 1 / 3);

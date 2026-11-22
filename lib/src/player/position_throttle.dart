// lib/src/player/position_throttle.dart
//
// Quantas vezes a posição chega ao estado.

/// O mpv avisa a posição a cada pedaço de áudio, dezenas de vezes por segundo, e
/// cada aviso no estado refaz a tela. A barra e as letras não precisam disso: as
/// letras contam o tempo entre um aviso e outro. Passa um aviso a cada [every], e
/// na hora quando a música salta (procura, troca de faixa).
class PositionThrottle {
  PositionThrottle({
    this.every = const Duration(milliseconds: 250),
    Duration Function()? clock,
  }) : _clock = clock ?? _stopwatch();

  final Duration every;
  final Duration Function() _clock;

  Duration? _shown;
  Duration _shownAt = Duration.zero;

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// Se [position] vai ao estado agora.
  bool take(Duration position) {
    final now = _clock();
    final shown = _shown;
    final passed = now - _shownAt;
    // Andou mais do que o relógio: saltaram para a frente
    final jumped =
        shown == null ||
        position < shown ||
        position - shown > passed + every;
    if (!jumped && passed < every) return false;
    _shown = position;
    _shownAt = now;
    return true;
  }
}

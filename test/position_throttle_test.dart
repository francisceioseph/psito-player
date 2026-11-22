import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/player/position_throttle.dart';

void main() {
  late Duration now;
  late PositionThrottle throttle;
  Duration ms(int v) => Duration(milliseconds: v);

  setUp(() {
    now = Duration.zero;
    throttle = PositionThrottle(every: ms(250), clock: () => now);
  });

  /// O tocador andando junto com o relógio, um aviso a cada [step].
  List<int> play(int from, int to, {int step = 20}) {
    final taken = <int>[];
    for (var t = from; t <= to; t += step) {
      now = ms(t);
      if (throttle.take(ms(t))) taken.add(t);
    }
    return taken;
  }

  test('passa um aviso a cada intervalo', () {
    expect(play(0, 1000), [0, 260, 520, 780]);
  });

  test('uma procura para trás passa na hora', () {
    play(0, 600);
    now = ms(620);
    expect(throttle.take(ms(10)), isTrue);
  });

  test('uma procura para a frente passa na hora', () {
    play(0, 100);
    now = ms(120);
    expect(throttle.take(ms(60000)), isTrue);
  });

  test('a faixa nova, de volta ao começo, passa na hora', () {
    play(0, 5000);
    now = ms(5010);
    expect(throttle.take(Duration.zero), isTrue);
  });

  test('um aviso atrasado no tempo não conta como procura', () {
    play(0, 260);
    // O relógio andou 200 ms e a posição 300: o mpv só estava atrasado
    now = ms(460);
    expect(throttle.take(ms(560)), isFalse);
  });
}

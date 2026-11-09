// A instância única sem barramento. A trava é por processo no Linux, então os
// testes dizem quem a ganhou.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psito_player/src/platform/loopback_instance.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('psito-instance'));
  tearDown(() {
    // No Windows, a trava fica com a instância, que só some com o processo
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      return;
    }
  });

  Future<LoopbackInstance?> claim(bool wins, [List<String> paths = const []]) =>
      LoopbackInstance.acquire(dir.path, paths, tryLock: (_) async => wins);

  test('o primeiro fica, e recebe o que o segundo trouxe', () async {
    final first = await claim(true);
    expect(first, isNotNull);
    final got = first!.opens.first;
    var handed = false;
    final second = await LoopbackInstance.acquire(
      dir.path,
      ['/m/á b.flac'],
      beforeHandOff: () => handed = true,
      tryLock: (_) async => false,
    );
    expect(second, isNull);
    expect(handed, isTrue);
    expect(await got, ['/m/á b.flac']);
  });

  test('quem não sabe a senha é ignorado', () async {
    final first = await claim(true);
    final info = jsonDecode(
      File(p.join(dir.path, 'instance.json')).readAsStringSync(),
    ) as Map;
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      info['port'] as int,
    );
    socket.writeln(
      jsonEncode({
        'token': 'errada',
        'paths': ['/etc/passwd'],
      }),
    );
    await socket.flush();
    await socket.drain<void>();
    await claim(false, ['/m/certo.flac']);
    expect(await first!.opens.first, ['/m/certo.flac']);
  });

  test('sem dono respondendo, abre do mesmo jeito', () async {
    File(p.join(dir.path, 'instance.json'))
        .writeAsStringSync(jsonEncode({'port': 1, 'token': 'x'}));
    expect(await claim(false), isNotNull);
  }, timeout: const Timeout(Duration(seconds: 20)));
}

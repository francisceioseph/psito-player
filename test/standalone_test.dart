import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/standalone_app.dart';

void main() {
  test('os arquivos abertos são os caminhos e as URLs', () {
    expect(
      openedFiles(['--flag', '/m/a b.flac', 'file:///m/c%20d.mp3', 'solto.mp3']),
      ['/m/a b.flac', '/m/c d.mp3'],
    );
  });
}

// Os formatos de playlist além do M3U.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/models.dart';
import 'package:psito_player/src/library/playlist_files.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  final track = Track.fromPath('/m/Rock & Roll/a b.flac');

  group('PLS', () {
    test('lê caminhos, relativos e endereços da rede', () {
      final entries = parsePls(
        _bytes('''
[playlist]
File1=/m/a.flac
Title1=Uma
file2=sub/b.mp3
File3=http://radio/x.mp3
File4=file:///m/c%20d.ogg
NumberOfEntries=4
Version=2
'''),
        '/lista',
      );
      expect(entries.paths, ['/m/a.flac', '/lista/sub/b.mp3', '/m/c d.ogg']);
      expect(entries.remote, 1);
    });

    test('o que escreve, lê de volta', () {
      final text = writePls([track]);
      expect(text, contains('NumberOfEntries=1'));
      expect(parsePls(_bytes(text), '/x').paths, [track.path]);
    });
  });

  group('XSPF', () {
    test('lê a location de cada faixa, e só delas', () {
      final entries = parseXspf(
        _bytes('''
<?xml version="1.0"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
  <attribution><location>http://outra/lista.xspf</location></attribution>
  <trackList>
    <track><location>file:///m/Rock%20%26%20Roll/a.flac</location></track>
    <!-- <track><location>/m/comentada.flac</location></track> -->
    <track><title>Sem caminho</title></track>
    <track><location>sub/c%20d.mp3</location></track>
    <track><location>/m/x &amp; y.ogg</location></track>
    <track><location><![CDATA[/m/z.ogg]]></location></track>
    <track><location>https://site/y.mp3</location></track>
  </trackList>
</playlist>
'''),
        '/lista',
      );
      expect(entries.paths, [
        '/m/Rock & Roll/a.flac',
        '/lista/sub/c d.mp3',
        '/m/x & y.ogg',
        '/m/z.ogg',
      ]);
      expect(entries.remote, 1);
    });

    test('o que escreve, lê de volta, com o que o XML não aceita', () {
      final text = writeXspf([track]);
      expect(text, contains('<title>'));
      expect(text, isNot(contains('Rock & Roll')));
      expect(parseXspf(_bytes(text), '/x').paths, [track.path]);
    });
  });

  test('a extensão escolhe o formato', () {
    expect(writePlaylist([track], '/x/a.PLS'), startsWith('[playlist]'));
    expect(writePlaylist([track], '/x/a.xspf'), startsWith('<?xml'));
    expect(writePlaylist([track], '/x/a.m3u8'), startsWith('#EXTM3U'));
    expect(parsePlaylist(_bytes('/m/a.flac\n'), '/x/a.m3u').paths, [
      '/m/a.flac',
    ]);
    expect(parsePlaylist(_bytes('File1=/m/a.flac\n'), '/x/a.pls').paths, [
      '/m/a.flac',
    ]);
  });
}

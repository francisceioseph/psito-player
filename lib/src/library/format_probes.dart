// lib/src/library/format_probes.dart
//
// O que o leitor de tags não sabe: as tags do WMA, e a duração do AAC, do WavPack
// e do Monkey's Audio, que ficam no próprio áudio. Tudo a partir dos cabeçalhos,
// sem decodificar.
import 'dart:io';
import 'dart:typed_data';

import 'tags.dart';

/// O que o áudio diz de si.
class AudioInfo {
  final int durationMs;
  final int? sampleRate;
  final int? bitrate;

  const AudioInfo({required this.durationMs, this.sampleRate, this.bitrate});
}

AudioInfo _info(int samples, int rate, int fileSize) {
  final ms = samples * 1000 ~/ rate;
  return AudioInfo(
    durationMs: ms,
    sampleRate: rate,
    bitrate: ms == 0 ? null : fileSize * 8000 ~/ ms,
  );
}

Uint8List _head(File file, int length) {
  final reader = file.openSync();
  try {
    return reader.readSync(length);
  } finally {
    reader.closeSync();
  }
}

bool _startsWith(Uint8List bytes, String magic) {
  if (bytes.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic.codeUnitAt(i)) return false;
  }
  return true;
}

const _adtsRates = [
  96000,
  88200,
  64000,
  48000,
  44100,
  32000,
  24000,
  22050,
  16000,
  12000,
  11025,
  8000,
  7350,
];

/// Conta os quadros de um AAC cru (ADTS), que não diz a duração em lugar nenhum.
/// Pula o ID3v2 do começo, e para no que não for quadro, como um ID3v1 no fim.
AudioInfo? readAdtsInfo(File file) {
  final bytes = file.readAsBytesSync();
  var at = 0;
  if (_startsWith(bytes, 'ID3') && bytes.length >= 10) {
    at = 10 + (bytes[6] << 21 | bytes[7] << 14 | bytes[8] << 7 | bytes[9]);
  }
  int? rate;
  var samples = 0;
  while (at + 7 <= bytes.length) {
    if (bytes[at] != 0xFF || bytes[at + 1] & 0xF6 != 0xF0) break;
    final index = bytes[at + 2] >> 2 & 0xF;
    if (index >= _adtsRates.length) break;
    final length =
        (bytes[at + 3] & 3) << 11 | bytes[at + 4] << 3 | bytes[at + 5] >> 5;
    if (length < 7) break;
    rate ??= _adtsRates[index];
    samples += 1024 * ((bytes[at + 6] & 3) + 1);
    at += length;
  }
  return rate == null ? null : _info(samples, rate, bytes.length);
}

const _wavPackRates = [
  6000,
  8000,
  9600,
  11025,
  12000,
  16000,
  22050,
  24000,
  32000,
  44100,
  48000,
  64000,
  88200,
  96000,
  192000,
];

/// O primeiro bloco do WavPack traz o total de amostras. Quem gravou sem saber o
/// total deixa tudo em 1, e a duração fica para o motor.
AudioInfo? readWavPackInfo(File file) {
  final head = _head(file, 32);
  if (head.length < 32 || !_startsWith(head, 'wvpk')) return null;
  final data = ByteData.sublistView(head);
  final low = data.getUint32(12, Endian.little);
  if (low == 0xFFFFFFFF) return null;
  final high = head[11];
  final index = data.getUint32(24, Endian.little) >> 23 & 0xF;
  if (index >= _wavPackRates.length) return null;
  return _info(
    low + (high << 32) - high,
    _wavPackRates[index],
    file.lengthSync(),
  );
}

/// O cabeçalho do Monkey's Audio, que mudou de forma na versão 3.98.
AudioInfo? readMonkeysInfo(File file) {
  final head = _head(file, 256);
  if (head.length < 32 || !_startsWith(head, 'MAC ')) return null;
  final data = ByteData.sublistView(head);
  final version = data.getUint16(4, Endian.little);
  int perFrame, finalBlocks, frames, rate;
  if (version >= 3980) {
    final at = data.getUint32(8, Endian.little);
    if (at + 24 > head.length) return null;
    perFrame = data.getUint32(at + 4, Endian.little);
    finalBlocks = data.getUint32(at + 8, Endian.little);
    frames = data.getUint32(at + 12, Endian.little);
    rate = data.getUint32(at + 20, Endian.little);
  } else {
    final level = data.getUint16(6, Endian.little);
    rate = data.getUint32(12, Endian.little);
    frames = data.getUint32(24, Endian.little);
    finalBlocks = data.getUint32(28, Endian.little);
    perFrame = version >= 3950
        ? 73728 * 4
        : version >= 3900 || (version >= 3800 && level == 4000)
        ? 73728
        : 9216;
  }
  if (rate == 0 || frames == 0) return null;
  return _info((frames - 1) * perFrame + finalBlocks, rate, file.lengthSync());
}

// O ASF, o contêiner do WMA, é uma lista de objetos: 16 bytes de GUID e 8 de
// tamanho. Tudo o que interessa fica no objeto do cabeçalho.
const _asfHeader = '3026b2758e66cf11a6d900aa0062ce6c';
const _asfFile = 'a1dcab8c47a9cf118ee400c00c205365';
const _asfStream = '9107dcb7b7a9cf118ee600c00c205365';
const _asfAudio = '409e69f84d5bcf11a8fd00805f5c442b';
const _asfContent = '3326b2758e66cf11a6d900aa0062ce6c';
const _asfExtended = '40a4d0d207e3d21197f000a0c95ea850';

/// Um cabeçalho maior que isso não é de um arquivo de música.
const _asfHeaderLimit = 64 * 1024 * 1024;

String _guid(Uint8List bytes, int at) => [
  for (final b in bytes.sublist(at, at + 16))
    b.toRadixString(16).padLeft(2, '0'),
].join();

String? _utf16(Uint8List bytes, int at, int length) {
  final view = ByteData.sublistView(bytes, at, at + length);
  final units = <int>[];
  for (var i = 0; i + 1 < length; i += 2) {
    final unit = view.getUint16(i, Endian.little);
    if (unit == 0) break;
    units.add(unit);
  }
  final text = String.fromCharCodes(units).trim();
  return text.isEmpty ? null : text;
}

/// O `WM/Picture`: tipo, tamanho, MIME e descrição, e a imagem depois deles.
Uint8List? _asfPicture(Uint8List value) {
  if (value.length < 9) return null;
  final size = ByteData.sublistView(value).getUint32(1, Endian.little);
  var at = 5;
  for (var text = 0; text < 2; text++) {
    while (at + 1 < value.length && (value[at] != 0 || value[at + 1] != 0)) {
      at += 2;
    }
    at += 2;
  }
  if (at + size > value.length) return null;
  return value.sublist(at, at + size);
}

int? _leadingInt(String? text) =>
    text == null ? null : int.tryParse(RegExp(r'^\d+').stringMatch(text) ?? '');

/// Lança se não for um ASF.
FileTags readAsfTags(File file) {
  final start = _head(file, 30);
  if (start.length < 30 || _guid(start, 0) != _asfHeader) {
    throw const FormatException('não é um arquivo ASF');
  }
  final size = ByteData.sublistView(start).getUint64(16, Endian.little);
  if (size < 30 || size > _asfHeaderLimit) {
    throw const FormatException('cabeçalho ASF fora do esperado');
  }
  final bytes = _head(file, size);
  final data = ByteData.sublistView(bytes);

  String? title, artist;
  final texts = <String, String>{};
  final numbers = <String, int>{};
  Uint8List? cover;
  var durationMs = 0;
  int? sampleRate, bitrate;

  void content(int at) {
    final lengths = [
      for (var i = 0; i < 5; i++) data.getUint16(at + i * 2, Endian.little),
    ];
    title = _utf16(bytes, at + 10, lengths[0]);
    artist = _utf16(bytes, at + 10 + lengths[0], lengths[1]);
  }

  void extended(int at) {
    final count = data.getUint16(at, Endian.little);
    var pos = at + 2;
    for (var i = 0; i < count; i++) {
      final nameLength = data.getUint16(pos, Endian.little);
      final name = _utf16(bytes, pos + 2, nameLength) ?? '';
      pos += 2 + nameLength;
      final type = data.getUint16(pos, Endian.little);
      final length = data.getUint16(pos + 2, Endian.little);
      pos += 4;
      switch (type) {
        case 0:
          final text = _utf16(bytes, pos, length);
          if (text != null) texts[name] = text;
        case 1 when name == 'WM/Picture':
          cover ??= _asfPicture(bytes.sublist(pos, pos + length));
        case 3:
          numbers[name] = data.getUint32(pos, Endian.little);
        case 5:
          numbers[name] = data.getUint16(pos, Endian.little);
      }
      pos += length;
    }
  }

  var at = 30;
  while (at + 24 <= bytes.length) {
    final guid = _guid(bytes, at);
    final objectSize = data.getUint64(at + 16, Endian.little);
    if (objectSize < 24 || at + objectSize > bytes.length) break;
    switch (guid) {
      case _asfFile:
        final duration = data.getUint64(at + 64, Endian.little);
        final preroll = data.getUint64(at + 80, Endian.little);
        final ms = duration ~/ 10000 - preroll;
        if (ms > 0) durationMs = ms;
      case _asfStream when _guid(bytes, at + 24) == _asfAudio:
        sampleRate = data.getUint32(at + 82, Endian.little);
        bitrate = data.getUint32(at + 86, Endian.little) * 8;
      case _asfContent:
        content(at + 24);
      case _asfExtended:
        extended(at + 24);
    }
    at += objectSize;
  }

  int? number(String name) => numbers[name] ?? _leadingInt(texts[name]);
  // WM/Track conta a partir de zero, e WM/TrackNumber, que o substituiu, de um
  final zeroBased = number('WM/Track');
  // Há quem grave o título e o autor junto das outras, e não no próprio objeto
  return FileTags(
    title: title ?? texts['Title'],
    artist: artist ?? texts['Author'],
    albumArtist: texts['WM/AlbumArtist'],
    album: texts['WM/AlbumTitle'],
    trackNumber:
        number('WM/TrackNumber') ?? (zeroBased == null ? null : zeroBased + 1),
    discNumber: number('WM/PartOfSet'),
    year: number('WM/Year'),
    genre: texts['WM/Genre'],
    durationMs: durationMs,
    sampleRate: sampleRate,
    bitrate: bitrate,
    embeddedLyrics: texts['WM/Lyrics'] != null,
    cover: cover,
  );
}

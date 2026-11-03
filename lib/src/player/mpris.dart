// lib/src/player/mpris.dart
//
// Os controles do player para o sistema, pelo MPRIS: as teclas de mídia e o applet
// de som de qualquer desktop falam com este objeto.
import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import 'engine.dart';
import 'playback_controller.dart';

const _rootInterface = 'org.mpris.MediaPlayer2';
const _playerInterface = 'org.mpris.MediaPlayer2.Player';
const _noTrack = '/org/mpris/MediaPlayer2/TrackList/NoTrack';

/// Um pulo maior que isto, entre dois avisos do motor, é uma busca.
const _seekSlack = Duration(milliseconds: 1500);

/// Quem controla o player de fora pode tocar estes tipos.
const _mimeTypes = [
  'audio/flac',
  'audio/mpeg',
  'audio/ogg',
  'audio/opus',
  'audio/mp4',
  'audio/wav',
  'audio/aac',
  'audio/x-ms-wma',
  'audio/x-ape',
  'audio/x-wavpack',
  'audio/x-aiff',
];

const _introspection =
    '''
<node>
  <interface name="$_rootInterface">
    <method name="Raise"/>
    <method name="Quit"/>
    <property name="CanQuit" type="b" access="read"/>
    <property name="CanRaise" type="b" access="read"/>
    <property name="HasTrackList" type="b" access="read"/>
    <property name="Identity" type="s" access="read"/>
    <property name="DesktopEntry" type="s" access="read"/>
    <property name="SupportedUriSchemes" type="as" access="read"/>
    <property name="SupportedMimeTypes" type="as" access="read"/>
  </interface>
  <interface name="$_playerInterface">
    <method name="Next"/>
    <method name="Previous"/>
    <method name="Pause"/>
    <method name="PlayPause"/>
    <method name="Stop"/>
    <method name="Play"/>
    <method name="Seek"><arg name="Offset" type="x" direction="in"/></method>
    <method name="SetPosition">
      <arg name="TrackId" type="o" direction="in"/>
      <arg name="Position" type="x" direction="in"/>
    </method>
    <method name="OpenUri"><arg name="Uri" type="s" direction="in"/></method>
    <signal name="Seeked"><arg name="Position" type="x"/></signal>
    <property name="PlaybackStatus" type="s" access="read"/>
    <property name="LoopStatus" type="s" access="readwrite"/>
    <property name="Rate" type="d" access="readwrite"/>
    <property name="Shuffle" type="b" access="readwrite"/>
    <property name="Metadata" type="a{sv}" access="read"/>
    <property name="Volume" type="d" access="readwrite"/>
    <property name="Position" type="x" access="read"/>
    <property name="MinimumRate" type="d" access="read"/>
    <property name="MaximumRate" type="d" access="read"/>
    <property name="CanGoNext" type="b" access="read"/>
    <property name="CanGoPrevious" type="b" access="read"/>
    <property name="CanPlay" type="b" access="read"/>
    <property name="CanPause" type="b" access="read"/>
    <property name="CanSeek" type="b" access="read"/>
    <property name="CanControl" type="b" access="read"/>
  </interface>
</node>''';

/// Publica o [playback] no barramento. O [close] tira.
class Mpris extends DBusObject {
  /// Termina no id do app: é o nome que o sandbox do Psito deixa assumir.
  static const busName = 'org.mpris.MediaPlayer2.org.psito.player';

  final PlaybackController playback;
  final String identity;

  /// Traz a janela para a frente, se quem abriu o player sabe como.
  final Future<void> Function()? onRaise;
  final Future<void> Function() onQuit;

  DBusClient? _client;
  Map<String, DBusValue> _last = const {};
  Duration _lastPosition = Duration.zero;
  int _lastIndex = -1;
  bool _wasPlaying = false;
  final _sinceLast = Stopwatch()..start();

  Mpris(
    this.playback, {
    required this.identity,
    required this.onQuit,
    this.onRaise,
  }) : super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  /// Sem barramento ou sem o nome, o player toca do mesmo jeito.
  Future<bool> publish(DBusClient client) async {
    try {
      await client.registerObject(this);
      final reply = await client.requestName(
        busName,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      if (reply != DBusRequestNameReply.primaryOwner &&
          reply != DBusRequestNameReply.alreadyOwner) {
        debugPrint('🎵 MPRIS: o nome $busName já tem dono');
        await client.unregisterObject(this);
        return false;
      }
    } catch (e) {
      debugPrint('🎵 MPRIS indisponível: $e');
      return false;
    }
    _client = client;
    _last = _playerProperties();
    _lastPosition = _state.position;
    _lastIndex = _state.index;
    _wasPlaying = _state.playing;
    playback.engine.state.addListener(_onChange);
    playback.addListener(_onChange);
    return true;
  }

  Future<void> close() async {
    final client = _client;
    if (client == null) return;
    _client = null;
    playback.engine.state.removeListener(_onChange);
    playback.removeListener(_onChange);
    await client.releaseName(busName);
    await client.unregisterObject(this);
  }

  PlayerState get _state => playback.state;

  bool get _hasTrack => playback.current != null;

  String get _trackId {
    final index = _state.index;
    return _hasTrack ? '/org/psito/player/track/$index' : _noTrack;
  }

  static DBusInt64 _micros(Duration value) => DBusInt64(value.inMicroseconds);

  DBusDict _metadata() {
    final track = playback.current;
    final values = <String, DBusValue>{
      'mpris:trackid': DBusObjectPath(_trackId),
    };
    if (track != null) {
      final length = _state.duration > Duration.zero
          ? _state.duration
          : track.duration;
      values['mpris:length'] = _micros(length);
      values['xesam:url'] = DBusString(Uri.file(track.path).toString());
      values['xesam:title'] = DBusString(track.title);
      if (track.artist.isNotEmpty) {
        values['xesam:artist'] = DBusArray.string([track.artist]);
      }
      if (track.album.isNotEmpty) {
        values['xesam:album'] = DBusString(track.album);
      }
      if (track.trackNumber != null) {
        values['xesam:trackNumber'] = DBusInt32(track.trackNumber!);
      }
      if (track.coverPath != null) {
        values['mpris:artUrl'] = DBusString(
          Uri.file(track.coverPath!).toString(),
        );
      }
    }
    return DBusDict.stringVariant(values);
  }

  /// O que avisa quando muda. A posição não: o MPRIS só avisa as buscas.
  Map<String, DBusValue> _playerProperties() {
    final s = _state;
    final has = _hasTrack;
    return {
      'PlaybackStatus': DBusString(
        !has
            ? 'Stopped'
            : s.playing
            ? 'Playing'
            : 'Paused',
      ),
      'LoopStatus': DBusString(switch (s.repeat) {
        PlayerRepeat.off => 'None',
        PlayerRepeat.all => 'Playlist',
        PlayerRepeat.one => 'Track',
      }),
      'Rate': const DBusDouble(1),
      'Shuffle': DBusBoolean(s.shuffle),
      'Metadata': _metadata(),
      'Volume': DBusDouble(s.volume),
      'MinimumRate': const DBusDouble(1),
      'MaximumRate': const DBusDouble(1),
      'CanGoNext': DBusBoolean(has && s.index + 1 < s.queue.length),
      // Na primeira faixa, voltar reinicia
      'CanGoPrevious': DBusBoolean(has),
      'CanPlay': DBusBoolean(has),
      'CanPause': DBusBoolean(has),
      'CanSeek': DBusBoolean(has),
      'CanControl': const DBusBoolean(true),
    };
  }

  Map<String, DBusValue> _rootProperties() => {
    'CanQuit': const DBusBoolean(true),
    'CanRaise': DBusBoolean(onRaise != null),
    'HasTrackList': const DBusBoolean(false),
    'Identity': DBusString(identity),
    'DesktopEntry': const DBusString('org.psito.player'),
    'SupportedUriSchemes': DBusArray.string(const ['file']),
    'SupportedMimeTypes': DBusArray.string(_mimeTypes),
  };

  void _onChange() {
    final next = _playerProperties();
    final changed = <String, DBusValue>{
      for (final entry in next.entries)
        if (_last[entry.key] != entry.value) entry.key: entry.value,
    };
    _last = next;
    if (changed.isNotEmpty) {
      unawaited(
        emitPropertiesChanged(_playerInterface, changedProperties: changed),
      );
    }
    final s = _state;
    final expected =
        _lastPosition + (_wasPlaying ? _sinceLast.elapsed : Duration.zero);
    if (s.index == _lastIndex && (s.position - expected).abs() > _seekSlack) {
      unawaited(emitSignal(_playerInterface, 'Seeked', [_micros(s.position)]));
    }
    _lastPosition = s.position;
    _lastIndex = s.index;
    _wasPlaying = s.playing;
    _sinceLast.reset();
  }

  @override
  List<DBusIntrospectInterface> introspect() =>
      parseDBusIntrospectXml(_introspection).interfaces;

  Future<void> _seekTo(Duration position) {
    if (position < Duration.zero) position = Duration.zero;
    // Passar do fim é ir para a próxima, diz o MPRIS
    final duration = _state.duration;
    if (duration > Duration.zero && position > duration) return playback.next();
    return playback.engine.seek(position);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == _rootInterface) {
      switch (methodCall.name) {
        case 'Raise':
          await onRaise?.call();
          return DBusMethodSuccessResponse();
        case 'Quit':
          unawaited(onQuit());
          return DBusMethodSuccessResponse();
      }
    }
    if (methodCall.interface == _playerInterface) {
      final s = _state;
      switch (methodCall.name) {
        case 'Next':
          if (_hasTrack) await playback.next();
          return DBusMethodSuccessResponse();
        case 'Previous':
          if (_hasTrack) await playback.previous();
          return DBusMethodSuccessResponse();
        case 'PlayPause':
          if (_hasTrack) await playback.togglePlay();
          return DBusMethodSuccessResponse();
        case 'Play':
          if (_hasTrack && !s.playing) await playback.togglePlay();
          return DBusMethodSuccessResponse();
        case 'Pause':
          if (s.playing) await playback.togglePlay();
          return DBusMethodSuccessResponse();
        case 'Stop':
          if (s.playing) await playback.togglePlay();
          if (_hasTrack) await playback.engine.seek(Duration.zero);
          return DBusMethodSuccessResponse();
        case 'Seek':
          if (methodCall.signature != DBusSignature('x')) break;
          if (_hasTrack) {
            await _seekTo(
              s.position +
                  Duration(microseconds: methodCall.values[0].asInt64()),
            );
          }
          return DBusMethodSuccessResponse();
        case 'SetPosition':
          if (methodCall.signature != DBusSignature('ox')) break;
          // Um pedido para uma faixa que já passou não vale, diz o MPRIS
          if ((methodCall.values[0] as DBusObjectPath).value == _trackId) {
            final at = Duration(microseconds: methodCall.values[1].asInt64());
            if (at >= Duration.zero && at <= s.duration) {
              await playback.engine.seek(at);
            }
          }
          return DBusMethodSuccessResponse();
        case 'OpenUri':
          if (methodCall.signature != DBusSignature('s')) break;
          final uri = Uri.tryParse(methodCall.values[0].asString());
          if (uri == null || !uri.isScheme('file')) {
            return DBusMethodErrorResponse.invalidArgs('só file://');
          }
          await playback.playPaths([uri.toFilePath()]);
          return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  Map<String, DBusValue>? _properties(String interface) => switch (interface) {
    _rootInterface => _rootProperties(),
    _playerInterface => {
      ..._playerProperties(),
      'Position': _micros(_state.position),
    },
    _ => null,
  };

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final value = _properties(interface)?[name];
    return value == null
        ? DBusMethodErrorResponse.unknownProperty()
        : DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    final values = _properties(interface);
    return values == null
        ? DBusMethodErrorResponse.unknownInterface()
        : DBusGetAllPropertiesResponse(values);
  }

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) async {
    if (interface != _playerInterface) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    switch (name) {
      case 'Volume' when value is DBusDouble:
        await playback.engine.setVolume(value.value.clamp(0, 1));
      case 'Shuffle' when value is DBusBoolean:
        await playback.engine.setShuffle(value.value);
      case 'LoopStatus' when value is DBusString:
        final repeat = switch (value.value) {
          'None' => PlayerRepeat.off,
          'Playlist' => PlayerRepeat.all,
          'Track' => PlayerRepeat.one,
          _ => null,
        };
        if (repeat == null) return DBusMethodErrorResponse.invalidArgs();
        await playback.engine.setRepeat(repeat);
      // Só toca em velocidade normal, e o MPRIS manda aceitar e ignorar
      case 'Rate' when value is DBusDouble:
        break;
      default:
        return DBusMethodErrorResponse.propertyReadOnly();
    }
    return DBusMethodSuccessResponse();
  }
}

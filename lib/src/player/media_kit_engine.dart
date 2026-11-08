// lib/src/player/media_kit_engine.dart
//
// O motor de verdade: a libmpv do sistema, pelo FFI do media_kit.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;

import '../library/models.dart' show CueRef;
import 'crossfade.dart';
import 'engine.dart';
import 'equalizer.dart';

/// Onde o cruzamento está. Em [fading], a faixa nova já é a do tocador principal.
enum _Cross { idle, preparing, handover, fading }

/// O endereço de um pedaço de arquivo, no formato EDL do mpv. O `%n%` diz quantos
/// bytes tem o caminho, que pode ter vírgula.
String cueEdlAddress(CueRef ref) {
  String seconds(int ms) => (ms / 1000).toStringAsFixed(3);
  final size = utf8.encode(ref.file).length;
  return 'edl://%$size%${ref.file},'
      '${seconds(ref.startMs)},${seconds(ref.lengthMs)}';
}

class MediaKitEngine implements PlayerEngine {
  final _state = ValueNotifier(const PlayerState());
  late final Player _player;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// O que vai direto ao mpv, nos dois tocadores.
  final Map<String, String> options;

  /// O que os dois tocadores precisam ter igual, como o equalizador.
  final _shared = <String, String>{};

  /// Toca o fim da faixa antiga durante um cruzamento. O principal, que tem a fila
  /// e o estado, já foi para a nova: quem olha o motor vê uma troca de faixa comum.
  Player? _tail;
  Duration _crossfade = Duration.zero;
  bool _fadeOnPause = false;
  _Cross _cross = _Cross.idle;
  CrossfadePlan? _plan;
  String? _planPath;

  /// Por cima do volume da pessoa, que é o que o estado mostra.
  double _gain = 1;
  double _tailGain = 0;
  Timer? _ramp;

  @override
  bool Function(String from, String to)? crossfadeRule;

  /// Lança se a libmpv não abre. As [options] vão direto ao mpv, como a saída de
  /// som dos testes.
  MediaKitEngine({@visibleForTesting this.options = const {}}) {
    MediaKit.ensureInitialized();
    _player = _newPlayer();
    final stream = _player.stream;
    _subscriptions.addAll([
      stream.playing.listen((v) => _update(_state.value.copyWith(playing: v))),
      stream.playlist.listen(
        (v) => _update(
          _state.value.copyWith(
            queue: [for (final media in v.medias) _pathOf(media)],
            index: v.medias.isEmpty ? -1 : v.index,
            // O mpv pula o arquivo que não abre: o erro era da faixa de antes
            clearError: v.index != _state.value.index,
          ),
        ),
      ),
      stream.position.listen((v) {
        _update(_state.value.copyWith(position: v));
        _watchCrossfade(v);
      }),
      stream.duration.listen((v) {
        _update(_state.value.copyWith(duration: v));
        unawaited(_readTrack());
      }),
      stream.audioParams.listen((_) => unawaited(_readTrack())),
      stream.completed.listen((done) {
        if (done && _state.value.stopAfter) unawaited(_stopHere());
      }),
      stream.error.listen((message) {
        debugPrint('🎵 erro do mpv: $message');
        _update(_state.value.copyWith(error: message));
      }),
      stream.log.listen(
        (log) => debugPrint('🎵 mpv ${log.prefix}: ${log.text}'),
      ),
    ]);
  }

  void _update(PlayerState state) => _state.value = state;

  Player _newPlayer() {
    final player = Player(
      configuration: const PlayerConfiguration(
        // Só áudio: sem saída de vídeo nem legendas, e 4 MB em vez de 32 MB de
        // leitura adiantada, que num arquivo local não faz falta
        vo: 'null',
        libass: false,
        bufferSize: 4 * 1024 * 1024,
        logLevel: MPVLogLevel.warn,
      ),
    );
    // O padrão do media_kit grava em ~/.cache/mpv, que é para streams
    final native = player.platform as NativePlayer;
    unawaited(native.setProperty('cache', 'no'));
    unawaited(native.setProperty('cache-on-disk', 'no'));
    // Música não precisa de pouca latência, e o processo no sandbox não tem
    // prioridade de tempo real: 100 ms em vez do quantum do PipeWire (21 ms)
    unawaited(native.setProperty('pipewire-buffer', '100'));
    // A capa embutida conta como vídeo: sem isto, o mpv decodifica a de cada faixa
    unawaited(native.setProperty('vid', 'no'));
    // O mpv tenta abrir o .lrc e o .srt ao lado da música como legenda, não
    // consegue e avisa como erro. Quem lê as letras é o app
    unawaited(native.setProperty('sub-auto', 'no'));
    for (final option in options.entries) {
      unawaited(native.setProperty(option.key, option.value));
    }
    for (final option in _shared.entries) {
      unawaited(native.setProperty(option.key, option.value));
    }
    return player;
  }

  /// Vale para o tocador principal, para o do fim da faixa e para quem ele vier a
  /// ser.
  Future<void> _setShared(String name, String value) async {
    _shared[name] = value;
    await (_player.platform as NativePlayer).setProperty(name, value);
    final tail = _tail;
    if (tail != null) {
      await (tail.platform as NativePlayer).setProperty(name, value);
    }
  }

  void _applyVolume() {
    final volume = _state.value.volume;
    unawaited(_player.setVolume(mpvVolume(volume, _gain)));
    final tail = _tail;
    if (tail != null) unawaited(tail.setVolume(mpvVolume(volume, _tailGain)));
  }

  /// Chama [apply] de 0 a 1 ao longo de [length], e [done] no fim. Só uma de cada
  /// vez: a nova toma o lugar da outra, sem o [done] dela.
  void _startRamp(
    Duration length,
    void Function(double t) apply, {
    VoidCallback? done,
  }) {
    _ramp?.cancel();
    final clock = Stopwatch()..start();
    _ramp = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      final t = clock.elapsedMicroseconds / length.inMicroseconds;
      apply(t.clamp(0.0, 1.0));
      _applyVolume();
      if (t < 1) return;
      timer.cancel();
      _ramp = null;
      done?.call();
    });
  }

  /// O caminho da faixa seguinte, se esta pode cruzar com ela.
  String? _crossfadeTarget() {
    final s = _state.value;
    if (!s.playing || s.stopAfter || s.repeat == PlayerRepeat.one) return null;
    if (s.index < 0 || s.queue.length < 2) return null;
    final next = s.index + 1;
    if (next >= s.queue.length && s.repeat != PlayerRepeat.all) return null;
    final from = s.queue[s.index];
    final to = s.queue[next % s.queue.length];
    return crossfadeRule?.call(from, to) ?? true ? to : null;
  }

  void _watchCrossfade(Duration position) {
    if (_crossfade <= Duration.zero) return;
    final s = _state.value;
    switch (_cross) {
      case _Cross.idle:
        if (_crossfadeTarget() == null) return;
        final plan = planCrossfade(
          position: position,
          duration: s.duration,
          length: _crossfade,
        );
        if (plan == null || position < plan.start - crossfadeLead) return;
        _cross = _Cross.preparing;
        _plan = plan;
        _planPath = s.queue[s.index];
        final tail = _tail ??= _newPlayer();
        unawaited(tail.setVolume(0));
        unawaited(
          tail.open(
            Playlist([_media(_planPath!, start: plan.start)]),
            play: false,
          ),
        );
      case _Cross.preparing:
        final plan = _plan!;
        final same = s.index >= 0 && s.queue[s.index] == _planPath;
        // Saltaram para longe, ou a faixa mudou: outro plano, se for o caso
        final away =
            position < plan.start - crossfadeLead * 2 ||
            position > plan.start + const Duration(seconds: 1);
        if (!same || away || _crossfadeTarget() == null) {
          _cancelCrossfade();
        } else if (position >= plan.start) {
          _handOver(plan);
        }
      case _Cross.handover:
      case _Cross.fading:
        break;
    }
  }

  void _handOver(CrossfadePlan plan) {
    _cross = _Cross.handover;
    _tailGain = 0;
    unawaited(_tail!.play());
    _startRamp(
      crossfadeHandover - crossfadeSettle,
      (t) {
        _gain = fadeOut(t);
        _tailGain = fadeIn(t);
      },
      // O volume leva o tamanho da saída para chegar ao som, e a troca de faixa
      // corta na hora: sem esperar, o outro ainda está baixo e o som afunda
      done: () => _ramp = Timer(crossfadeSettle, () {
        _ramp = null;
        _cross = _Cross.fading;
        _gain = 0;
        _applyVolume();
        unawaited(_player.next());
        _startRamp(plan.fade, (t) {
          _gain = fadeIn(t);
          _tailGain = fadeOut(t);
        }, done: _cancelCrossfade);
      }),
    );
  }

  /// Volta ao estado de sempre: só o tocador principal, no volume da pessoa.
  void _cancelCrossfade() {
    final idle = _cross == _Cross.idle;
    _cross = _Cross.idle;
    _plan = null;
    _planPath = null;
    if (idle) return;
    _ramp?.cancel();
    _ramp = null;
    _gain = 1;
    _tailGain = 0;
    _applyVolume();
    unawaited(_tail?.stop());
  }

  /// Numa troca pedida no meio da passagem, a faixa ainda é a mesma nos dois: não
  /// tem o que sobrepor. Depois dela, o fim da antiga termina de sair sozinho.
  void _cancelHandover() {
    if (_cross != _Cross.fading) _cancelCrossfade();
  }

  // Com o `keep-open` em `always`, o mpv pausa no fim de cada arquivo, em vez de
  // seguir. Marcar a seguinte com o `jump` do media_kit tocaria um pedaço dela
  Future<void> _stopHere() async {
    final native = _player.platform as NativePlayer;
    final s = _state.value;
    await setStopAfter(false);
    await _player.pause();
    if (s.index + 1 < s.queue.length) {
      await native.setProperty('playlist-pos', '${s.index + 1}');
    }
  }

  /// O `repeat one` nunca chega ao fim do arquivo: enquanto vale o parar, fica de
  /// lado.
  Future<void> _applyRepeat() {
    final s = _state.value;
    return _player.setPlaylistMode(switch (s.repeat) {
      PlayerRepeat.off => PlaylistMode.none,
      PlayerRepeat.all => PlaylistMode.loop,
      PlayerRepeat.one when s.stopAfter => PlaylistMode.none,
      PlayerRepeat.one => PlaylistMode.single,
    });
  }

  /// O `Media` guarda o caminho como URI.
  String _pathOf(Media media) =>
      _cuePaths[media.uri] ??
      (media.uri.startsWith('file:')
          ? Uri.parse(media.uri).toFilePath()
          : media.uri);

  /// As faixas de cue sheet, por endereço de EDL, para voltar ao caminho delas.
  final _cuePaths = <String, String>{};

  /// O que o mpv abre: o arquivo, ou o pedaço dele numa faixa de cue sheet.
  Media _media(String path, {Duration? start}) {
    final ref = CueRef.parse(path);
    if (ref == null) return Media(path, start: start);
    final uri = cueEdlAddress(ref);
    _cuePaths[uri] = path;
    return Media(uri, start: start);
  }

  /// O título e o formato ficam em propriedades que o media_kit não publica.
  Future<void> _readTrack() async {
    final native = _player.platform as NativePlayer;
    final title = await native.getProperty('media-title');
    final codec = await native.getProperty('audio-codec-name');
    final ao = await native.getProperty('current-ao');
    final params = _player.state.audioParams;
    final format = codec.isEmpty || params.sampleRate == null
        ? null
        : '$codec ${params.sampleRate} Hz ${params.format} '
              '${params.channelCount} ch';
    final changed =
        format != null && format != _state.value.format ||
        title != _state.value.title;
    _update(
      _state.value.copyWith(
        title: title.isEmpty ? null : title,
        format: format,
      ),
    );
    if (changed && format != null) {
      debugPrint('🎵 tocando "$title": $format, saída $ao');
    }
  }

  @override
  ValueListenable<PlayerState> get state => _state;

  @override
  Future<void> open(
    List<String> paths, {
    int index = 0,
    Duration start = Duration.zero,
    bool play = true,
  }) async {
    _cancelCrossfade();
    final old = _state.value;
    if (old.stopAfter) await setStopAfter(false);
    _update(
      PlayerState(volume: old.volume, shuffle: false, repeat: old.repeat),
    );
    await _player.setShuffle(false);
    await _player.open(
      Playlist(paths.map(_media).toList(), index: index),
      play: play,
    );
    if (start > Duration.zero) {
      // Antes de o arquivo carregar, o mpv ignora o seek
      await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 5));
      await _player.seek(start);
    }
  }

  @override
  Future<void> playOrPause() async {
    // A faixa antiga não fica esperando: quem continua, continua na nova
    _cancelCrossfade();
    if (!_fadeOnPause) return _player.playOrPause();
    if (_state.value.playing) {
      _update(_state.value.copyWith(playing: false));
      final from = _gain;
      _startRamp(
        pauseFade,
        (t) => _gain = from * (1 - t),
        done: () async {
          await _player.pause();
          _gain = 1;
          _applyVolume();
        },
      );
      return;
    }
    // Se ainda estava baixando, sobe de onde parou
    final from = _ramp == null ? 0.0 : _gain;
    _ramp?.cancel();
    _ramp = null;
    _gain = from;
    _applyVolume();
    await _player.play();
    _startRamp(pauseFade, (t) => _gain = from + (1 - from) * t);
  }

  @override
  Future<void> next() {
    _cancelHandover();
    return _player.next();
  }

  @override
  Future<void> previous() {
    _cancelHandover();
    return _player.previous();
  }

  @override
  Future<void> jump(int index) {
    _cancelHandover();
    return _player.jump(index);
  }

  @override
  Future<void> add(String path) => _player.add(_media(path));

  @override
  // No mpv, o destino é a faixa que perde o lugar: para descer até [to], é a de
  // depois dela
  Future<void> move(int from, int to) =>
      _player.move(from, to > from ? to + 1 : to);

  @override
  Future<void> remove(int index) => _player.remove(index);

  @override
  Future<void> setShuffle(bool shuffle) async {
    await _player.setShuffle(shuffle);
    _update(_state.value.copyWith(shuffle: shuffle));
    // O mpv embaralha a fila inteira: a atual vai para o começo, para todo o
    // resto ainda tocar
    final index = _player.state.playlist.index;
    if (shuffle && index > 0) await _player.move(index, 0);
  }

  @override
  Future<void> setRepeat(PlayerRepeat repeat) async {
    _update(_state.value.copyWith(repeat: repeat));
    await _applyRepeat();
  }

  @override
  Future<void> setStopAfter(bool stop) async {
    _update(_state.value.copyWith(stopAfter: stop));
    await (_player.platform as NativePlayer).setProperty(
      'keep-open',
      stop ? 'always' : 'yes',
    );
    await _applyRepeat();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) async {
    _update(_state.value.copyWith(volume: volume));
    _applyVolume();
  }

  @override
  // O `weak` só reabre a saída quando o formato muda, e o `yes` converteria a
  // faixa seguinte para o formato da primeira
  Future<void> setGapless(bool gapless) async =>
      (_player.platform as NativePlayer).setProperty(
        'gapless-audio',
        gapless ? 'weak' : 'no',
      );

  @override
  Future<void> setCrossfade(Duration length) async {
    _crossfade = length;
    if (length > Duration.zero) return;
    _cancelCrossfade();
    await _tail?.dispose();
    _tail = null;
  }

  @override
  Future<void> setFadeOnPause(bool fade) async => _fadeOnPause = fade;

  @override
  Future<void> setReplayGain(PlayerReplayGain mode) =>
      _setShared('replaygain', mode == PlayerReplayGain.off ? 'no' : mode.name);

  @override
  Future<void> setEqualizer(List<double> gains) =>
      _setShared('af', equalizerFilter(gains));

  @override
  Future<void> dispose() async {
    _ramp?.cancel();
    await _tail?.dispose();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    _state.dispose();
  }
}

// lib/src/player/desktop_hooks.dart
//
// O que o player pede ao desktop pelo barramento, além do MPRIS: não deixar o
// computador dormir, avisar da faixa nova e mostrar um arquivo no gerenciador. Um
// desktop sem esses serviços não impede de tocar.
import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../settings/player_settings.dart';
import 'playback_controller.dart';

const _appName = 'Psito Player';
const _appId = 'org.psito.player';
const _screenSaver = 'org.freedesktop.ScreenSaver';
const _notifications = 'org.freedesktop.Notifications';
const _fileManager = 'org.freedesktop.FileManager1';
const _timeout = Duration(seconds: 5);

class DesktopHooks {
  final PlaybackController playback;
  final PlayerSettings settings;
  final DBusClient bus;

  /// O motivo que o desktop mostra ao dizer quem está segurando a tela.
  final String awakeReason;

  int? _cookie;
  bool _noScreenSaver = false;
  bool _noNotifications = false;
  int _notification = 0;
  String? _announced;
  Future<void> _pending = Future.value();

  DesktopHooks({
    required this.playback,
    required this.settings,
    required this.bus,
    required this.awakeReason,
  }) {
    playback.addListener(_onChange);
    settings.addListener(_onChange);
    _onChange();
  }

  // Um pedido de cada vez: a resposta do Inhibit traz o que o UnInhibit precisa
  void _onChange() => _pending = _pending.then((_) => _apply());

  Future<void> _apply() async {
    await _syncAwake();
    await _announce();
  }

  Future<void> _syncAwake() async {
    if (_noScreenSaver) return;
    final want = settings.keepAwake && playback.state.playing;
    if (want == (_cookie != null)) return;
    final remote = DBusRemoteObject(
      bus,
      name: _screenSaver,
      path: DBusObjectPath('/org/freedesktop/ScreenSaver'),
    );
    try {
      if (want) {
        final reply = await remote
            .callMethod(_screenSaver, 'Inhibit', [
              const DBusString(_appName),
              DBusString(awakeReason),
            ], replySignature: DBusSignature('u'))
            .timeout(_timeout);
        _cookie = reply.values.single.asUint32();
      } else {
        final cookie = _cookie!;
        _cookie = null;
        await remote
            .callMethod(_screenSaver, 'UnInhibit', [
              DBusUint32(cookie),
            ], replySignature: DBusSignature(''))
            .timeout(_timeout);
      }
    } catch (e) {
      debugPrint('🎵 sem o serviço de tela: $e');
      _noScreenSaver = true;
    }
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Uma vez por faixa, ao começar a tocar. A que voltou parada avisa ao tocar.
  Future<void> _announce() async {
    final track = playback.current;
    if (track == null || !playback.state.playing) return;
    if (track.path == _announced) return;
    _announced = track.path;
    if (_noNotifications || !settings.notifyTrack) return;
    final who = [
      track.artist,
      track.album,
    ].where((part) => part.isNotEmpty).join(' · ');
    try {
      final reply =
          await DBusRemoteObject(
                bus,
                name: _notifications,
                path: DBusObjectPath('/org/freedesktop/Notifications'),
              )
              .callMethod(_notifications, 'Notify', [
                const DBusString(_appName),
                DBusUint32(_notification),
                const DBusString(_appId),
                DBusString(track.title),
                DBusString(_escape(who)),
                DBusArray.string(const []),
                DBusDict.stringVariant({
                  'desktop-entry': const DBusString(_appId),
                  'transient': const DBusBoolean(true),
                }),
                const DBusInt32(-1),
              ], replySignature: DBusSignature('u'))
              .timeout(_timeout);
      _notification = reply.values.single.asUint32();
    } catch (e) {
      debugPrint('🎵 sem o serviço de notificações: $e');
      _noNotifications = true;
    }
  }

  /// Fechar o barramento solta a tela: aqui só espera o que já foi pedido.
  Future<void> dispose() async {
    playback.removeListener(_onChange);
    settings.removeListener(_onChange);
    await _pending;
  }
}

/// Mostra o arquivo selecionado no gerenciador. Devolve false se ninguém atendeu.
Future<bool> showInFileManager(String path, DBusClient bus) async {
  try {
    await DBusRemoteObject(
          bus,
          name: _fileManager,
          path: DBusObjectPath('/org/freedesktop/FileManager1'),
        )
        .callMethod(_fileManager, 'ShowItems', [
          DBusArray.string([Uri.file(path).toString()]),
          const DBusString(''),
        ], replySignature: DBusSignature(''))
        .timeout(_timeout);
    return true;
  } catch (e) {
    debugPrint('🎵 sem o FileManager1: $e');
    return false;
  }
}

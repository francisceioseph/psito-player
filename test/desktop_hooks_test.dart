// O que o player pede ao desktop, num barramento privado.
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/player/desktop_hooks.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/settings/player_settings.dart';

import 'helpers.dart';

/// O ScreenSaver, as notificações e o gerenciador de arquivos de um desktop.
class _Desktop extends DBusObject {
  final calls = <String, List<List<DBusValue>>>{};
  final String interface;

  _Desktop(String path, this.interface) : super(DBusObjectPath(path));

  List<List<DBusValue>> of(String method) => calls[method] ?? const [];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != interface) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    (calls[call.name] ??= []).add(call.values);
    return switch (call.name) {
      'Inhibit' => DBusMethodSuccessResponse([const DBusUint32(7)]),
      'Notify' => DBusMethodSuccessResponse([const DBusUint32(42)]),
      _ => DBusMethodSuccessResponse(),
    };
  }
}

void main() {
  late Directory dir;
  late DBusServer server;
  late DBusClient desktop;
  late DBusClient bus;
  late _Desktop screenSaver;
  late _Desktop notifications;
  late FakeEngine engine;
  late PlaybackController playback;
  late PlayerSettings settings;
  DesktopHooks? hooks;

  Future<void> wait() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('player_hooks_');
    server = DBusServer();
    final address = await server.listenAddress(DBusAddress.unix(dir: dir));
    desktop = DBusClient(address);
    bus = DBusClient(address);
    screenSaver = _Desktop(
      '/org/freedesktop/ScreenSaver',
      'org.freedesktop.ScreenSaver',
    );
    notifications = _Desktop(
      '/org/freedesktop/Notifications',
      'org.freedesktop.Notifications',
    );
    await desktop.requestName('org.freedesktop.ScreenSaver');
    await desktop.requestName('org.freedesktop.Notifications');
    await desktop.registerObject(screenSaver);
    await desktop.registerObject(notifications);
    engine = FakeEngine();
    playback = PlaybackController(
      engine: engine,
      store: DirectStore(LibraryDb.memory()),
    );
    settings = PlayerSettings();
    hooks = null;
  });

  tearDown(() async {
    await hooks?.dispose();
    playback.dispose();
    await bus.close();
    await desktop.close();
    await server.close();
    await dir.delete(recursive: true);
  });

  void start() => hooks = DesktopHooks(
    playback: playback,
    settings: settings,
    bus: bus,
    awakeReason: 'Tocando música',
  );

  group('manter acordado', () {
    test('desligado, não pede nada', () async {
      start();
      await playback.playPaths(['/m/a.flac']);
      await wait();
      expect(screenSaver.of('Inhibit'), isEmpty);
    });

    test('segura só enquanto toca, e devolve o mesmo número', () async {
      settings.keepAwake = true;
      start();
      await wait();
      expect(screenSaver.of('Inhibit'), isEmpty);

      await playback.playPaths(['/m/a.flac']);
      await wait();
      expect(screenSaver.of('Inhibit'), hasLength(1));
      expect(screenSaver.of('Inhibit').single[1].asString(), 'Tocando música');

      await playback.togglePlay();
      await wait();
      expect(screenSaver.of('UnInhibit').single.single.asUint32(), 7);

      await playback.togglePlay();
      await wait();
      expect(screenSaver.of('Inhibit'), hasLength(2));
    });

    test('desligar a opção tocando solta na hora', () async {
      settings.keepAwake = true;
      start();
      await playback.playPaths(['/m/a.flac']);
      await wait();
      settings.keepAwake = false;
      await wait();
      expect(screenSaver.of('UnInhibit'), hasLength(1));
    });

    test('sem o serviço, continua tocando e não insiste', () async {
      await desktop.unregisterObject(screenSaver);
      await desktop.releaseName('org.freedesktop.ScreenSaver');
      settings.keepAwake = true;
      start();
      await playback.playPaths(['/m/a.flac']);
      await wait();
      expect(engine.state.value.playing, isTrue);
      expect(screenSaver.of('Inhibit'), isEmpty);
    });
  });

  group('avisar da faixa', () {
    test('desligado, não avisa', () async {
      start();
      await playback.playPaths(['/m/a.flac']);
      await wait();
      expect(notifications.of('Notify'), isEmpty);
    });

    test('uma vez por faixa, trocando o aviso anterior', () async {
      settings.notifyTrack = true;
      start();
      await playback.playPaths(['/m/a.flac', '/m/b.flac']);
      await wait();
      expect(notifications.of('Notify'), hasLength(1));
      expect(notifications.of('Notify').first[1].asUint32(), 0);

      // Pausar e voltar não é faixa nova
      await playback.togglePlay();
      await wait();
      await playback.togglePlay();
      await wait();
      expect(notifications.of('Notify'), hasLength(1));

      await playback.next();
      await wait();
      expect(notifications.of('Notify'), hasLength(2));
      expect(notifications.of('Notify').last[1].asUint32(), 42);
    });

    test('a faixa que voltou parada só avisa ao tocar', () async {
      settings.notifyTrack = true;
      start();
      await engine.open(['/m/a.flac'], play: false);
      await wait();
      expect(notifications.of('Notify'), isEmpty);
      await playback.togglePlay();
      await wait();
      expect(notifications.of('Notify'), hasLength(1));
    });

    test('o corpo não vira marcação', () async {
      settings.notifyTrack = true;
      start();
      await playback.playPaths(['/m/a.flac']);
      await wait();
      final track = playback.current!;
      expect(notifications.of('Notify').single[3].asString(), track.title);
    });
  });

  group('gerenciador de arquivos', () {
    test('pede pelo FileManager1, como URI', () async {
      final manager = _Desktop(
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1',
      );
      await desktop.requestName('org.freedesktop.FileManager1');
      await desktop.registerObject(manager);
      expect(await showInFileManager('/m/a b.flac', bus), isTrue);
      expect(manager.of('ShowItems').single.first.asStringArray(), [
        'file:///m/a%20b.flac',
      ]);
    });

    test('sem o serviço, avisa quem chamou', () async {
      expect(await showInFileManager('/m/a.flac', bus), isFalse);
    });
  });
}

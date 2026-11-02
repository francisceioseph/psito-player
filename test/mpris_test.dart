import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/player/engine.dart';
import 'package:psito_player/src/player/mpris.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/player/single_instance.dart';

import 'helpers.dart';

const _player = 'org.mpris.MediaPlayer2.Player';

void main() {
  late Directory dir;
  late DBusServer server;
  late DBusAddress address;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('player_dbus_');
    server = DBusServer();
    address = await server.listenAddress(DBusAddress.unix(dir: dir));
  });
  tearDown(() async {
    await server.close();
    await dir.delete(recursive: true);
  });

  group('MPRIS', () {
    late FakeEngine engine;
    late PlaybackController playback;
    late Mpris mpris;
    late DBusClient service;
    late DBusClient outside;
    late DBusRemoteObject remote;
    var raised = 0;
    var quit = 0;

    setUp(() async {
      engine = FakeEngine();
      playback = PlaybackController(
        engine: engine,
        store: DirectStore(LibraryDb.memory()),
      );
      mpris = Mpris(
        playback,
        identity: 'Psito Player',
        onRaise: () async => raised++,
        onQuit: () async => quit++,
      );
      service = DBusClient(address);
      outside = DBusClient(address);
      expect(await mpris.publish(service), isTrue);
      remote = DBusRemoteObject(
        outside,
        name: Mpris.busName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
    });

    tearDown(() async {
      await mpris.close();
      playback.dispose();
      await outside.close();
      await service.close();
    });

    Future<DBusValue> prop(String name) => remote.getProperty(_player, name);
    Future<void> call(String name, [List<DBusValue> args = const []]) => remote
        .callMethod(_player, name, args, replySignature: DBusSignature(''));

    test('sem faixa, está parado e não aceita tocar', () async {
      expect((await prop('PlaybackStatus')).asString(), 'Stopped');
      expect((await prop('CanPlay')).asBoolean(), isFalse);
      await call('PlayPause');
      expect(engine.state.value.playing, isFalse);
    });

    test('mostra a faixa e obedece aos comandos', () async {
      await engine.open(['/m/a b.flac', '/m/c.flac']);
      expect((await prop('PlaybackStatus')).asString(), 'Playing');
      final metadata = (await prop('Metadata')).asStringVariantDict();
      expect(metadata['xesam:title']!.asString(), 'a b');
      expect(metadata['xesam:url']!.asString(), 'file:///m/a%20b.flac');
      expect(
        (metadata['mpris:trackid'] as DBusObjectPath).value,
        '/org/psito/player/track/0',
      );

      await call('Pause');
      expect(engine.state.value.playing, isFalse);
      await call('Pause');
      expect(engine.state.value.playing, isFalse, reason: 'pausar não alterna');
      await call('Play');
      expect(engine.state.value.playing, isTrue);
      await call('Next');
      expect(engine.state.value.index, 1);
      expect((await prop('CanGoNext')).asBoolean(), isFalse);

      await call('Seek', [const DBusInt64(30 * 1000000)]);
      expect(engine.seeks.last, const Duration(seconds: 30));
      await call('SetPosition', [
        DBusObjectPath('/org/psito/player/track/0'),
        const DBusInt64(1000000),
      ]);
      expect(
        engine.seeks.last,
        const Duration(seconds: 30),
        reason: 'pedido para a faixa que já passou',
      );
      await call('SetPosition', [
        DBusObjectPath('/org/psito/player/track/1'),
        const DBusInt64(1000000),
      ]);
      expect(engine.seeks.last, const Duration(seconds: 1));
    });

    test('muda volume, repetir e aleatório', () async {
      await engine.open(['/m/a.flac']);
      await remote.setProperty(_player, 'Volume', const DBusDouble(0.25));
      expect(engine.state.value.volume, 0.25);
      await remote.setProperty(
        _player,
        'LoopStatus',
        const DBusString('Track'),
      );
      expect(engine.state.value.repeat, PlayerRepeat.one);
      await remote.setProperty(_player, 'Shuffle', const DBusBoolean(true));
      expect(engine.state.value.shuffle, isTrue);
      expect(
        remote.setProperty(_player, 'Position', const DBusInt64(0)),
        throwsA(isA<DBusMethodResponseException>()),
      );
    });

    test('avisa o que muda e as buscas, sem avisar a posição', () async {
      final changes = <Set<String>>[];
      final seeks = <int>[];
      final subs = <StreamSubscription<Object?>>[
        remote.propertiesChanged.listen(
          (e) => changes.add(e.changedProperties.keys.toSet()),
        ),
        DBusRemoteObjectSignalStream(
          object: remote,
          interface: _player,
          name: 'Seeked',
        ).listen((s) => seeks.add(s.values[0].asInt64())),
      ];
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await engine.open(['/m/a.flac']);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        changes.expand((c) => c),
        containsAll(['PlaybackStatus', 'Metadata']),
      );
      changes.clear();

      final s = engine.state.value;
      engine.set(s.copyWith(position: const Duration(milliseconds: 300)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(changes, isEmpty);
      expect(seeks, isEmpty);

      engine.set(s.copyWith(position: const Duration(minutes: 2)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seeks, [120000000]);
      for (final sub in subs) {
        await sub.cancel();
      }
    });

    test('traz a janela e sai', () async {
      const root = 'org.mpris.MediaPlayer2';
      await remote.callMethod(
        root,
        'Raise',
        [],
        replySignature: DBusSignature(''),
      );
      await remote.callMethod(
        root,
        'Quit',
        [],
        replySignature: DBusSignature(''),
      );
      expect((raised, quit), (1, 1));
      expect(
        (await remote.getProperty(root, 'Identity')).asString(),
        'Psito Player',
      );
    });

    test('um segundo player no mesmo barramento desiste do nome', () async {
      final other = DBusClient(address);
      final second = Mpris(playback, identity: 'x', onQuit: () async {});
      expect(await second.publish(other), isFalse);
      await other.close();
    });
  });

  group('instância única', () {
    test('o segundo entrega os arquivos ao primeiro e sai', () async {
      final clients = <DBusClient>[];
      DBusClient connect() {
        final client = DBusClient(address);
        clients.add(client);
        return client;
      }

      final first = await SingleInstance.acquire([
        '/m/a.flac',
      ], connect: connect);
      expect(first, isNotNull);
      final received = first!.opens.first;
      final second = await SingleInstance.acquire([
        '/m/b.flac',
      ], connect: connect);
      expect(second, isNull);
      expect(await received, ['/m/b.flac']);
      await clients.first.close();
    });

    test('sem barramento, abre mesmo assim', () async {
      final instance = await SingleInstance.acquire(
        const [],
        connect: () => throw StateError('sem barramento'),
      );
      expect(instance, isNotNull);
    });
  });
}

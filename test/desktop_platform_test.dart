// O que o player pede ao sistema, no Linux, e os caminhos do Windows nos argumentos.
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:psito_player/src/library/library_db.dart';
import 'package:psito_player/src/library/library_store.dart';
import 'package:psito_player/src/platform/desktop_platform.dart';
import 'package:psito_player/src/platform/linux_desktop.dart';
import 'package:psito_player/src/platform/windows_desktop.dart';
import 'package:psito_player/src/platform/windows_system.dart';
import 'package:psito_player/src/player/mpris.dart';
import 'package:psito_player/src/player/playback_controller.dart';
import 'package:psito_player/src/settings/player_settings.dart';
import 'package:psito_player/standalone_app.dart';

import 'helpers.dart';

class _System implements WindowsSystem {
  final String? music;
  final (int, String)? disk;
  final revealed = <String>[];

  _System({this.music, this.disk});

  @override
  String? musicFolder() => music;
  @override
  (int, String)? diskInfo(String path) => disk;
  @override
  void keepAwake(bool on) {}
  @override
  bool reveal(String path) {
    revealed.add(path);
    return true;
  }

  @override
  void allowForeground() {}
}

WindowsDesktop windows(Map<String, String> env, [WindowsSystem? system]) =>
    WindowsDesktop(env: env, system: system ?? _System());

void main() {
  group('LinuxDesktop', () {
    test('as pastas seguem o padrão sem as variáveis do XDG', () {
      final paths = LinuxDesktop({'HOME': '/home/a'}).libraryPaths;
      expect(paths.db, '/home/a/.local/share/psito/player/library.db');
      expect(paths.covers, '/home/a/.cache/psito/player/covers');
      expect(
        paths.playlistCovers,
        '/home/a/.local/share/psito/player/playlist-covers',
      );
      expect(paths.tagUndo, '/home/a/.local/share/psito/player/tag-undo');
    });

    test('as variáveis do XDG mudam as pastas', () {
      final paths = LinuxDesktop({
        'HOME': '/home/a',
        'XDG_DATA_HOME': '/d',
        'XDG_CACHE_HOME': '/c',
      }).libraryPaths;
      expect(paths.db, '/d/psito/player/library.db');
      expect(paths.covers, '/c/psito/player/covers');
    });

    test('o home vem do ambiente', () {
      expect(LinuxDesktop({'HOME': '/home/a'}).homeDir, '/home/a');
      expect(LinuxDesktop(const {}).homeDir, isNull);
    });

    test('o disco diz o espaço livre e o tipo', () {
      final info = LinuxDesktop().diskInfo(Directory.systemTemp.path);
      expect(info, isNotNull);
      expect(info!.$1, greaterThan(0));
      expect(info.$2, isNotEmpty);
      expect(LinuxDesktop().diskInfo('/nao/existe'), isNull);
    });

    test('devolve o modo do arquivo', () {
      final dir = Directory.systemTemp.createTempSync('psito-mode');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'a'))..writeAsStringSync('x');
      LinuxDesktop().restoreFileMode(file.path, 0x180); // 0600
      expect(file.statSync().mode & 0xFFF, 0x180);
      expect(
        () => LinuxDesktop().restoreFileMode(p.join(dir.path, 'b'), 0x180),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('é o sistema destes testes', () {
      expect(desktopPlatform, isA<LinuxDesktop>());
    });
  });

  group('a sessão no Linux', () {
    late Directory dir;
    late DBusServer server;
    late DBusClient outside;
    late DBusAddress address;
    late PlaybackController playback;
    late PlayerSettings settings;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('player_session_');
      server = DBusServer();
      address = await server.listenAddress(DBusAddress.unix(dir: dir));
      outside = DBusClient(address);
      playback = PlaybackController(
        engine: FakeEngine(),
        store: DirectStore(LibraryDb.memory()),
      );
      settings = PlayerSettings();
    });

    tearDown(() async {
      settings.dispose();
      playback.dispose();
      await outside.close();
      await server.close();
      await dir.delete(recursive: true);
    });

    DesktopSessionRequest request({bool open = true}) => DesktopSessionRequest(
      playback: playback,
      settings: settings,
      awakeReason: 'tocando',
      onRaise: null,
      onQuit: () async {},
      isOpen: () => open,
    );

    Future<DesktopSession?> start({bool open = true}) => LinuxDesktop(
      const {},
      () => DBusClient(address),
    ).openSession(request(open: open));

    test('publica os controles, e fechar solta o nome', () async {
      final session = await start();
      expect(session, isNotNull);
      expect(await outside.nameHasOwner(Mpris.busName), isTrue);
      await session!.close();
      expect(await outside.nameHasOwner(Mpris.busName), isFalse);
    });

    test('o player que fechou nesse meio não fica publicado', () async {
      expect(await start(open: false), isNull);
      expect(await outside.nameHasOwner(Mpris.busName), isFalse);
    });

    test('sem barramento, não há sessão e o player segue', () async {
      final session = await LinuxDesktop(
        const {},
        () => throw StateError('sem barramento'),
      ).openSession(request());
      expect(session, isNull);
    });
  });

  group('WindowsDesktop', () {
    test('as pastas seguem as variáveis do Windows', () {
      final paths = windows(const {
        'USERPROFILE': r'C:\Users\a',
        'APPDATA': r'C:\Users\a\AppData\Roaming',
        'LOCALAPPDATA': r'C:\Users\a\AppData\Local',
      }).libraryPaths;
      expect(paths.db, r'C:\Users\a\AppData\Roaming\Psito Player\library.db');
      expect(paths.covers, r'C:\Users\a\AppData\Local\Psito Player\covers');
    });

    test('sem as variáveis, parte do perfil', () {
      final paths = windows(const {'USERPROFILE': r'C:\Users\a'}).libraryPaths;
      expect(paths.db, r'C:\Users\a\AppData\Roaming\Psito Player\library.db');
    });

    test('sem resposta do sistema, não inventa', () async {
      final desktop = windows(const {});
      expect(desktop.homeDir, isNull);
      expect(desktop.musicDir, isNull);
      expect(desktop.diskInfo(r'C:\'), isNull);
    });

    test('a pasta Música vem do sistema, onde quer que esteja', () {
      final dir = Directory.systemTemp.createTempSync('psito-music');
      addTearDown(() => dir.deleteSync(recursive: true));
      expect(windows(const {}, _System(music: dir.path)).musicDir, dir.path);
    });

    test('o disco responde pelo sistema', () {
      expect(windows(const {}, _System(disk: (7, 'ntfs'))).diskInfo(r'C:\'), (
        7,
        'ntfs',
      ));
    });

    test('mostrar um arquivo normaliza o caminho', () async {
      final system = _System();
      expect(await windows(const {}, system).reveal('C:/m/a b.flac'), isTrue);
      expect(system.revealed, [r'C:\m\a b.flac']);
    });

    test('o FAT do Windows tem o nome do Linux', () {
      expect(fileSystemName('FAT32'), 'vfat');
      expect(fileSystemName('exFAT'), 'exfat');
      expect(fileSystemName('NTFS'), 'ntfs');
    });

    test('sem os controles de mídia, não há sessão e o player segue', () async {
      final desktop = WindowsDesktop(
        env: const {},
        system: _System(),
        openTransport: () => throw StateError('sem a biblioteca'),
      );
      final playback = PlaybackController(
        engine: FakeEngine(),
        store: DirectStore(LibraryDb.memory()),
      );
      final settings = PlayerSettings();
      addTearDown(playback.dispose);
      addTearDown(settings.dispose);
      expect(
        await desktop.openSession(
          DesktopSessionRequest(
            playback: playback,
            settings: settings,
            awakeReason: '',
            onRaise: null,
            onQuit: () async {},
            isOpen: () => true,
          ),
        ),
        isNull,
      );
    });
  });

  test('os argumentos aceitam os caminhos do Windows', () {
    expect(
      openedFiles([
        '--flag',
        r'C:\Musica\a b.flac',
        r'\\servidor\m\c.mp3',
        'file:///C:/Musica/d%20e.mp3',
        'solto.mp3',
      ], context: p.windows),
      [r'C:\Musica\a b.flac', r'\\servidor\m\c.mp3', r'C:\Musica\d e.mp3'],
    );
  });

  test('no Linux, um caminho do Windows não é um caminho', () {
    expect(openedFiles([r'C:\Musica\a.flac']), isEmpty);
  });
}

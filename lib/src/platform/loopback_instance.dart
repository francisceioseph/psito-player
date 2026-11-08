// lib/src/platform/loopback_instance.dart
//
// Um player só, onde não há barramento: quem segura a trava do arquivo é o dono e
// escuta só no endereço local. Quem chega depois lê o endereço e a senha da pasta
// do usuário, entrega os arquivos e sai.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'desktop_platform.dart';

const _timeout = Duration(seconds: 5);

/// Um pedido maior que isso não veio do player.
const _maxRequest = 16 * 1024 * 1024;

class LoopbackInstance implements AppInstance {
  final _opens = StreamController<List<String>>();
  final String _token;

  /// Fica aberto enquanto o processo viver: fechar soltaria a trava. Sem o pragma,
  /// o compilador de release apaga o campo, que ninguém lê, e o arquivo é fechado.
  @pragma('vm:entry-point')
  // ignore: unused_field
  final RandomAccessFile? _lock;
  final ServerSocket? _server;

  LoopbackInstance._(this._token, this._lock, this._server) {
    _server?.listen(_onClient, onError: (Object e) => debugPrint('🎵 $e'));
  }

  /// Sem dono nem como saber: abre do mesmo jeito, sozinha.
  factory LoopbackInstance._alone() => LoopbackInstance._('', null, null);

  /// Guarda até alguém ouvir, porque o pedido pode chegar antes da tela.
  @override
  Stream<List<String>> get opens => _opens.stream;

  /// Devolve esta instância, ou null se outra recebeu os [paths]. Um dono travado
  /// não impede de abrir. [beforeHandOff] roda antes de entregar.
  static Future<LoopbackInstance?> acquire(
    String dir,
    List<String> paths, {
    void Function()? beforeHandOff,
    @visibleForTesting Future<bool> Function(RandomAccessFile lock)? tryLock,
  }) async {
    final address = File(p.join(dir, 'instance.json'));
    RandomAccessFile? lock;
    try {
      await Directory(dir).create(recursive: true);
      lock = await File(p.join(dir, 'instance.lock'))
          .open(mode: FileMode.write);
      if (await (tryLock ?? _tryLock)(lock)) {
        return await _serve(address, lock);
      }
      await lock.close();
      lock = null;
      beforeHandOff?.call();
      await _handOff(address, paths);
      return null;
    } catch (e) {
      debugPrint('🎵 sem instância única: $e');
      await lock?.close();
      return LoopbackInstance._alone();
    }
  }

  static Future<bool> _tryLock(RandomAccessFile file) async {
    try {
      await file.lock(FileLock.exclusive);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  static Future<LoopbackInstance> _serve(
    File address,
    RandomAccessFile lock,
  ) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final random = Random.secure();
    final token = [
      for (var i = 0; i < 32; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await address.writeAsString(
      jsonEncode({'port': server.port, 'token': token}),
      flush: true,
    );
    return LoopbackInstance._(token, lock, server);
  }

  /// O dono pode ter acabado de ganhar a trava e ainda não ter escrito o endereço.
  static Future<void> _handOff(File address, List<String> paths) async {
    final deadline = DateTime.now().add(_timeout);
    while (true) {
      try {
        final info = jsonDecode(await address.readAsString()) as Map;
        final socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          info['port'] as int,
          timeout: _timeout,
        );
        socket.writeln(jsonEncode({'token': info['token'], 'paths': paths}));
        await socket.flush().timeout(_timeout);
        await socket.close();
        return;
      } on Exception {
        if (DateTime.now().isAfter(deadline)) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> _onClient(Socket socket) async {
    try {
      final line = await _firstLine(socket).timeout(_timeout);
      final request = jsonDecode(line) as Map;
      if (request['token'] == _token) {
        _opens.add((request['paths'] as List).cast<String>());
      }
    } catch (e) {
      debugPrint('🎵 pedido recusado: $e');
    } finally {
      socket.destroy();
    }
  }

  Future<String> _firstLine(Socket socket) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in socket) {
      bytes.add(chunk);
      if (bytes.length > _maxRequest) throw StateError('pedido grande demais');
      if (chunk.contains(0x0A)) break;
    }
    return utf8.decode(bytes.takeBytes()).split('\n').first;
  }
}

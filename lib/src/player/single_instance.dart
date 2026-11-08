// lib/src/player/single_instance.dart
//
// Um player só por sessão, para o player sozinho: quem chega depois entrega os
// arquivos ao que está aberto, pelo barramento, e sai. No Psito, quem faz isso é o
// shell.
import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

import '../platform/desktop_platform.dart';

const _name = 'org.psito.player';
const _interface = 'org.psito.Player';
final _path = DBusObjectPath('/org/psito/player');

class SingleInstance extends DBusObject implements AppInstance {
  final _opens = StreamController<List<String>>();

  SingleInstance._() : super(_path);

  /// O que pediram para abrir depois. Vazio é só trazer a janela. Guarda até
  /// alguém ouvir, porque o pedido pode chegar antes da tela.
  @override
  Stream<List<String>> get opens => _opens.stream;

  /// Devolve esta instância, ou null se outra recebeu os [paths]. Sem barramento,
  /// abre do mesmo jeito.
  static Future<SingleInstance?> acquire(
    List<String> paths, {
    DBusClient Function()? connect,
  }) async {
    final instance = SingleInstance._();
    try {
      final client = connect?.call() ?? DBusClient.session();
      await client.registerObject(instance);
      final reply = await client.requestName(
        _name,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      if (reply == DBusRequestNameReply.primaryOwner ||
          reply == DBusRequestNameReply.alreadyOwner) {
        return instance;
      }
      await client.unregisterObject(instance);
      await DBusRemoteObject(client, name: _name, path: _path)
          .callMethod(_interface, 'Open', [
            DBusArray.string(paths),
          ], replySignature: DBusSignature(''))
          .timeout(const Duration(seconds: 5));
      await client.close();
      return null;
    } catch (e) {
      // Um dono travado não pode impedir de abrir
      debugPrint('🎵 sem instância única: $e');
      return instance;
    }
  }

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      _interface,
      methods: [
        DBusIntrospectMethod(
          'Open',
          args: [
            DBusIntrospectArgument(
              DBusSignature('as'),
              DBusArgumentDirection.in_,
              name: 'paths',
            ),
          ],
        ),
      ],
    ),
  ];

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == _interface &&
        methodCall.name == 'Open' &&
        methodCall.signature == DBusSignature('as')) {
      _opens.add(methodCall.values[0].asStringArray().toList());
      return DBusMethodSuccessResponse();
    }
    return DBusMethodErrorResponse.unknownMethod();
  }
}

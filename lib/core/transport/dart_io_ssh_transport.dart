import 'dart:io';
import 'dart:typed_data';

import '../ssh/ssh_contracts.dart';
import 'ssh_transport.dart';

typedef DartIoSocketConnector = Future<DartIoSocket> Function(
  String host,
  int port,
);

abstract interface class DartIoSocket {
  Stream<Uint8List> get incoming;

  Future<void> send(List<int> bytes);

  Future<void> close();
}

final class DartIoSshTransport implements SshTransport {
  DartIoSshTransport({
    DartIoSocketConnector? connectSocket,
  }) : _connectSocket = connectSocket ?? _connect;

  final DartIoSocketConnector _connectSocket;

  @override
  SshTransportCapabilities get capabilities => const SshTransportCapabilities(
        rawTcp: true,
        requiresBridge: false,
      );

  @override
  Future<SshTransportConnection> connect(SshConnectionRequest request) async =>
      _DartIoSshTransportConnection(
        await _connectSocket(request.host, request.port),
      );

  static Future<DartIoSocket> _connect(String host, int port) async =>
      _SocketAdapter(await Socket.connect(host, port));
}

final class _DartIoSshTransportConnection implements SshTransportConnection {
  _DartIoSshTransportConnection(this._socket);

  final DartIoSocket _socket;

  @override
  Stream<List<int>> get incoming => _socket.incoming;

  @override
  Future<void> send(List<int> bytes) => _socket.send(bytes);

  @override
  Future<void> close() => _socket.close();
}

final class _SocketAdapter implements DartIoSocket {
  _SocketAdapter(this._socket);

  final Socket _socket;

  @override
  Stream<Uint8List> get incoming => _socket;

  @override
  Future<void> send(List<int> bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}

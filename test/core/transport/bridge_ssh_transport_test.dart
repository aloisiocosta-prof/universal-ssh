import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/transport/bridge_ssh_transport.dart';

void main() {
  test('BridgeSshTransport delegates the connection lifecycle to its bridge',
      () async {
    final bridge = _FakeBridge();
    final transport = BridgeSshTransport(bridge: bridge);
    final request = SshConnectionRequest(
      host: 'ssh.example.test',
      port: 2222,
      username: 'alice',
    );

    expect(transport.capabilities.rawTcp, isFalse);
    expect(transport.capabilities.requiresBridge, isTrue);

    final connection = await transport.connect(request);

    expect(bridge.connectedHost, 'ssh.example.test');
    expect(bridge.connectedPort, 2222);

    bridge.emit(Uint8List.fromList([83, 83, 72]));
    expect(await connection.incoming.first, [83, 83, 72]);

    await connection.send([1, 2, 3]);
    expect(bridge.sentBytes, [1, 2, 3]);

    await connection.close();
    expect(bridge.closed, isTrue);
  });
}

final class _FakeBridge implements SshTransportBridge {
  final _incoming = StreamController<Uint8List>();
  String? connectedHost;
  int? connectedPort;
  List<int>? sentBytes;
  bool closed = false;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Future<void> connect(String host, int port) async {
    connectedHost = host;
    connectedPort = port;
  }

  void emit(Uint8List bytes) => _incoming.add(bytes);

  @override
  Future<void> send(List<int> bytes) async {
    sentBytes = List<int>.of(bytes);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _incoming.close();
  }
}

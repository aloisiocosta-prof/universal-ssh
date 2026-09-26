import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/transport/dart_io_ssh_transport.dart';

void main() {
  test('DartIoSshTransport delegates TCP lifecycle to its socket boundary',
      () async {
    final socket = _FakeSocket();
    String? connectedHost;
    int? connectedPort;
    final transport = DartIoSshTransport(
      connectSocket: (host, port) async {
        connectedHost = host;
        connectedPort = port;
        return socket;
      },
    );

    expect(transport.capabilities.rawTcp, isTrue);
    expect(transport.capabilities.requiresBridge, isFalse);

    final connection = await transport.connect(
      SshConnectionRequest(
        host: 'ssh.example.test',
        port: 2222,
        username: 'alice',
      ),
    );

    expect(connectedHost, 'ssh.example.test');
    expect(connectedPort, 2222);

    final incoming = expectLater(
      connection.incoming,
      emitsInOrder(<List<int>>[
        <int>[83, 83, 72],
      ]),
    );
    socket.addIncoming(Uint8List.fromList(<int>[83, 83, 72]));
    await incoming;

    await connection.send(<int>[1, 2, 3]);
    expect(socket.sent, <List<int>>[
      <int>[1, 2, 3],
    ]);

    await connection.close();
    expect(socket.closed, isTrue);
  });
}

final class _FakeSocket implements DartIoSocket {
  final _incoming = StreamController<Uint8List>();
  final sent = <List<int>>[];
  var closed = false;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  void addIncoming(Uint8List bytes) => _incoming.add(bytes);

  @override
  Future<void> send(List<int> bytes) async {
    sent.add(List<int>.of(bytes));
  }

  @override
  Future<void> close() async {
    closed = true;
    await _incoming.close();
  }
}

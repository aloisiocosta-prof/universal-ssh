import 'dart:typed_data';

import '../ssh/ssh_contracts.dart';
import 'ssh_transport.dart';

abstract interface class SshTransportBridge {
  Stream<Uint8List> get incoming;

  Future<void> connect(String host, int port);

  Future<void> send(List<int> bytes);

  Future<void> close();
}

final class BridgeSshTransport implements SshTransport {
  BridgeSshTransport({required SshTransportBridge bridge}) : _bridge = bridge;

  final SshTransportBridge _bridge;

  @override
  SshTransportCapabilities get capabilities => const SshTransportCapabilities(
        rawTcp: false,
        requiresBridge: true,
      );

  @override
  Future<SshTransportConnection> connect(SshConnectionRequest request) async {
    await _bridge.connect(request.host, request.port);
    return _BridgeSshTransportConnection(_bridge);
  }
}

final class _BridgeSshTransportConnection implements SshTransportConnection {
  _BridgeSshTransportConnection(this._bridge);

  final SshTransportBridge _bridge;

  @override
  Stream<List<int>> get incoming => _bridge.incoming;

  @override
  Future<void> send(List<int> bytes) => _bridge.send(bytes);

  @override
  Future<void> close() => _bridge.close();
}

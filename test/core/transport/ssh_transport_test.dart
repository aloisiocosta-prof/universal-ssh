import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/transport/ssh_transport.dart';

void main() {
  group('platform-neutral transport boundary', () {
    test('opens a byte transport from an SSH connection request', () async {
      final transport = _RecordingTransport(
        capabilities: const SshTransportCapabilities(
          rawTcp: true,
          requiresBridge: false,
        ),
      );
      const request = SshConnectionRequest(
        host: 'ssh.example.test',
        port: 22,
        username: 'researcher',
      );

      final connection = await transport.connect(request);

      expect(transport.lastRequest, same(request));
      expect(connection, isA<SshTransportConnection>());
    });

    test('exposes platform limitations before connection', () {
      final transport = _RecordingTransport(
        capabilities: const SshTransportCapabilities(
          rawTcp: false,
          requiresBridge: true,
        ),
      );

      expect(transport.capabilities.rawTcp, isFalse);
      expect(transport.capabilities.requiresBridge, isTrue);
    });
  });
}

final class _RecordingTransport implements SshTransport {
  _RecordingTransport({required this.capabilities});

  @override
  final SshTransportCapabilities capabilities;

  SshConnectionRequest? lastRequest;

  @override
  Future<SshTransportConnection> connect(SshConnectionRequest request) async {
    lastRequest = request;
    return const _FakeConnection();
  }
}

final class _FakeConnection implements SshTransportConnection {
  const _FakeConnection();

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  Future<void> send(List<int> bytes) async {}

  @override
  Future<void> close() async {}
}

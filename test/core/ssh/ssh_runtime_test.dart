import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/ssh/ssh_runtime.dart';

void main() {
  group('SshConnectionService request validation', () {
    const service = SshConnectionService();

    test('rejects empty host before opening any platform socket', () async {
      await expectLater(
        service.connect(
          request: const SshConnectionRequest(
            host: ' ',
            port: 22,
            username: 'alice',
          ),
          onVerifyHostKey: (_) async => true,
          requestPassword: () async => 'unused',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid ports before opening any platform socket', () async {
      await expectLater(
        service.connect(
          request: const SshConnectionRequest(
            host: 'ssh.example.test',
            port: 65536,
            username: 'alice',
          ),
          onVerifyHostKey: (_) async => true,
          requestPassword: () async => 'unused',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty username before opening any platform socket', () async {
      await expectLater(
        service.connect(
          request: const SshConnectionRequest(
            host: 'ssh.example.test',
            port: 22,
            username: '',
          ),
          onVerifyHostKey: (_) async => true,
          requestPassword: () async => 'unused',
        ),
        throwsArgumentError,
      );
    });
  });
}

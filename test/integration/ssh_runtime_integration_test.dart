import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/ssh/ssh_runtime.dart';

void main() {
  final port = int.tryParse(Platform.environment['SSH_TEST_PORT'] ?? '');

  group(
    'real OpenSSH MVP integration',
    () {
      const service = SshConnectionService();
      final request = SshConnectionRequest(
        host: Platform.environment['SSH_TEST_HOST'] ?? '127.0.0.1',
        port: port ?? 22,
        username: Platform.environment['SSH_TEST_USERNAME'] ?? 'ssh-e2e',
      );
      final password = Platform.environment['SSH_TEST_PASSWORD'] ?? '';

      test(
        'verifies the host key before authenticating and runs a shell',
        () async {
          var hostKeyVerified = false;
          var passwordRequested = false;
          final session = await service.connect(
            request: request,
            onVerifyHostKey: (identity) async {
              hostKeyVerified = true;
              expect(identity.fingerprint, startsWith('SHA256:'));
              return true;
            },
            requestPassword: () async {
              expect(hostKeyVerified, isTrue);
              passwordRequested = true;
              return password;
            },
          );

          expect(hostKeyVerified, isTrue);
          expect(passwordRequested, isTrue);
          final output = StringBuffer();
          final markerReceived = Completer<void>();
          final subscription = session.stdout.listen((bytes) {
            output.write(utf8.decode(bytes, allowMalformed: true));
            if (RegExp(r'[\r\n]MVP_SSH_REAL_SESSION_OK[\r\n]')
                    .hasMatch(output.toString()) &&
                !markerReceived.isCompleted) {
              markerReceived.complete();
            }
          });

          try {
            session.write(
              utf8.encode("printf '\\nMVP_SSH_REAL_SESSION_OK\\n'\n"),
            );
            await markerReceived.future.timeout(const Duration(seconds: 10));
            expect(output.toString(), contains('MVP_SSH_REAL_SESSION_OK'));
          } finally {
            await subscription.cancel();
            await session.close().timeout(const Duration(seconds: 5));
          }
        },
      );

      test(
        'rejects an untrusted host key before requesting a password',
        () async {
          var passwordRequested = false;
          await expectLater(
            service.connect(
              request: request,
              onVerifyHostKey: (_) async => false,
              requestPassword: () async {
                passwordRequested = true;
                return password;
              },
            ),
            throwsA(anything),
          );
          expect(passwordRequested, isFalse);
        },
      );

      test(
        'rejects invalid authentication against the SSH server',
        () async {
          await expectLater(
            service.connect(
              request: request,
              onVerifyHostKey: (_) async => true,
              requestPassword: () async =>
                  'invalid-${DateTime.now().microsecondsSinceEpoch}',
            ),
            throwsA(anything),
          );
        },
      );
    },
    skip: port == null ? 'SSH_TEST_PORT is not configured.' : null,
  );
}

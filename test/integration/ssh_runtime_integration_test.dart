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
            if (output.toString().contains('MVP_SSH_REAL_SESSION_OK') &&
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
        'keeps stderr separate and completes when the remote shell exits',
        () async {
          final session = await service.connect(
            request: request,
            onVerifyHostKey: (_) async => true,
            requestPassword: () async => password,
          );
          final stdout = StringBuffer();
          final stderr = StringBuffer();
          final stdoutReceived = Completer<void>();
          final stderrReceived = Completer<void>();
          final stdoutSubscription = session.stdout.listen((bytes) {
            stdout.write(utf8.decode(bytes, allowMalformed: true));
            if (stdout.toString().contains('MVP_STDOUT_OK') &&
                !stdoutReceived.isCompleted) {
              stdoutReceived.complete();
            }
          });
          final stderrSubscription = session.stderr.listen((bytes) {
            stderr.write(utf8.decode(bytes, allowMalformed: true));
            if (stderr.toString().contains('MVP_STDERR_OK') &&
                !stderrReceived.isCompleted) {
              stderrReceived.complete();
            }
          });

          try {
            session.write(
              utf8.encode(
                "printf 'MVP_STDOUT_OK\\n'; "
                "printf 'MVP_STDERR_OK\\n' >&2; exit\n",
              ),
            );
            await stdoutReceived.future.timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException(
                'The remote command did not reach stdout.',
              ),
            );
            await stderrReceived.future.timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException(
                'The remote command did not reach stderr.',
              ),
            );
            await session.done.timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException(
                'The remote shell exit did not complete the session.',
              ),
            );
            expect(stdout.toString(), contains('MVP_STDOUT_OK'));
            expect(stderr.toString(), contains('MVP_STDERR_OK'));
          } finally {
            await stdoutSubscription.cancel();
            await stderrSubscription.cancel();
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

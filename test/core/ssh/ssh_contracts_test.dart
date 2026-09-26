import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';

void main() {
  group('FR-001 connection request', () {
    test('preserves host, port and username without UI coupling', () {
      final request = SshConnectionRequest(
        host: 'ssh.example.test',
        port: 2222,
        username: 'researcher',
      );

      expect(request.host, 'ssh.example.test');
      expect(request.port, 2222);
      expect(request.username, 'researcher');
    });
  });

  group('FR-002..FR-007 session lifecycle', () {
    test('defines the minimum observable lifecycle in protocol order', () {
      expect(
        SshSessionState.values,
        containsAllInOrder([
          SshSessionState.disconnected,
          SshSessionState.connecting,
          SshSessionState.verifyingHost,
          SshSessionState.authenticating,
          SshSessionState.openingSession,
          SshSessionState.connected,
          SshSessionState.disconnecting,
        ]),
      );
    });
  });

  group('SEC-001 host identity', () {
    test('requires an explicit host verification decision', () {
      final identity = SshHostIdentity(
        algorithm: 'ssh-ed25519',
        fingerprint: 'SHA256:test-fixture-only',
      );

      expect(
        SshHostVerificationDecision.values,
        containsAll([
          SshHostVerificationDecision.trust,
          SshHostVerificationDecision.reject,
        ]),
      );
      expect(identity.algorithm, 'ssh-ed25519');
      expect(identity.fingerprint, startsWith('SHA256:'));
    });

    test('represents a changed host key as a typed failure', () {
      final failure = SshFailure.hostKeyMismatch(
        expectedFingerprint: 'SHA256:expected',
        actualFingerprint: 'SHA256:actual',
      );

      expect(failure, isA<SshFailure>());
      expect(failure.code, SshFailureCode.hostKeyMismatch);
      expect(failure.expectedFingerprint, 'SHA256:expected');
      expect(failure.actualFingerprint, 'SHA256:actual');
    });
  });

  group('FR-004 authentication', () {
    test('models authentication input without storing a plaintext secret', () {
      final request = SshAuthenticationRequest.publicKey(
        username: 'researcher',
      );

      expect(request.username, 'researcher');
      expect(request.method, SshAuthenticationMethod.publicKey);
    });
  });

  group('FR-006 I/O', () {
    test('distinguishes stdout and stderr', () {
      final stdout = SshOutput.stdout([111, 107]);
      final stderr = SshOutput.stderr([101, 114, 114]);

      expect(stdout.channel, SshOutputChannel.stdout);
      expect(stdout.bytes, [111, 107]);
      expect(stderr.channel, SshOutputChannel.stderr);
      expect(stderr.bytes, [101, 114, 114]);
    });
  });

  group('NFR-002 platform capability', () {
    test('does not pretend every transport has identical capabilities', () {
      final capabilities = SshTransportCapabilities(
        rawTcp: false,
        requiresBridge: true,
      );

      expect(capabilities.rawTcp, isFalse);
      expect(capabilities.requiresBridge, isTrue);
    });
  });
}

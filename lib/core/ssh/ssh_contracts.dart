enum SshSessionState {
  disconnected,
  connecting,
  error,
  verifyingHost,
  authenticating,
  openingSession,
  connected,
  disconnecting,
}

enum SshHostVerificationDecision { trust, reject }

enum SshFailureCode { hostKeyMismatch }

enum SshAuthenticationMethod { password, publicKey }

enum SshOutputChannel { stdout, stderr }

final class SshConnectionRequest {
  const SshConnectionRequest({
    required this.host,
    required this.port,
    required this.username,
    this.allocatePty = true,
  });

  final String host;
  final int port;
  final String username;

  /// Allocate a pseudo-terminal for interactive terminal sessions.
  ///
  /// When false, SSH keeps stdout and stderr on separate channels.
  final bool allocatePty;
}

final class SshHostIdentity {
  const SshHostIdentity({
    required this.algorithm,
    required this.fingerprint,
  });

  final String algorithm;
  final String fingerprint;
}

final class SshFailure {
  const SshFailure._({
    required this.code,
    this.expectedFingerprint,
    this.actualFingerprint,
  });

  const SshFailure.hostKeyMismatch({
    required String expectedFingerprint,
    required String actualFingerprint,
  }) : this._(
          code: SshFailureCode.hostKeyMismatch,
          expectedFingerprint: expectedFingerprint,
          actualFingerprint: actualFingerprint,
        );

  final SshFailureCode code;
  final String? expectedFingerprint;
  final String? actualFingerprint;
}

final class SshAuthenticationRequest {
  const SshAuthenticationRequest._({
    required this.username,
    required this.method,
  });

  const SshAuthenticationRequest.password({required String username})
      : this._(
          username: username,
          method: SshAuthenticationMethod.password,
        );

  const SshAuthenticationRequest.publicKey({required String username})
      : this._(
          username: username,
          method: SshAuthenticationMethod.publicKey,
        );

  final String username;
  final SshAuthenticationMethod method;
}

final class SshOutput {
  const SshOutput._({
    required this.channel,
    required this.bytes,
  });

  const SshOutput.stdout(List<int> bytes)
      : this._(channel: SshOutputChannel.stdout, bytes: bytes);

  const SshOutput.stderr(List<int> bytes)
      : this._(channel: SshOutputChannel.stderr, bytes: bytes);

  final SshOutputChannel channel;
  final List<int> bytes;
}

final class SshTransportCapabilities {
  const SshTransportCapabilities({
    required this.rawTcp,
    required this.requiresBridge,
  });

  final bool rawTcp;
  final bool requiresBridge;
}

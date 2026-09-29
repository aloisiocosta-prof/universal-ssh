import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';

import 'ssh_contracts.dart';
import '../transport/ssh_socket_factory.dart';

typedef HostKeyDecision = Future<bool> Function(SshHostIdentity identity);
typedef PasswordRequest = Future<String?> Function();

final class SshTerminalSession {
  SshTerminalSession._(this._client, this._session);

  final SSHClient _client;
  final SSHSession _session;

  Stream<Uint8List> get stdout => _session.stdout;
  Stream<Uint8List> get stderr => _session.stderr;
  Future<void> get done => _session.done;

  void write(List<int> bytes) =>
      _session.write(Uint8List.fromList(bytes));

  void resize(int columns, int rows) =>
      _session.resizeTerminal(columns, rows);

  Future<void> close() async {
    _session.close();
    _client.close();
    await done;
  }
}

/// Opens a real SSH transport, verifies the server key before requesting a
/// password, authenticates and starts an interactive remote shell.
///
/// No credential or host-key decision is persisted by this service. The
/// caller must present every fingerprint to the user and obtain consent.
final class SshConnectionService {
  const SshConnectionService();

  Future<SshTerminalSession> connect({
    required SshConnectionRequest request,
    required HostKeyDecision onVerifyHostKey,
    required PasswordRequest requestPassword,
    String? gatewayUrl,
    String? gatewayToken,
  }) async {
    final host = request.host.trim();
    final username = request.username.trim();
    if (host.isEmpty || username.isEmpty) {
      throw ArgumentError('Host and username are required.');
    }
    if (request.port < 1 || request.port > 65535) {
      throw ArgumentError.value(request.port, 'port', 'must be 1–65535');
    }

    final socket = await createPlatformSshSocket(
      host: host,
      port: request.port,
      gatewayUrl: gatewayUrl,
      gatewayToken: gatewayToken,
    );

    var passwordAvailable = true;
    final client = SSHClient(
      socket,
      username: username,
      handshakeTimeout: const Duration(seconds: 20),
      authTimeout: const Duration(seconds: 30),
      onVerifyHostKey: (type, fingerprint) => onVerifyHostKey(
        SshHostIdentity(
          algorithm: type,
          fingerprint: utf8.decode(fingerprint),
        ),
      ),
      onPasswordRequest: () async {
        if (!passwordAvailable) return null;
        passwordAvailable = false;
        return requestPassword();
      },
    );

    try {
      await client.authenticated;
      final shell = await client.shell(
        pty: const SSHPtyConfig(type: 'xterm-256color', width: 80, height: 24),
      );
      return SshTerminalSession._(client, shell);
    } catch (_) {
      client.close();
      rethrow;
    }
  }
}

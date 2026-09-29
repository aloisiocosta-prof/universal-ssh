import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart'
    show FilledButton, Key, SelectableText, TextInputAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/ssh/ssh_runtime.dart';
import 'package:universal_ssh/main.dart';

void main() {
  testWidgets('renders the SSH connection flow', (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    expect(find.text('Universal SSH'), findsWidgets);
    expect(find.text('Conectar a um servidor SSH'), findsOneWidget);
    expect(find.byKey(const Key('host-field')), findsOneWidget);
    expect(find.byKey(const Key('port-field')), findsOneWidget);
    expect(find.byKey(const Key('username-field')), findsOneWidget);
    expect(find.byKey(const Key('connect-button')), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);
  });

  testWidgets('confirms host key before password and runs an SSH shell',
      (tester) async {
    final connector = _FakeSshConnectable();
    await tester.pumpWidget(UniversalSshApp(connector: connector));
    await _fillConnectionForm(tester);

    await tester.tap(find.byKey(const Key('connect-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Confirme a chave do servidor'), findsOneWidget);
    expect(connector.passwordRequests, 0);

    await tester.tap(find.byKey(const Key('accept-host-key')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Autenticação SSH'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password-field')), 'secret');
    await tester.tap(find.byKey(const Key('submit-password')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(connector.password, 'secret');
    expect(find.text('Conectado'), findsOneWidget);
    expect(find.text('Shell remoto • ssh.example.test'), findsOneWidget);

    connector.session.stdoutController.add(
      Uint8List.fromList('ready\n'.codeUnits),
    );
    connector.session.stderrController.add(
      Uint8List.fromList('warning\n'.codeUnits),
    );
    await tester.pump();
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText).last).data,
      'ready\nwarning\n',
    );

    await tester.enterText(find.byKey(const Key('terminal-input')), 'whoami');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(connector.session.written, 'whoami\r'.codeUnits);

    final disconnectButton = find.byKey(const Key('disconnect-button'));
    await tester.ensureVisible(disconnectButton);
    await tester.tap(disconnectButton);
    await tester.pump();
    await tester.idle();
    await tester.pump();
    expect(connector.session.closed, isTrue);
    expect(find.text('Desconectado'), findsOneWidget);
  });

  testWidgets('rejected host key never requests a password', (tester) async {
    final connector = _FakeSshConnectable();
    connector.acceptHostKey = false;
    await tester.pumpWidget(UniversalSshApp(connector: connector));
    await _fillConnectionForm(tester);

    await tester.tap(find.byKey(const Key('connect-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('reject-host-key')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(connector.passwordRequests, 0);
    expect(find.text('Erro'), findsOneWidget);
  });
}

Future<void> _fillConnectionForm(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const Key('host-field')), 'ssh.example.test');
  await tester.enterText(find.byKey(const Key('username-field')), 'alice');
  await tester.pump();
  final connect = tester.widget<FilledButton>(
    find.byKey(const Key('connect-button')),
  );
  expect(connect.onPressed, isNotNull);
}

final class _FakeSshConnectable implements SshConnectable {
  final session = _FakeSshSession();
  int passwordRequests = 0;
  String? password;
  bool acceptHostKey = true;

  @override
  Future<SshTerminalSession> connect({
    required SshConnectionRequest request,
    required HostKeyDecision onVerifyHostKey,
    required PasswordRequest requestPassword,
    String? gatewayUrl,
    String? gatewayToken,
  }) async {
    expect(request.host, 'ssh.example.test');
    expect(request.username, 'alice');
    final accepted = await onVerifyHostKey(
      const SshHostIdentity(
        algorithm: 'ssh-ed25519',
        fingerprint: 'SHA256:test-fingerprint',
      ),
    );
    if (!acceptHostKey || !accepted) {
      throw StateError('Host key rejected.');
    }
    passwordRequests++;
    password = await requestPassword();
    if (password == null) throw StateError('Authentication canceled.');
    return session;
  }
}

final class _FakeSshSession implements SshTerminalSession {
  final stdoutController = StreamController<Uint8List>();
  final stderrController = StreamController<Uint8List>();
  final _done = Completer<void>();
  List<int> written = <int>[];
  bool closed = false;

  @override
  Stream<Uint8List> get stdout => stdoutController.stream;

  @override
  Stream<Uint8List> get stderr => stderrController.stream;

  @override
  Future<void> get done => _done.future;

  @override
  void write(List<int> bytes) => written = List<int>.of(bytes);

  @override
  void resize(int columns, int rows) {}

  @override
  Future<void> close() async {
    closed = true;
    await stdoutController.close();
    await stderrController.close();
    if (!_done.isCompleted) _done.complete();
  }
}

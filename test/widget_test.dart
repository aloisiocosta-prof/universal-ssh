import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/ssh/ssh_contracts.dart';
import 'package:universal_ssh/core/transport/ssh_transport.dart';
import 'package:universal_ssh/main.dart';

void main() {
  testWidgets('renders connection form and dispatches a real transport request',
      (tester) async {
    final transport = RecordingSshTransport();
    await tester.pumpWidget(UniversalSshApp(transport: transport));

    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Porta'), findsOneWidget);
    expect(find.text('Usuário'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('host')), '192.168.1.10');
    await tester.enterText(find.byKey(const Key('port')), '22');
    await tester.enterText(find.byKey(const Key('username')), 'aluno');
    await tester.tap(find.text('Conectar'));
    await tester.pump();

    expect(transport.lastRequest?.host, '192.168.1.10');
    expect(transport.lastRequest?.port, 22);
    expect(transport.lastRequest?.username, 'aluno');
    expect(find.text('Conectando…'), findsOneWidget);
  });
}

final class RecordingSshTransport implements SshTransport {
  final Completer<SshTransportConnection> _connection = Completer();
  SshConnectionRequest? lastRequest;

  @override
  SshTransportCapabilities get capabilities =>
      const SshTransportCapabilities(rawTcp: true, requiresBridge: false);

  @override
  Future<SshTransportConnection> connect(SshConnectionRequest request) {
    lastRequest = request;
    return _connection.future;
  }
}

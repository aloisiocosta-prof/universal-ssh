import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/main.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validates endpoint data before continuing', (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    final connect = tester.widget<FilledButton>(
      find.byKey(const Key('connect-button')),
    );
    expect(connect.onPressed, isNull);

    await tester.enterText(
        find.byKey(const Key('host-field')), 'server.example');
    await tester.enterText(find.byKey(const Key('user-field')), 'demo');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('connect-button')))
          .onPressed,
      isNotNull,
    );

    await tester.enterText(find.byKey(const Key('port-field')), '65536');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('connect-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('demonstrates host verification, access, terminal and disconnect',
      (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    await tester.enterText(
        find.byKey(const Key('host-field')), 'server.example');
    await tester.enterText(find.byKey(const Key('port-field')), '22');
    await tester.enterText(find.byKey(const Key('user-field')), 'demo');
    await tapVisible(tester, find.byKey(const Key('connect-button')));

    expect(find.text('Verifique a chave do host'), findsOneWidget);
    expect(find.text('SHA256:DEMO-ONLY-NOT-A-REAL-HOST-KEY'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('trust-host-key')));
    expect(find.text('Autenticação'), findsOneWidget);
    expect(find.textContaining('não digite senha nem chave privada'),
        findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('simulate-auth')));
    expect(find.byKey(const Key('terminal-output')), findsOneWidget);
    expect(find.textContaining('nenhum servidor foi acessado'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('command-field')), 'whoami');
    await tapVisible(tester, find.byKey(const Key('send-command')));
    expect(find.text('demo'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('disconnect-button')));
    expect(find.text('Nova conexão'), findsOneWidget);
    expect(find.text('Sessão demonstrativa encerrada.'), findsOneWidget);
  });

  testWidgets('rejected host key returns to endpoint form', (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    await tester.enterText(
        find.byKey(const Key('host-field')), 'server.example');
    await tester.enterText(find.byKey(const Key('user-field')), 'demo');
    await tapVisible(tester, find.byKey(const Key('connect-button')));

    await tapVisible(tester, find.byKey(const Key('reject-host-key')));
    expect(find.text('Nova conexão'), findsOneWidget);
    expect(find.text('Chave rejeitada. Nenhuma conexão foi iniciada.'),
        findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/main.dart';

void main() {
  testWidgets('validates endpoint data before continuing',
      (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    final connect = tester.widget<FilledButton>(
      find.byKey(const Key('connect-button')),
    );
    expect(connect.onPressed, isNull);

    expect(find.text('Verifique a chave do host'), findsNothing);
  });

  testWidgets('demonstrates host verification, access, terminal and disconnect',
      (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    await tester.enterText(find.byKey(const Key('host-field')), 'server.example');
    await tester.enterText(find.byKey(const Key('port-field')), '22');
    await tester.enterText(find.byKey(const Key('user-field')), 'demo');
    await tester.tap(find.byKey(const Key('connect-button')));
    await tester.pumpAndSettle();

    expect(find.text('Verifique a chave do host'), findsOneWidget);
    expect(find.text('SHA256:DEMO-ONLY-NOT-A-REAL-HOST-KEY'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trust-host-key')));
    await tester.pumpAndSettle();
    expect(find.text('Autenticação'), findsOneWidget);
    expect(find.textContaining('não digite senha nem chave privada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('simulate-auth')));
    await tester.pumpAndSettle();
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.textContaining('nenhum servidor foi acessado'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('command-field')), 'whoami');
    await tester.tap(find.byKey(const Key('send-command')));
    await tester.pumpAndSettle();
    expect(find.text('demo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('disconnect-button')));
    await tester.pumpAndSettle();
    expect(find.text('Nova conexão'), findsOneWidget);
    expect(find.text('Sessão demonstrativa encerrada.'), findsOneWidget);
  });

  testWidgets('rejected host key returns to endpoint form', (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    await tester.enterText(find.byKey(const Key('host-field')), 'server.example');
    await tester.enterText(find.byKey(const Key('user-field')), 'demo');
    await tester.tap(find.byKey(const Key('connect-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reject-host-key')));
    await tester.pumpAndSettle();
    expect(find.text('Nova conexão'), findsOneWidget);
    expect(find.text('Chave rejeitada. Nenhuma conexão foi iniciada.'),
        findsOneWidget);
  });
}

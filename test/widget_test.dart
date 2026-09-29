import 'package:flutter_test/flutter_test.dart';
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
}

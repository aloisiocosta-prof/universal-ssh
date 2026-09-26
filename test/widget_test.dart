import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/main.dart';

void main() {
  testWidgets('renders Universal SSH shell', (tester) async {
    await tester.pumpWidget(const UniversalSshApp());

    expect(find.text('Universal SSH'), findsWidgets);
    expect(find.text('Web • Android • Windows x64 • Xbox One'), findsOneWidget);
    expect(find.text('Nova conexão'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/platform_transport.dart';

void main() {
  group('Flutter runtime transport capabilities', () {
    test(
      'browser Web runtime requires a bridge because it has no raw TCP',
      () {
        final capabilities = transportCapabilitiesFor(
          SshRuntimePlatform.web,
        );

        expect(capabilities.rawTcp, isFalse);
        expect(capabilities.requiresBridge, isTrue);
      },
    );

    test('Android Flutter runtime exposes native raw TCP', () {
      final capabilities = transportCapabilitiesFor(
        SshRuntimePlatform.android,
      );

      expect(capabilities.rawTcp, isTrue);
      expect(capabilities.requiresBridge, isFalse);
    });

    test(
      'Flutter Web embedded in the UWP host still requires a bridge',
      () {
        final capabilities = transportCapabilitiesFor(
          SshRuntimePlatform.uwpWebView,
        );

        expect(capabilities.rawTcp, isFalse);
        expect(capabilities.requiresBridge, isTrue);
      },
    );
  });
}

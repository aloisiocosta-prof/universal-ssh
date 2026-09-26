import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/platform_transport.dart';

void main() {
  group('platform transport capabilities', () {
    test(
      'Web requires a bridge because browser Dart has no raw TCP socket',
      () {
      final capabilities = transportCapabilitiesFor(SshRuntimePlatform.web);

      expect(capabilities.rawTcp, isFalse);
        expect(capabilities.requiresBridge, isTrue);
      },
    );

    test('Android exposes a native raw TCP transport', () {
      final capabilities = transportCapabilitiesFor(SshRuntimePlatform.android);

      expect(capabilities.rawTcp, isTrue);
      expect(capabilities.requiresBridge, isFalse);
    });

    test('UWP exposes a native raw TCP transport boundary', () {
      final capabilities = transportCapabilitiesFor(SshRuntimePlatform.uwp);

      expect(capabilities.rawTcp, isTrue);
      expect(capabilities.requiresBridge, isFalse);
    });
  });
}

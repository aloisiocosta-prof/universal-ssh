import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/dart_io_ssh_transport.dart';
import 'package:universal_ssh/core/transport/platform_transport_factory.dart';

void main() {
  test('native Dart runtime selects the Dart IO raw TCP transport', () {
    final transport = createPlatformSshTransport();

    expect(transport, isA<DartIoSshTransport>());
    expect(transport.capabilities.rawTcp, isTrue);
    expect(transport.capabilities.requiresBridge, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/uwp_bridge_protocol.dart';

void main() {
  group('UWP host bridge protocol', () {
    test('encodes a connect request without credentials', () {
      final message = UwpBridgeMessage.connect(
        host: 'ssh.example.test',
        port: 2222,
      );

      expect(message.toJson(), {
        'type': 'connect',
        'host': 'ssh.example.test',
        'port': 2222,
      });
    });

    test('encodes binary payload as base64 text for the WebView boundary', () {
      final message = UwpBridgeMessage.data([83, 83, 72]);

      expect(message.toJson(), {
        'type': 'data',
        'payload': 'U1NI',
      });
    });

    test('encodes an explicit close request', () {
      final message = UwpBridgeMessage.close();

      expect(message.toJson(), {'type': 'close'});
    });
  });
}

// CI synchronization marker: protocol contract intentionally unchanged.

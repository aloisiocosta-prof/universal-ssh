import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/uwp_bridge_protocol.dart';

void main() {
  group('UWP host bridge events', () {
    test('decodes a connected event', () {
      expect(
        UwpBridgeEvent.fromJson({'type': 'connected'}),
        isA<UwpBridgeConnectedEvent>(),
      );
    });

    test('decodes base64 data into binary payload', () {
      final event = UwpBridgeEvent.fromJson({
        'type': 'data',
        'payload': 'U1NI',
      });

      expect(event, isA<UwpBridgeDataEvent>());
      expect((event as UwpBridgeDataEvent).bytes, [83, 83, 72]);
    });

    test('decodes a closed event', () {
      expect(
        UwpBridgeEvent.fromJson({'type': 'closed'}),
        isA<UwpBridgeClosedEvent>(),
      );
    });

    test('decodes an error event without exposing credentials', () {
      final event = UwpBridgeEvent.fromJson({
        'type': 'error',
        'code': 'connection_failed',
        'message': 'Unable to connect to host.',
      });

      expect(event, isA<UwpBridgeErrorEvent>());
      final error = event as UwpBridgeErrorEvent;
      expect(error.code, 'connection_failed');
      expect(error.message, 'Unable to connect to host.');
    });
  });
}

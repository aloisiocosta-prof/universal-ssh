import 'dart:convert';

sealed class UwpBridgeMessage {
  const UwpBridgeMessage();

  factory UwpBridgeMessage.connect({
    required String host,
    required int port,
  }) = UwpBridgeConnectMessage;

  factory UwpBridgeMessage.data(List<int> bytes) = UwpBridgeDataMessage;

  factory UwpBridgeMessage.close() = UwpBridgeCloseMessage;

  Map<String, Object> toJson();
}

final class UwpBridgeConnectMessage extends UwpBridgeMessage {
  const UwpBridgeConnectMessage({
    required this.host,
    required this.port,
  });

  final String host;
  final int port;

  @override
  Map<String, Object> toJson() => {
        'type': 'connect',
        'host': host,
        'port': port,
      };
}

final class UwpBridgeDataMessage extends UwpBridgeMessage {
  UwpBridgeDataMessage(List<int> bytes) : payload = base64Encode(bytes);

  final String payload;

  @override
  Map<String, Object> toJson() => {
        'type': 'data',
        'payload': payload,
      };
}

final class UwpBridgeCloseMessage extends UwpBridgeMessage {
  const UwpBridgeCloseMessage();

  @override
  Map<String, Object> toJson() => {'type': 'close'};
}

sealed class UwpBridgeEvent {
  const UwpBridgeEvent();

  factory UwpBridgeEvent.fromJson(Map<String, Object> json) =>
      switch (json['type']) {
        'connected' => const UwpBridgeConnectedEvent(),
        'data' => UwpBridgeDataEvent(base64Decode(json['payload']! as String)),
        'closed' => const UwpBridgeClosedEvent(),
        'error' => UwpBridgeErrorEvent(
            code: json['code']! as String,
            message: json['message']! as String,
          ),
        final type => throw FormatException('Unknown UWP bridge event: $type'),
      };
}

final class UwpBridgeConnectedEvent extends UwpBridgeEvent {
  const UwpBridgeConnectedEvent();
}

final class UwpBridgeDataEvent extends UwpBridgeEvent {
  const UwpBridgeDataEvent(this.bytes);

  final List<int> bytes;
}

final class UwpBridgeClosedEvent extends UwpBridgeEvent {
  const UwpBridgeClosedEvent();
}

final class UwpBridgeErrorEvent extends UwpBridgeEvent {
  const UwpBridgeErrorEvent({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

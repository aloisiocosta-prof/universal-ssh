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

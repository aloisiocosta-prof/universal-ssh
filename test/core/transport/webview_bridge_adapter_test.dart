import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/uwp_bridge_protocol.dart';
import 'package:universal_ssh/core/transport/webview_bridge_adapter.dart';

void main() {
  test('serializes bridge messages before notifying the UWP host', () {
    String? notification;
    final adapter = WebViewBridgeAdapter((value) => notification = value);

    adapter.send(
      UwpBridgeMessage.connect(host: 'ssh.example.test', port: 22),
    );

    expect(
      jsonDecode(notification!),
      {
        'type': 'connect',
        'host': 'ssh.example.test',
        'port': 22,
      },
    );
  });
}

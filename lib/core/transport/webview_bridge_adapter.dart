import 'dart:convert';

import 'uwp_bridge_protocol.dart';

typedef WebViewHostNotifier = void Function(String value);

final class WebViewBridgeAdapter {
  const WebViewBridgeAdapter(this._notifyHost);

  final WebViewHostNotifier _notifyHost;

  void send(UwpBridgeMessage message) {
    _notifyHost(jsonEncode(message.toJson()));
  }
}

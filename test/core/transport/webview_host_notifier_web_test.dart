import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/webview_bridge_adapter.dart';
import 'package:universal_ssh/core/transport/webview_host_notifier.dart';

void main() {
  test('creates a platform-selected WebView host notifier', () {
    final WebViewHostNotifier notifier = createWebViewHostNotifier();

    expect(notifier, isA<WebViewHostNotifier>());
  });
}

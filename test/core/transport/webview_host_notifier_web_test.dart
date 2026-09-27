import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/core/transport/webview_bridge_adapter.dart';
import 'package:universal_ssh/core/transport/webview_host_notifier_web.dart';

void main() {
  test('creates a notifier for the UWP WebView host boundary', () {
    final WebViewHostNotifier notifier = createWebViewHostNotifier();

    expect(notifier, isA<WebViewHostNotifier>());
  });
}

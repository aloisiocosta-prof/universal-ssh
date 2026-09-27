import 'webview_bridge_adapter.dart';

WebViewHostNotifier createWebViewHostNotifier() =>
    (_) => throw UnsupportedError('UWP WebView host bridge is unavailable.');

import 'dart:js_interop';

import 'webview_bridge_adapter.dart';

@JS('window.external.notify')
external void _notifyUwpHost(JSString value);

WebViewHostNotifier createWebViewHostNotifier() =>
    (value) => _notifyUwpHost(value.toJS);

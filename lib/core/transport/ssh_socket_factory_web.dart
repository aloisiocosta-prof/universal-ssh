import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:web/web.dart' as web;

Future<SSHSocket> createPlatformSshSocket({
  required String host,
  required int port,
  String? gatewayUrl,
  String? gatewayToken,
}) async {
  final url = gatewayUrl?.trim() ?? '';
  final token = gatewayToken ?? '';
  final uri = Uri.tryParse(url);
  final localDevelopment =
      uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
  if (uri == null ||
      !(uri.scheme == 'wss' || (uri.scheme == 'ws' && localDevelopment)) ||
      token.length < 32) {
    throw ArgumentError(
      'Use a WSS gateway URL and its access token (at least 32 characters). '
      'Plain WS is allowed only for localhost development.',
    );
  }

  final socket = web.WebSocket(url)..binaryType = 'arraybuffer';
  final transport = _WebSocketSshSocket(socket);
  await transport.opened;
  socket.send(jsonEncode({
    'type': 'connect',
    'host': host,
    'port': port,
    'token': token,
  }).toJS);
  await transport.connected;
  return transport;
}

final class _WebSocketSshSocket implements SSHSocket {
  _WebSocketSshSocket(this._socket) {
    _socket.onopen = ((web.Event _) {
      if (!_opened.isCompleted) _opened.complete();
    }).toJS;
    _socket.onerror = ((web.Event _) {
      final error = StateError('The SSH gateway could not be reached.');
      if (!_opened.isCompleted) _opened.completeError(error);
      if (!_connected.isCompleted) _connected.completeError(error);
      if (!_done.isCompleted) _done.completeError(error);
      if (!_incoming.isClosed) _incoming.addError(error);
    }).toJS;
    _socket.onmessage = ((web.MessageEvent event) {
      final data = event.data;
      if (data == null) return;
      if (data.isA<JSString>()) {
        _handleControl((data as JSString).toDart);
        return;
      }
      if (!_connected.isCompleted || _incoming.isClosed) return;
      _incoming.add((data as JSArrayBuffer).toDart.asUint8List());
    }).toJS;
    _socket.onclose = ((web.CloseEvent _) {
      if (!_incoming.isClosed) _incoming.close();
      if (!_outgoing.isClosed) _outgoing.close();
      if (!_opened.isCompleted) {
        _opened.completeError(StateError('The SSH gateway closed early.'));
      }
      if (!_connected.isCompleted) {
        _connected.completeError(
          StateError('The SSH gateway rejected the target.'),
        );
      }
      if (!_done.isCompleted) _done.complete();
    }).toJS;
    _outgoing.stream.listen(
      (bytes) => _socket.send(Uint8List.fromList(bytes).toJS),
      onError: (Object error, StackTrace stackTrace) {
        if (!_done.isCompleted) _done.completeError(error, stackTrace);
      },
    );
  }

  final web.WebSocket _socket;
  final Completer<void> _opened = Completer<void>();
  final Completer<void> _connected = Completer<void>();
  final Completer<void> _done = Completer<void>();
  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();
  final StreamController<List<int>> _outgoing = StreamController<List<int>>();

  Future<void> get opened => _opened.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('SSH gateway open timed out.'),
      );

  Future<void> get connected => _connected.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'SSH gateway connection timed out.',
        ),
      );

  void _handleControl(String value) {
    try {
      final message = jsonDecode(value) as Map<String, dynamic>;
      if (message['type'] == 'connected') {
        if (!_connected.isCompleted) _connected.complete();
      } else {
        final code = message['code'] as String? ?? 'connection_failed';
        final error = StateError(
          'SSH gateway rejected the connection ($code).',
        );
        if (!_connected.isCompleted) _connected.completeError(error);
      }
    } on FormatException {
      final error = StateError('SSH gateway returned an invalid response.');
      if (!_connected.isCompleted) _connected.completeError(error);
    }
  }

  @override
  Stream<Uint8List> get stream => _incoming.stream;

  @override
  StreamSink<List<int>> get sink => _outgoing.sink;

  @override
  Future<void> get done => _done.future;

  @override
  Future<void> close() async {
    if (_socket.readyState == web.WebSocket.OPEN ||
        _socket.readyState == web.WebSocket.CONNECTING) {
      _socket.close();
    }
    await done;
  }

  @override
  void destroy() => _socket.close();

  @override
  Future<void> flush() async {}
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../lib/gateway/ssh_gateway_policy.dart';

Future<void> main() async {
  final policy = SshGatewayPolicy.fromEnvironment(Platform.environment);
  final port = int.tryParse(Platform.environment['SSH_GATEWAY_PORT'] ?? '8080');
  if (port == null || port < 1 || port > 65535) {
    throw ArgumentError('SSH_GATEWAY_PORT must be between 1 and 65535.');
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('SSH WebSocket gateway listening on port $port.');
  var activeConnections = 0;

  await for (final request in server) {
    if (request.uri.path != '/ssh' ||
        request.method != 'GET' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }
    if (!policy.allowsOrigin(request.headers.value(HttpHeaders.originHeader))) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      continue;
    }
    if (activeConnections >= 64) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      continue;
    }
    activeConnections++;
    unawaited(_serve(request, policy).whenComplete(() => activeConnections--));
  }
}

Future<void> _serve(HttpRequest request, SshGatewayPolicy policy) async {
  WebSocket? webSocket;
  Socket? sshSocket;
  StreamSubscription<dynamic>? webSubscription;
  StreamSubscription<dynamic>? sshSubscription;
  final firstFrame = Completer<dynamic>();
  final disconnected = Completer<void>();

  try {
    webSocket = await WebSocketTransformer.upgrade(request);
    webSubscription = webSocket.listen(
      (frame) {
        if (!firstFrame.isCompleted) {
          firstFrame.complete(frame);
        } else if (frame is List<int> && sshSocket != null) {
          sshSocket!.add(frame);
        }
      },
      onError: (_) {
        if (!firstFrame.isCompleted) {
          firstFrame.completeError(StateError('WebSocket closed.'));
        }
        if (!disconnected.isCompleted) disconnected.complete();
      },
      onDone: () {
        if (!firstFrame.isCompleted) {
          firstFrame.completeError(StateError('WebSocket closed.'));
        }
        if (!disconnected.isCompleted) disconnected.complete();
      },
      cancelOnError: true,
    );

    final firstMessage = await firstFrame.future.timeout(
      const Duration(seconds: 10),
    );
    if (firstMessage is! String || firstMessage.length > 4096) {
      await _reject(webSocket, 'invalid_request');
      return;
    }

    final payload = jsonDecode(firstMessage);
    if (payload is! Map<String, dynamic> ||
        payload['type'] != 'connect' ||
        payload['host'] is! String ||
        payload['port'] is! int ||
        payload['token'] is! String) {
      await _reject(webSocket, 'invalid_request');
      return;
    }

    final host = (payload['host'] as String).trim().toLowerCase();
    final port = payload['port'] as int;
    if (!policy.acceptsToken(payload['token'] as String)) {
      await _reject(webSocket, 'unauthorized');
      return;
    }
    if (!policy.allowsTarget(host, port)) {
      await _reject(webSocket, 'target_not_allowed');
      return;
    }

    sshSocket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 10),
    );
    webSocket.add(jsonEncode({'type': 'connected'}));
    sshSubscription = sshSocket.listen(
      (bytes) => webSocket!.add(bytes),
      onError: (_) {
        if (!disconnected.isCompleted) disconnected.complete();
      },
      onDone: () {
        if (!disconnected.isCompleted) disconnected.complete();
      },
      cancelOnError: true,
    );
    await disconnected.future;
  } on TimeoutException {
    if (webSocket != null) await _reject(webSocket, 'connection_timeout');
  } on SocketException {
    if (webSocket != null) await _reject(webSocket, 'target_unavailable');
  } on FormatException {
    if (webSocket != null) await _reject(webSocket, 'invalid_request');
  } catch (_) {
    if (webSocket != null) await _reject(webSocket, 'connection_failed');
  } finally {
    await webSubscription?.cancel();
    await sshSubscription?.cancel();
    sshSocket?.destroy();
    if (webSocket != null && webSocket.readyState != WebSocket.closed) {
      await webSocket.close();
    }
  }
}

Future<void> _reject(WebSocket socket, String code) async {
  if (socket.readyState == WebSocket.open) {
    socket.add(jsonEncode({'type': 'error', 'code': code}));
    await socket.close(WebSocketStatus.policyViolation);
  }
}

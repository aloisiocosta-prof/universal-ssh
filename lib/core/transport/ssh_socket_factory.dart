import 'package:dartssh2/dartssh2.dart';

import 'ssh_socket_factory_stub.dart'
    if (dart.library.io) 'ssh_socket_factory_io.dart'
    if (dart.library.js_interop) 'ssh_socket_factory_web.dart' as platform;

Future<SSHSocket> createPlatformSshSocket({
  required String host,
  required int port,
  String? gatewayUrl,
  String? gatewayToken,
}) =>
    platform.createPlatformSshSocket(
      host: host,
      port: port,
      gatewayUrl: gatewayUrl,
      gatewayToken: gatewayToken,
    );

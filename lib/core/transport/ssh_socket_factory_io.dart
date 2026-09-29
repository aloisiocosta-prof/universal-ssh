import 'package:dartssh2/dartssh2.dart';

Future<SSHSocket> createPlatformSshSocket({
  required String host,
  required int port,
  String? gatewayUrl,
  String? gatewayToken,
}) =>
    SSHSocket.connect(host, port, timeout: const Duration(seconds: 15));

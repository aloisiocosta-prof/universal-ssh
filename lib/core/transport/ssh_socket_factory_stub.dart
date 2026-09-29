import 'package:dartssh2/dartssh2.dart';

Future<SSHSocket> createPlatformSshSocket({
  required String host,
  required int port,
  String? gatewayUrl,
  String? gatewayToken,
}) =>
    throw UnsupportedError('No SSH socket adapter exists for this platform.');

import 'dart_io_ssh_transport.dart';
import 'ssh_transport.dart';

SshTransport createPlatformSshTransport() => DartIoSshTransport();

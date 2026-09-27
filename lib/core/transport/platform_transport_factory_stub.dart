import 'ssh_transport.dart';

SshTransport createPlatformSshTransport() =>
    throw UnsupportedError('This platform requires an SSH transport bridge.');

import '../ssh/ssh_contracts.dart';

abstract interface class SshTransport {
  SshTransportCapabilities get capabilities;

  Future<SshTransportConnection> connect(SshConnectionRequest request);
}

abstract interface class SshTransportConnection {
  Stream<List<int>> get incoming;

  Future<void> send(List<int> bytes);

  Future<void> close();
}

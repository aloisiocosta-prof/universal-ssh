final class SshGatewayTarget {
  const SshGatewayTarget({required this.host, required this.port});

  final String host;
  final int port;

  String get key => '${host.toLowerCase()}:$port';

  factory SshGatewayTarget.parse(String value) {
    final separator = value.lastIndexOf(':');
    if (separator <= 0 || separator == value.length - 1) {
      throw FormatException('Target must use host:port notation.');
    }
    var host = value.substring(0, separator).trim();
    final portText = value.substring(separator + 1).trim();
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    } else if (host.contains(':')) {
      throw FormatException('IPv6 targets must be enclosed in brackets.');
    }
    final port = int.tryParse(portText);
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      throw FormatException('Invalid SSH target.');
    }
    if (host.contains(RegExp(r'[^a-zA-Z0-9.:-]'))) {
      throw FormatException('Invalid SSH host.');
    }
    return SshGatewayTarget(host: host.toLowerCase(), port: port);
  }
}

final class SshGatewayPolicy {
  SshGatewayPolicy({
    required String token,
    required Iterable<String> targets,
    required Iterable<String> origins,
  })  : _token = token,
        _targets =
            targets.map((value) => SshGatewayTarget.parse(value).key).toSet(),
        _origins = origins
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet() {
    if (token.length < 32 || token.trim() != token) {
      throw ArgumentError('Gateway token must contain at least 32 characters.');
    }
    if (_targets.isEmpty || _origins.isEmpty) {
      throw ArgumentError('At least one target and one origin are required.');
    }
  }

  final String _token;
  final Set<String> _targets;
  final Set<String> _origins;

  bool allowsOrigin(String? origin) =>
      origin != null && _origins.contains(origin);

  bool allowsTarget(String host, int port) => _targets
      .contains(SshGatewayTarget(host: host.toLowerCase(), port: port).key);

  bool acceptsToken(String candidate) {
    final expected = _token.codeUnits;
    final actual = candidate.codeUnits;
    var difference = expected.length ^ actual.length;
    final limit =
        expected.length > actual.length ? expected.length : actual.length;
    for (var index = 0; index < limit; index++) {
      final left = index < expected.length ? expected[index] : 0;
      final right = index < actual.length ? actual[index] : 0;
      difference |= left ^ right;
    }
    return difference == 0;
  }

  factory SshGatewayPolicy.fromEnvironment(Map<String, String> environment) =>
      SshGatewayPolicy(
        token: environment['SSH_GATEWAY_TOKEN'] ?? '',
        targets: (environment['SSH_GATEWAY_ALLOWED_TARGETS'] ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
        origins: (environment['SSH_GATEWAY_ALLOWED_ORIGINS'] ?? '')
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );
}

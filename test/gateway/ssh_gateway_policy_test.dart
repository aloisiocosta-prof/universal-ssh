import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ssh/gateway/ssh_gateway_policy.dart';

void main() {
  group('SSH gateway policy', () {
    final policy = SshGatewayPolicy(
      token: 'a-secure-test-token-with-at-least-32-characters',
      targets: ['ssh.example.test:22', '[2001:db8::1]:2222'],
      origins: ['https://example.github.io'],
    );

    test('requires an exact allowed browser origin', () {
      expect(policy.allowsOrigin('https://example.github.io'), isTrue);
      expect(policy.allowsOrigin('https://attacker.example'), isFalse);
      expect(policy.allowsOrigin(null), isFalse);
    });

    test('only permits configured SSH destinations and ports', () {
      expect(policy.allowsTarget('SSH.EXAMPLE.TEST', 22), isTrue);
      expect(policy.allowsTarget('ssh.example.test', 2222), isFalse);
      expect(policy.allowsTarget('other.example.test', 22), isFalse);
      expect(policy.allowsTarget('2001:db8::1', 2222), isTrue);
    });

    test('checks the full gateway token', () {
      expect(
        policy.acceptsToken('a-secure-test-token-with-at-least-32-characters'),
        isTrue,
      );
      expect(policy.acceptsToken('a-secure-test-token'), isFalse);
    });

    test('rejects weak tokens and empty allow lists', () {
      expect(
        () => SshGatewayPolicy(
          token: 'short',
          targets: ['host:22'],
          origins: ['https://example.test'],
        ),
        throwsArgumentError,
      );
      expect(
        () => SshGatewayPolicy(
          token: 'a-secure-test-token-with-at-least-32-characters',
          targets: [],
          origins: ['https://example.test'],
        ),
        throwsArgumentError,
      );
    });

    test('parses bracketed IPv6 and rejects ambiguous unbracketed targets', () {
      expect(
        SshGatewayTarget.parse('[2001:db8::1]:2222').key,
        '2001:db8::1:2222',
      );
      expect(() => SshGatewayTarget.parse('2001:db8::1:22'), throwsFormatException);
    });
  });
}

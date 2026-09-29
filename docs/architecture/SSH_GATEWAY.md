# Real SSH sessions from Flutter Web

The client uses `dartssh2` for SSH transport negotiation, cryptography, explicit host-key verification, password authentication, and interactive shell I/O. Android connects to the configured SSH host directly through Dart's native TCP socket. Browsers cannot open raw TCP, so Web and the UWP WebView use the included WebSocket-to-TCP gateway. The gateway carries encrypted SSH packets; it does not decrypt SSH or receive the SSH password.

## Run the gateway for a controlled test

Run the gateway on a server reachable over TLS. Terminate TLS at a reverse proxy that supports WebSocket upgrade and forwards requests to port 8080.

Configure:

- `SSH_GATEWAY_TOKEN`: a random secret of at least 32 characters, provided to the client at connection time;
- `SSH_GATEWAY_ALLOWED_TARGETS`: exact comma-separated `host:port` destinations; IPv6 must use `[address]:port`;
- `SSH_GATEWAY_ALLOWED_ORIGINS`: exact comma-separated browser origins, for example `https://aloisiocosta-prof.github.io`;
- optional `SSH_GATEWAY_PORT`: listen port, default 8080.

Start with `dart run bin/ssh_gateway.dart`. The client connects to `wss://your-gateway.example/ssh`. Plain `ws://` is accepted by the Flutter client only for localhost development. The gateway rejects unknown origins, tokens, hosts, and ports and limits concurrent tunnels to 64. Do not expose it without TLS termination, a strong random token, and a narrowly scoped destination allowlist.

The access token is not an SSH credential. The user enters it for the gateway session and the app keeps it in memory only. The SSH password is requested only after the server host-key fingerprint is shown and accepted; it is not persisted.

## Limits of this MVP slice

The browser client presents an interactive text shell but does not yet emulate ANSI/VT terminal control sequences, persist trusted host keys, or implement keyboard-interactive/public-key authentication. Users confirm the presented host fingerprint on every connection. The Windows WebView can use the same WSS route; the native UWP bridge is not yet wired as a second socket adapter. Xbox compatibility still needs installation and interaction evidence from physical hardware in Developer Mode.

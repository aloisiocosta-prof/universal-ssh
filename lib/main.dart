import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/ssh/ssh_contracts.dart';
import 'core/ssh/ssh_runtime.dart';

void main() => runApp(const UniversalSshApp());

class UniversalSshApp extends StatelessWidget {
  const UniversalSshApp({
    super.key,
    this.connector = const SshConnectionService(),
  });

  final SshConnectable connector;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Universal SSH',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF63E6BE),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF07111F),
          useMaterial3: true,
        ),
        home: HomePage(connector: connector),
      );
}

enum _ClientState { disconnected, connecting, connected, error }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.connector});

  final SshConnectable connector;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '22');
  final _username = TextEditingController();
  final _gateway = TextEditingController();
  final _gatewayToken = TextEditingController();
  final _command = TextEditingController();
  final _outputScroll = ScrollController();
  final _output = StringBuffer();
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  SshTerminalSession? _session;
  _ClientState _state = _ClientState.disconnected;
  String? _error;
  String? _hostIdentityMessage;

  int? get _validPort => int.tryParse(_port.text.trim());

  bool get _canConnect {
    final port = _validPort;
    return _host.text.trim().isNotEmpty &&
        _username.text.trim().isNotEmpty &&
        port != null &&
        port >= 1 &&
        port <= 65535 &&
        _state != _ClientState.connecting &&
        (!kIsWeb ||
            (_gateway.text.trim().isNotEmpty &&
                _gatewayToken.text.length >= 32));
  }

  @override
  void dispose() {
    unawaited(_disconnect());
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _gateway.dispose();
    _gatewayToken.dispose();
    _command.dispose();
    _outputScroll.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final port = _validPort;
    if (!_canConnect || port == null) return;
    setState(() {
      _state = _ClientState.connecting;
      _error = null;
      _hostIdentityMessage = null;
    });

    try {
      final session = await widget.connector.connect(
        request: SshConnectionRequest(
          host: _host.text.trim(),
          port: port,
          username: _username.text.trim(),
        ),
        gatewayUrl: kIsWeb ? _gateway.text.trim() : null,
        gatewayToken: kIsWeb ? _gatewayToken.text : null,
        onVerifyHostKey: _confirmHostKey,
        requestPassword: _requestPassword,
      );
      _session = session;
      _gatewayToken.clear();
      _watch(session.stdout);
      _watch(session.stderr);
      unawaited(session.done.then((_) {
        if (mounted && identical(_session, session)) {
          setState(() {
            _session = null;
            _state = _ClientState.disconnected;
          });
        }
      }));
      if (mounted) {
        setState(() {
          _state = _ClientState.connected;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _session = null;
        _state = _ClientState.error;
        _error = _safeError(error);
      });
    }
  }

  Future<bool> _confirmHostKey(SshHostIdentity identity) async {
    if (!mounted) return false;
    setState(() {
      _hostIdentityMessage = '${identity.algorithm}\n${identity.fingerprint}';
    });
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirme a chave do servidor'),
        content: SelectableText(
          'Confira esta impressão digital por um canal confiável antes de '
          'prosseguir. A decisão vale somente para esta conexão.\n\n'
          '${identity.algorithm}\n${identity.fingerprint}',
        ),
        actions: [
          TextButton(
            key: const Key('reject-host-key'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rejeitar'),
          ),
          FilledButton(
            key: const Key('accept-host-key'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceitar e continuar'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<String?> _requestPassword() async {
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PasswordDialog(),
    );
  }

  void _watch(Stream<List<int>> stream) {
    final subscription = stream.listen(
      (bytes) {
        if (!mounted) return;
        final text = utf8.decode(bytes, allowMalformed: true);
        setState(() {
          _output.write(text);
          if (_output.length > 60000) {
            final current = _output.toString();
            _output
              ..clear()
              ..write(current.substring(current.length - 45000));
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_outputScroll.hasClients) {
            _outputScroll.jumpTo(_outputScroll.position.maxScrollExtent);
          }
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = _safeError(error));
      },
    );
    if (stream == _session?.stdout) {
      _stdoutSubscription = subscription;
    } else {
      _stderrSubscription = subscription;
    }
  }

  String _safeError(Object error) {
    final text = error.toString();
    if (text.contains('password') || text.contains('credential')) {
      return 'A conexão SSH falhou. Verifique o destino e a autenticação.';
    }
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _sendCommand(String value) {
    final session = _session;
    if (session == null) return;
    session.write(utf8.encode('$value\r'));
    _command.clear();
  }

  Future<void> _disconnect() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    final session = _session;
    _session = null;
    if (session != null) {
      await session.close();
    }
    if (mounted && _state != _ClientState.disconnected) {
      setState(() => _state = _ClientState.disconnected);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Universal SSH'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Chip(
                  key: const Key('session-state'),
                  avatar: Icon(
                    _state == _ClientState.connected
                        ? Icons.circle
                        : _state == _ClientState.connecting
                            ? Icons.sync
                            : Icons.circle_outlined,
                    size: 14,
                    color: _state == _ClientState.connected
                        ? const Color(0xFF63E6BE)
                        : null,
                  ),
                  label: Text(switch (_state) {
                    _ClientState.disconnected => 'Desconectado',
                    _ClientState.connecting => 'Conectando',
                    _ClientState.connected => 'Conectado',
                    _ClientState.error => 'Erro',
                  }),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, _) {
                    if (_state == _ClientState.connected) {
                      return _buildTerminal();
                    }
                    return _buildConnectionForm();
                  },
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildConnectionForm() => SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Conectar a um servidor SSH',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'A chave do servidor será exibida antes da senha. '
                  'A senha não é salva.',
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('host-field'),
                  controller: _host,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Host ou endereço IP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('port-field'),
                        controller: _port,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Porta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('username-field'),
                        controller: _username,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Usuário',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('gateway-field'),
                    controller: _gateway,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Gateway WSS (Web/PWA e WebView)',
                      hintText: 'wss://ssh-gateway.example/ssh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('gateway-token-field'),
                    controller: _gatewayToken,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Token de acesso do gateway',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_hostIdentityMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Chave recebida:\n$_hostIdentityMessage',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('connect-button'),
                  onPressed: _canConnect ? _connect : null,
                  icon: _state == _ClientState.connecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link),
                  label: Text(_state == _ClientState.connecting
                      ? 'Estabelecendo sessão SSH'
                      : 'Conectar'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildTerminal() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shell remoto • ${_host.text.trim()}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: const Key('disconnect-button'),
                tooltip: 'Desconectar',
                onPressed: _disconnect,
                icon: const Icon(Icons.power_settings_new),
              ),
            ],
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Expanded(
            child: Container(
              key: const Key('terminal-output'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF02070D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF26384D)),
              ),
              child: SingleChildScrollView(
                controller: _outputScroll,
                child: SelectableText(
                  _output.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    height: 1.35,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('terminal-input'),
            controller: _command,
            autofocus: true,
            onSubmitted: _sendCommand,
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: 'Digite um comando remoto e pressione Enter',
              suffixIcon: IconButton(
                key: const Key('send-command'),
                tooltip: 'Enviar ao shell remoto',
                onPressed: () => _sendCommand(_command.text),
                icon: const Icon(Icons.send),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      );
}


class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller
      ..clear()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Autenticação SSH'),
        content: TextField(
          key: const Key('password-field'),
          controller: _controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Senha do servidor'),
          onSubmitted: (_) => Navigator.pop(context, _controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('submit-password'),
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Autenticar'),
          ),
        ],
      );
}

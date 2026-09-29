import 'package:flutter/material.dart';

void main() => runApp(const UniversalSshApp());

class UniversalSshApp extends StatelessWidget {
  const UniversalSshApp({super.key});

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
        home: const HomePage(),
      );
}

enum DemoStep { connect, hostKey, authenticate, terminal }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _userController = TextEditingController();
  final _commandController = TextEditingController();
  final List<String> _terminalLines = <String>[
    'Protótipo visual. Nenhuma conexão SSH foi aberta.',
    'Digite pwd, whoami, ls ou clear para explorar o terminal fictício.',
  ];

  DemoStep _step = DemoStep.connect;
  String? _validationMessage;

  bool get _endpointIsValid {
    final port = int.tryParse(_portController.text.trim());
    return _hostController.text.trim().isNotEmpty &&
        _userController.text.trim().isNotEmpty &&
        port != null &&
        port > 0 &&
        port <= 65535;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _startDemo() {
    setState(() {
      _validationMessage = _endpointIsValid
          ? null
          : 'Informe host, usuário e uma porta entre 1 e 65535.';
      if (_endpointIsValid) {
        _step = DemoStep.hostKey;
      }
    });
  }

  void _trustDemoHostKey(bool trust) {
    setState(() {
      _step = trust ? DemoStep.authenticate : DemoStep.connect;
      _validationMessage =
          trust ? null : 'Chave rejeitada. Nenhuma conexão foi iniciada.';
    });
  }

  void _finishDemoAuthentication() {
    setState(() {
      _step = DemoStep.terminal;
      _terminalLines
        ..clear()
        ..add('Autenticação demonstrativa concluída.')
        ..add(
            'Sessão fictícia para validar a interface; nenhum servidor foi acessado.');
    });
  }

  void _sendDemoCommand() {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    setState(() {
      if (command == 'clear') {
        _terminalLines.clear();
      } else {
        final output = switch (command) {
          'whoami' => 'demo',
          'pwd' => '/home/demo',
          'ls' => 'documentos/  projetos/  README.txt',
          _ => 'Comando apenas exibido no protótipo: $command',
        };
        _terminalLines
          ..add('\$ $command')
          ..add(output);
      }
      _commandController.clear();
    });
  }

  void _disconnectDemo() {
    setState(() {
      _step = DemoStep.connect;
      _validationMessage = 'Sessão demonstrativa encerrada.';
      _terminalLines
        ..clear()
        ..add('Protótipo visual. Nenhuma conexão SSH foi aberta.')
        ..add(
            'Digite pwd, whoami, ls ou clear para explorar o terminal fictício.');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF0B1B2D),
                Color(0xFF07111F),
                Color(0xFF10172B)
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final intro = _buildIntro();
                      final panel = _buildWorkflowPanel();
                      if (constraints.maxWidth >= 820) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(child: intro),
                            const SizedBox(width: 44),
                            SizedBox(width: 470, child: panel),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          intro,
                          const SizedBox(height: 28),
                          panel
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildIntro() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.terminal_rounded,
                  color: Color(0xFF63E6BE), size: 34),
              const SizedBox(width: 12),
              Text('UNIVERSAL SSH',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 14),
              const Chip(
                avatar: Icon(Icons.science_outlined, size: 16),
                label: Text('DEMO VISUAL'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Seu terminal remoto,\ncom uma experiência simples.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Este protótipo percorre a jornada do cliente SSH. O fluxo abaixo é uma simulação de interface: ele não conecta a servidores.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFB8C7D9),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 24),
          const _FeatureLine(
              icon: Icons.verified_user_outlined,
              text: 'Confirmação explícita da chave do host'),
          const _FeatureLine(
              icon: Icons.devices_outlined,
              text: 'Fluxo pensado para Web, Windows e Xbox'),
          const _FeatureLine(
              icon: Icons.lock_outline,
              text: 'Sem armazenar credenciais neste protótipo'),
          const SizedBox(height: 24),
          const Text(
            'Próxima etapa real: conectar os adapters de transporte e validar a sessão SSH.',
            style: TextStyle(color: Color(0xFF91A4BA)),
          ),
        ],
      );

  Widget _buildWorkflowPanel() => Card(
        color: const Color(0xFF111F31),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF26384D)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildProgress(),
              const SizedBox(height: 22),
              const _DemoNotice(),
              const SizedBox(height: 22),
              _buildStepContent(),
            ],
          ),
        ),
      );

  Widget _buildProgress() {
    const labels = <String>['Conexão', 'Host key', 'Acesso', 'Terminal'];
    final current = _step.index;
    return Row(
      children: List<Widget>.generate(labels.length, (index) {
        final active = index <= current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF63E6BE)
                        : const Color(0xFF34465A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? const Color(0xFFEAF7F4)
                        : const Color(0xFF8495A8),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() => switch (_step) {
        DemoStep.connect => _buildConnectionForm(),
        DemoStep.hostKey => _buildHostKeyConfirmation(),
        DemoStep.authenticate => _buildAuthenticationStep(),
        DemoStep.terminal => _buildTerminal(),
      };

  Widget _buildConnectionForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Nova conexão',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Informe os dados do endpoint para avançar pela demonstração.'),
          const SizedBox(height: 20),
          _field('Host ou endereço IP', _hostController,
              key: const Key('host-field')),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  'Porta',
                  _portController,
                  key: const Key('port-field'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _field('Usuário', _userController,
                      key: const Key('user-field'))),
            ],
          ),
          if (_validationMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _validationMessage!,
              key: const Key('form-message'),
              style: const TextStyle(color: Color(0xFFFFC078)),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('connect-button'),
            onPressed: _endpointIsValid ? _startDemo : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuar demonstração'),
          ),
        ],
      );

  Widget _buildHostKeyConfirmation() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Verifique a chave do host',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Em um cliente real, confirme esta impressão digital por um canal confiável.'),
          const SizedBox(height: 18),
          _detailRow('Destino',
              '${_hostController.text.trim()}:${_portController.text.trim()}'),
          const SizedBox(height: 12),
          const _Fingerprint(),
          const SizedBox(height: 18),
          OutlinedButton(
            key: const Key('reject-host-key'),
            onPressed: () => _trustDemoHostKey(false),
            child: const Text('Rejeitar chave'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('trust-host-key'),
            onPressed: () => _trustDemoHostKey(true),
            child: const Text('Confiar nesta chave (demo)'),
          ),
        ],
      );

  Widget _buildAuthenticationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Autenticação',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Usuário: ${_userController.text.trim()}'),
          const SizedBox(height: 14),
          const Text(
            'A autenticação real ainda não está ligada. Para manter a demo segura, não digite senha nem chave privada.',
            style: TextStyle(color: Color(0xFFB8C7D9)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('simulate-auth'),
            onPressed: _finishDemoAuthentication,
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Simular autenticação'),
          ),
        ],
      );

  Widget _buildTerminal() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text('Terminal',
                      style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                key: const Key('disconnect-button'),
                tooltip: 'Desconectar',
                onPressed: _disconnectDemo,
                icon: const Icon(Icons.power_settings_new),
              ),
            ],
          ),
          Text(
            '${_hostController.text.trim()} • sessão demonstrativa',
            style: const TextStyle(color: Color(0xFF91A4BA)),
          ),
          const SizedBox(height: 14),
          Container(
            key: const Key('terminal-output'),
            constraints: const BoxConstraints(minHeight: 150, maxHeight: 230),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF07111F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF26384D)),
            ),
            child: ListView(
              shrinkWrap: true,
              children: _terminalLines
                  .map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(line,
                            style: const TextStyle(fontFamily: 'monospace')),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('command-field'),
                  controller: _commandController,
                  decoration: const InputDecoration(
                    labelText: 'Comando de demonstração',
                    hintText: 'whoami',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendDemoCommand(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('send-command'),
                tooltip: 'Executar na simulação',
                onPressed: _sendDemoCommand,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    required Key key,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _detailRow(String label, String value) => Row(
        children: <Widget>[
          Text('$label: ', style: const TextStyle(color: Color(0xFF91A4BA))),
          Expanded(child: Text(value)),
        ],
      );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF342A18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8C6A31)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, color: Color(0xFFFFC078), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Modo demonstração: não há conexão de rede, autenticação ou execução de comandos.',
                style: TextStyle(color: Color(0xFFFFD9A8)),
              ),
            ),
          ],
        ),
      );
}

class _Fingerprint extends StatelessWidget {
  const _Fingerprint();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1726),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Impressão digital ilustrativa'),
            SizedBox(height: 6),
            SelectableText(
              'SHA256:DEMO-ONLY-NOT-A-REAL-HOST-KEY',
              style:
                  TextStyle(fontFamily: 'monospace', color: Color(0xFF63E6BE)),
            ),
          ],
        ),
      );
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF63E6BE), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

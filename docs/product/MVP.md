# MVP: validar um cliente SSH

## Objetivo do produto

Entregar um protótipo funcional que permita testar a principal proposta de valor do Universal SSH. Os resultados de uso orientarão a decisão posterior sobre segmento, modelo de negócio e plano de negócio. Nenhum preço, forma de receita ou público pagante deve ser tratado como decidido antes da pesquisa.

## Hipótese de valor

Uma pessoa que administra servidores remotos pode valorizar um cliente SSH que ofereça uma experiência simples e coerente em navegador/PWA, Windows e Xbox, com suporte a teclado e controle quando apropriado. Esta hipótese precisa ser confrontada com uma sessão SSH real e com usuários-alvo; compilar ou publicar a aplicação não comprova valor.

## Principal funcionalidade

Fluxo vertical mínimo:

`configurar host, porta e usuário → conectar → verificar host key → autenticar → abrir terminal → enviar entrada → receber stdout/stderr → desconectar`

O MVP deve explicar erros e estados da sessão. A confirmação da host key deve ser explícita. Credenciais e chaves privadas não podem ser incluídas em logs, telemetria ou evidências compartilhadas.

## Arquitetura e distribuição propostas

| Superfície | Implementação do MVP | Artefato/evidência |
| --- | --- | --- |
| Web/PWA | Flutter/Dart gera `build/web`; GitHub Actions publica no GitHub Pages | Abrir pelo caminho de projeto `/universal-ssh/`, validar recursos, instalação e comportamento offline que estiver realmente implementado |
| Host UWP | Aplicativo nativo C#/WinRT carrega localmente os assets Flutter em WebView e expõe somente a bridge necessária | APPX/MSIX compilado e executado em Windows; o build não comprova funcionamento no console |
| Xbox | Mesmo pacote UWP compatível, sujeito a capacidades, políticas e entrada disponíveis | Só declarar compatibilidade depois de instalar e testar em Xbox físico via Developer Mode |
| Windows desktop | Priorizar pacote MSIX para o host compatível | Validar instalação e uso em Windows desktop |
| MSI | Fora do caminho UWP | Só criar com host/instalador Win32 separado; MSI não é outro nome para APPX/MSIX |
| Android | Mantido como superfície de regressão existente | Não é parte da primeira decisão comercial |

Os artefatos Web para Pages e UWP usam caminhos-base distintos. O primeiro usa `/universal-ssh/`; os assets incluídos no pacote UWP usam `/Web/`. Isso permite respeitar o caminho público do GitHub Pages e o diretório local do WebView.

## TDD e ferramentas nativas

Seguir Red → Green → Refactor para cada critério funcional:

- **Flutter/Dart:** `flutter_test`, analyzer, formatter e testes de widget; manter lógica de domínio testável sem UI.
- **Host UWP:** testes .NET/C# para protocolo da bridge, ciclo de vida e validação de comandos; build/empacotamento com MSBuild.
- **Web/PWA:** testes de navegador para fluxo, rotas/recursos no caminho Pages e integração com a bridge simulada; validar offline somente para recursos implementados.
- **Windows/Xbox:** evidência de execução nos dispositivos correspondentes. CI em Windows não substitui teste do Xbox físico.

Antes de implementar cada comportamento, criar um teste que falhe pela ausência dele; em seguida implementar a menor mudança que o torne verde e refatorar preservando os testes.

## Evidência para a decisão de negócio

Depois que o fluxo SSH funcionar, pesquisar usuários que executam tarefas de acesso remoto. Registrar tarefas, contexto, conclusão, fricções, alternativas atuais, frequência de uso e sinais de adoção. Para avaliar disposição a pagar, usar perguntas e experimentos apropriados e separar respostas declaradas de comportamento observado.

O relatório deve distinguir:

1. observações e evidências coletadas;
2. hipóteses ainda não validadas;
3. limites da amostra e riscos;
4. opções de modelo de negócio a investigar;
5. custos de desenvolvimento, operação, suporte e distribuição;
6. recomendação de próximos experimentos e plano de negócio.

Não decidir previamente entre assinatura, licença, freemium ou outra receita. Pesquisa de negócio: [issue #19](https://github.com/aloisiocosta-prof/universal-ssh/issues/19).

## Critérios de aceite do MVP

- [ ] Um usuário configura host, porta e usuário e inicia uma conexão real.
- [ ] O cliente apresenta a host key e exige decisão explícita antes de confiar nela.
- [ ] Uma autenticação segura funciona e trata sucesso, rejeição e cancelamento.
- [ ] Um shell mínimo envia entrada e apresenta stdout/stderr.
- [ ] Estados, erros e desconexão são compreensíveis e testados.
- [ ] O PWA abre no GitHub Pages no caminho correto e os recursos necessários carregam.
- [ ] O host UWP carrega o Web build local e gera APPX/MSIX.
- [ ] Execução em Windows desktop está documentada; Xbox tem evidência separada em hardware real.
- [ ] Testes automatizados e Quality Gate passam; requisitos críticos têm testes RED/GREEN.
- [ ] Testes com usuários-alvo e limites das evidências são documentados sem dados secretos.
- [ ] O relatório recomenda o próximo experimento de negócio sem alegar conclusões não sustentadas.

## Fora do primeiro MVP

SFTP, múltiplas abas, sincronização, gerenciamento avançado de chaves, monetização implementada, distribuição em lojas e um instalador MSI Win32 independente. Android permanece na regressão técnica, mas pode ser reavaliado no experimento comercial.

## Rastreamento

- Épico, escopo e critérios completos: [issue #10](https://github.com/aloisiocosta-prof/universal-ssh/issues/10).
- Fluxo SSH: issues #11–#17.
- Experimento multiplataforma: [issue #18](https://github.com/aloisiocosta-prof/universal-ssh/issues/18).
- Pesquisa de proposta de valor/modelo de negócio: [issue #19](https://github.com/aloisiocosta-prof/universal-ssh/issues/19).

# Development lifecycle

## Fonte de verdade

GitHub é a fonte de verdade:

```text
Epic -> Issue -> branch -> Conventional Commits -> Pull Request
     -> review + CI + security gates -> artifact + digest -> merge -> release
```

Nenhuma mudança funcional deve começar apenas como commit solto.

## GitFlow simplificado

- `main`: código/release estável; sem desenvolvimento direto.
- `develop`: integração das próximas mudanças.
- `feature/<issue>-<slug>`: funcionalidades.
- `fix/<issue>-<slug>`: correções.
- `security/<issue>-<slug>`: hardening/correções de segurança.
- `release/<version>`: estabilização opcional.
- `hotfix/<issue>-<slug>`: correção urgente baseada em `main`.

Fluxo normal: `feature/* -> develop -> release/* -> main`.

## Conventional Commits

```text
<type>(<scope>): <descrição>

Refs: #123
```

Tipos: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`, `revert`.

Commits devem ser pequenos, coesos e vinculados à Issue. Nunca incluir secrets, tokens ou dados pessoais em mensagens/logs.

## Issues, sub-issues e Kanban

Uma Epic agrega work items. Cada Issue contém contexto, critérios de aceite e impacto de segurança. Subtarefas são Issues próprias referenciadas no checklist da Epic.

```text
Backlog/Open -> branch/In progress -> Draft PR -> Ready for review
 -> CI/Security checks -> Approved -> Merged -> Closed/Done
```

Quando GitHub Projects v2 estiver habilitado, esses estados devem virar colunas/campos do Project; Issues e PRs continuam sendo a fonte de verdade.

## Pull Requests

Todo PR deve apontar para Issue usando `Closes #N` quando apropriado, explicar mudança/risco, demonstrar critérios de aceite e passar CI/security gates.

Ruleset recomendado para `main` e `develop`: exigir PR, impedir force push/deletion, exigir branch atualizada, checks obrigatórios e aprovação quando houver segundo mantenedor.

## Audit trail

```text
Issue ID -> branch -> commit SHA -> PR -> workflow run ID
 -> job/step -> logs -> artifact -> digest -> merge SHA -> tag/release
```

Logs extensos não são copiados para Git: permanecem no Actions/Release com retenção. O Git versiona políticas, manifests e relatórios pequenos/reproduzíveis.

## DevSecOps

Quality gates mínimos:
- análise estática e testes;
- build reproduzível;
- dependency review em PRs quando disponível;
- secret scanning/push protection quando disponível;
- CodeQL/SAST quando compatível;
- menor privilégio para `GITHUB_TOKEN`;
- actions confiáveis;
- secrets apenas em GitHub Secrets/Environments;
- assinatura/proveniência no release.

Falhas de segurança bloqueiam promoção para release.

## Definition of Done

Uma Issue só está Done quando os critérios foram demonstrados, PR mergeado, checks verdes e documentação/artifacts aplicáveis estão rastreáveis.

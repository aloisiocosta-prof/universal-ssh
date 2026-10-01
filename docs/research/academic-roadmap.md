# Roteiro acadêmico — Universal SSH

## Situação
O repositório já contém pergunta, requisitos SSH, protocolo experimental, matriz por plataforma e workflow de evidências. O protocolo ressalva corretamente que build bem-sucedido não demonstra sessão SSH funcional nem compatibilidade Xbox; falta executar e analisar os testes end-to-end.

## Problema, objeto e pergunta
Problema: oferecer sessão SSH observável em Web, Android e UWP/Xbox pode exigir adaptações cujos custos e limites precisam ser medidos.
Objeto: contratos, adapters e sessão SSH por plataforma.
Pergunta: manter a questão de docs/research/ssh-mvp.md e separá-la em equivalência funcional, limitações e custo de cada adaptação.

## Objetivo e etapas
Avaliar capacidades SSH por plataforma com servidor controlado e artefatos reproduzíveis.
1. Congelar critérios de sessão e matriz de requisitos.
2. Usar servidor não produtivo, host key conhecida e credenciais de teste efêmeras.
3. Registrar commit, runtime, dispositivo, configuração, tempos, erros e logs sanitizados.
4. Repetir transporte, autenticação, verificação de host, canal e desconexão em cada alvo.
5. Medir com repetições; separar emulador, desktop e hardware Xbox.
6. Analisar validade e publicar pacote de replicação sem segredos.

## Revisão
Usar RFC 4253, 4252 e 4254 para camadas SSH; atualizar a revisão de algoritmos criptográficos com orientação atual IETF/NIST antes de qualquer recomendação. Consultar padrões empíricos da ACM SIGSOFT quando aplicáveis: https://www2.sigsoft.org/EmpiricalStandards/.

## Publicação e apresentação
Artigo de engenharia de artefato somente após evidência end-to-end; não alegar avaliação de segurança sem testes especializados. Banner deve separar Web, Android, UWP x64 e Xbox, marcando medições pendentes.

## Próximo gate
Implementar RED tests para os requisitos já listados no protocolo e publicar somente métricas reproduzidas, nunca dados de acesso sensíveis.
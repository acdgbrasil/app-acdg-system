# Report — 2026-03-18 — Code Review e Refatoração de Infraestrutura

## Contexto
Análise profunda do código da aplicação principal (`apps/acdg_system`) e saneamento das dependências do monorepo após identificação de vazamentos de pacotes e inconsistências de configuração.

## Decisões Tomadas

1. **Refatoração do `Env` (Best Pattern):**
   - Migração de `String.fromEnvironment` dinâmico para `static const` para permitir tree-shaking.
   - Implementação de `Env.validate()` no `main.dart` para garantir que a aplicação não inicie com configurações OIDC corrompidas ou faltantes.
   
2. **Saneamento de Dependências (Melos):**
   - Correção de múltiplos erros de `depend_on_referenced_packages`.
   - Adição explícita de `social_care`, `core`, `dio`, `meta`, `mocktail` e `flutter` nos pacotes que as utilizavam mas não as declaravam.
   
3. **Padrão de Logs (Recomendação):**
   - Identificada a necessidade de substituir `print()` por um logger estruturado (planejado para próxima etapa).

## Code Review — Principais Observações

### Arquitetura (`Root.dart`)
- **Observação:** O widget `Root` está com excesso de responsabilidade (instanciação de infra + UI + orquestração de sync).
- **Recomendação:** Desacoplar a criação do grafo de dependências para uma Factory ou Dependency Provider.

### Performance (`HomePage.dart`)
- **Observação:** Reconstrução desnecessária de toda a página ao mudar o status do `SyncEngine`.
- **Recomendação:** Utilizar `Selector` ou `Consumer` granular para o `SyncIndicator`.

### Bug Prevention (`OfflineFirstRepository`)
- **Observação:** Chamadas de `prefetchLookupTables` sem controle de estado podem causar múltiplas execuções.
- **Recomendação:** Implementar trava de inicialização ou idempotência no prefetch.

## Artefatos Produzidos

- `packages/core/lib/src/utils/env.dart` — Refatorado para constantes e validação.
- `packages/core/lib/src/utils/acdg_logger.dart` — Novo sistema de log centralizado.
- `apps/acdg_system/lib/main.dart` — Atualizado com check de ambiente e inicialização do logger.
- `packages/core/pubspec.yaml`, `apps/acdg_system/pubspec.yaml`, `bff/social_care_desktop/pubspec.yaml` — Dependências corrigidas.

## Ações de Saneamento Realizadas

1. **Implementação do `AcdgLogger`:**
   - Criado utilitário baseado em `package:logging`.
   - Substituídos `print()` em `hml_auth_helper.dart` e `staging_integration_test.dart`.
   
2. **Limpeza Automática (`dart fix`):**
   - Removidos centenas de imports não utilizados em todo o monorepo.
   - Corrigida a ordenação de diretivas.
   - Adicionadas chaves `{}` em blocos de controle de fluxo para conformidade com o lint.

## Status da Análise Estática
- **Passando (0 issues):** `acdg_system`, `core`, `auth`, `social_care`, `social_care_web`.
- **Pendentes (Warnings de Tipagem/Infra):** `network`, `shared`, `social_care_desktop`.

## Próximos Passos
- Corrigir `inference_failure` no package `network`.
- Refatorar o `Root.dart` para remover lógica de criação de infraestrutura.

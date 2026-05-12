# ADR-009: Provider como Injeção de Dependência

**Data:** 2026-03 (reconstituído a partir de `frontend/CLAUDE.md`)
**Status:** Aceito (reconstituído)
**Relacionado:** [ADR-003](ADR-003-mvvm-logic-layer.md), [ADR-018](ADR-018-root-main-injection.md)

## Contexto

Precisamos de um mecanismo de DI/IoC para Flutter que:

- Seja idiomático do framework (não introduzir conceito alienígena).
- Permita escopo por sub-tree (alguns providers globais, outros por feature).
- Permita testes substituírem dependências facilmente.
- Não imponha service locator global anti-padrão.

## Decisão

Usar **`package:provider`** como mecanismo único de DI.

Repositories e UseCases são expostos na árvore de widgets via `MultiProvider` / `Provider.value`, e consumidos via `context.read()` (não-reativo) ou `context.watch()` (reativo).

## Consequências

- Sem service locator (sem `GetIt`, sem singleton global).
- Testes substituem dependências envolvendo o widget alvo num `Provider` que injeta o Fake.
- Escopo de provider segue a árvore de widgets — features sub-tree podem ter providers próprios.
- Funciona naturalmente com `ChangeNotifier` / `ValueNotifier` ([ADR-015](ADR-015-command-pattern.md)).

## Anti-padrão

- ❌ Service locator global (`GetIt`, `kiwi`).
- ❌ Singletons (`static final instance = ...`).
- ❌ `BuildContext` percorrido manualmente para encontrar dependência.

## Status atual (2026-05-12)

- Padrão aplicado no `bff/social_care_desktop/` para wire-up de Repository / UseCase.
- Phase 6+ (UI Flutter) aplicará o mesmo padrão no Shell + features.

## Superseded by

Nenhum.

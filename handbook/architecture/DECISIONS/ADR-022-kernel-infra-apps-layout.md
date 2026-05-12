# ADR-022: Reorganização do Monorepo — kernel/infra/apps Layout

**Data:** 2026-05-01
**Status:** Aceito
**Relacionado:** D1.C delete (commit `33626f0`), Phase 5 CLI-first kickoff, [MONOREPO_LAYOUT.md](../MONOREPO_LAYOUT.md)

## Contexto

Antes de iniciar a Fase 5 (CLI-first), o usuário pediu reorganização da estrutura monorepo:

- "TUDO sem interação com usuário é um APP" — definição expandida de "aplicação".
- Necessidade de suportar múltiplas apps independentes (CLI, BFF, Flutter UI futura, analytics_bi futuro).
- Cada app deve poder ter sua própria lógica/arquitetura.
- Nomenclatura "shared" considerada genérica demais.

Layout anterior (`packages/ + bff/`) tratava `bff/` como cidadão de segunda classe (não-app) e agrupava todas as libs sob `packages/` sem distinção semântica entre primitives Dart-puros e impl concrete.

## Decisão

Reorganizar o monorepo em três buckets semânticos, mantendo **Dart Workspaces 3.6+ idiomático** (single workspace global por enquanto, preparado para evolução a workspaces independentes per-app):

```text
acdg-frontend/
├── kernel/      — Dart-pure foundation (contracts, lints)
├── infra/       — Flutter-coupled infrastructure (runtime, transport, storage)
└── apps/        — Unidades entregáveis (social_care_bff = web+desktop+contracts; cli; ...)
```

**Mapping** (todos os nomes de packages preservados — só pastas mudam):

- `packages/core_contracts/` → `kernel/contracts/`
- `packages/acdg_lints/` → `kernel/lints/`
- `packages/core/` → `infra/runtime/`
- `packages/network/` → `infra/transport/`
- `packages/persistence/` → `infra/storage/`
- `bff/shared/` → `apps/social_care_bff/contracts/`
- `bff/social_care_web/` → `apps/social_care_bff/web/`
- `bff/social_care_desktop/` → `apps/social_care_bff/desktop/`

## Justificativa

| Critério | `packages/` + `bff/` (anterior) | `kernel/` + `infra/` + `apps/` (atual) |
|---|---|---|
| Semântica de pasta | Genérica ("packages") | Explícita (kernel/infra/apps) |
| BFF status | Pasta especial fora de packages | First-class app em `apps/` |
| Onboarding novo dev | "O que é o quê?" | Auto-explicativo |
| Multi-app readiness | `apps/` não existia | Cada app já em `apps/<x>/` |
| Promoção a Padrão B | Refactor maior | Mecânico (adicionar pubspec.yaml na app) |
| Dart idiomático | Workspace 3.6+ | Workspace 3.6+ (mantido) |

## Decisões secundárias

1. **Names dos packages preservados** — `core_contracts`, `core`, `network`, `persistence`, `acdg_lints`, `shared`, `social_care_web`, `social_care_desktop`. Imports `package:X` continuam idênticos. Renomeação eventual fica como ticket separado pós-CLI estabilizar.

2. **Workspace global mantido por agora** — Padrão B real (workspaces independentes por app) é diferido. Layout já preparado para promoção mecânica quando primeira app divergir em versões.

3. **Phase 3 BFF sagrada preservada** — todos os 2036 testes GREEN intactos pós-migração. Apenas paths em pubspec.yaml mudam; imports e código não.

## Consequências

**Imediatas:**

- 8 entries no workspace raiz (era 13 antes, perdeu 5 com D1.C delete).
- Path deps cruzados atualizados em `infra/runtime/`, `apps/social_care_bff/{contracts,web,desktop}/pubspec.yaml`.
- `dart analyze` zero errors em src/ dos 3 BFFs.
- `flutter test` 2036 GREEN (535 contracts + 1075 web + 426 desktop + 1 skip).
- Doc canônico: [MONOREPO_LAYOUT.md](../MONOREPO_LAYOUT.md).

**Para Phase 5 (CLI-first):**

- CLI nasce em `apps/cli/` no layout novo.
- Path deps pra `kernel/contracts/` e `apps/social_care_bff/contracts/` são naturais (co-located em `apps/`).

**Para futuras apps (Phase 6+):**

- `apps/social_care_ui/`, `apps/analytics_bi/` etc. seguem o mesmo padrão.
- Cada app pode ter sua própria arquitetura interna (MVVM, Clean, BLoC, etc.) sem afetar outras.

**Histórico documental:**

- Docs em `archive/chat/`, `archive/audit/`, `archive/missions/`, `archive/reports/` com paths antigos **NÃO foram atualizados** — preservam histórico imutável.
- Docs vivos ([ARCHITECTURE.md](../ARCHITECTURE.md), etc.) referenciam paths antigos esporadicamente; updates incrementais ocorrerão conforme cada doc é tocado.

## Gatilho de evolução para Padrão B real

Promover uma app específica a workspace independente quando:

- Precisa de Flutter SDK diferente do resto.
- Versão de dep crítica (Riverpod, Bloc, Dio) precisa divergir.
- CI quer pipelines separados (deploy independente).

Procedimento:

1. Adicionar `pubspec.yaml` na app com `workspace: [<members>]`.
2. Remover entries da app do `pubspec.yaml` raiz.
3. App passa a ter próprio `pubspec.lock`.
4. Melos `--scope` continua funcionando.

## Histórico de pesquisa

Decisão fundamentada em (sessão 2026-05-01):

- https://docs.flutter.dev/packages-and-plugins/developing-packages
- https://pub.dev/packages/melos (v7.x — workspaces idiomático)
- https://medium.com/flutter-community/managing-multi-package-flutter-projects-with-melos-c8ce96fa7c82
- https://dart.dev/tools/pub/dependencies (path packages)
- https://dart.dev/tools/pub/workspaces (Dart 3.6+)

## Referência

- Layout doc: [MONOREPO_LAYOUT.md](../MONOREPO_LAYOUT.md).
- Migration commit: `af81393` (`refactor!: reorganize monorepo to kernel/infra/apps (ADR-022)`).
- Session reports: `archive/reports/SESSION_2026_04_29_A16_V2_DESKTOP_REBUILD.md`, `archive/reports/SESSION_2026_04_30_A17_V2_DESKTOP_CACHE.md`.

## Superseded by

Nenhum.

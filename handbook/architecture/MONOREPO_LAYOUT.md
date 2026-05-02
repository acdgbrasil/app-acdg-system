# Monorepo Layout (post-2026-05-01 reorganization)

> **Status:** Canônico desde 2026-05-01. Supersede o layout `packages/ + bff/` anterior.
> **ADR relacionado:** ADR-022 — Reorganização do monorepo (kernel/infra/apps).

## Princípios

1. **Nomes semânticos** — pastas explicam papel arquitetural (não "shared"/"libs" genéricos).
2. **Tudo sem UI é "app"** — qualquer unidade entregável/executável vira `apps/<name>/` (servidor HTTP, lib in-process, CLI, app Flutter).
3. **Dart Workspaces 3.6+ idiomático** — single `pubspec.lock` na raiz, `resolution: workspace` em cada member.
4. **Padrão B-semântico** — layout preparado para futura migração a workspaces independentes por app (cada `apps/<x>/` pode ser promovido a workspace próprio adicionando `pubspec.yaml` com `workspace:` próprio e removendo do root).

## Estrutura

```
acdg-frontend/
├── pubspec.yaml                        # Workspace global + Melos config
│                                       # workspace: lista os 8 packages atuais
│
├── kernel/                             # Dart-pure foundation — primitives sem Flutter SDK dep
│   ├── contracts/                      # name: core_contracts (Result<T>, branded types, base contracts)
│   └── lints/                          # name: acdg_lints (custom lint rules via custom_lint)
│
├── infra/                              # Implementação concreta — Flutter-coupled, choice-of-tech
│   ├── runtime/                        # name: core (AcdgLogger, JWT, Sentry, Command pattern)
│   ├── transport/                      # name: network (Dio wrapper, connectivity_plus)
│   └── storage/                        # name: persistence (Drift + sqlite)
│
└── apps/                               # Unidades entregáveis — cada subdir é uma app autônoma
    └── social_care_bff/                # BFF social_care (Phase 3 sagrada)
        ├── contracts/                  # name: shared (Contract A DTOs + 11 sub-contracts)
        ├── web/                        # name: social_care_web (servidor HTTP shelf, OIDC, proxy)
        └── desktop/                    # name: social_care_desktop (lib in-process com cache + sync)
```

## Mapping antigo → novo

| Antes | Depois | Package name (preservado) |
|-------|--------|--------------------------|
| `packages/core_contracts/` | `kernel/contracts/` | `core_contracts` |
| `packages/acdg_lints/` | `kernel/lints/` | `acdg_lints` |
| `packages/core/` | `infra/runtime/` | `core` |
| `packages/network/` | `infra/transport/` | `network` |
| `packages/persistence/` | `infra/storage/` | `persistence` |
| `bff/shared/` | `apps/social_care_bff/contracts/` | `shared` |
| `bff/social_care_web/` | `apps/social_care_bff/web/` | `social_care_web` |
| `bff/social_care_desktop/` | `apps/social_care_bff/desktop/` | `social_care_desktop` |

**Importante:** os NOMES dos packages estão preservados. Imports `package:core/core.dart`, `package:shared/shared.dart`, etc. continuam idênticos. Mudou apenas a localização das pastas + path deps em `pubspec.yaml`.

## Apps futuras (Padrão B-semântico)

Quando cada nova app for criada, ela vira mais um diretório em `apps/`:

```
apps/
├── social_care_bff/        # presente
├── cli/                    # Phase 5 — CLI Dart puro consumindo BFF Web via HTTP
├── social_care_ui/         # Phase 6 — Flutter UI futura
├── analytics_bi/           # Phase 7+ — dashboards
├── form_conversions/       # futuro
└── queue_manager/          # futuro
```

## Path deps cruzados

### kernel → kernel
Nenhum (kernel são primitives independentes).

### infra → kernel
- `infra/runtime/` consome `kernel/contracts/` via path: `../../kernel/contracts`
- `infra/runtime/` consome `infra/storage/` via path: `../storage`

### apps → kernel + infra + apps internos
- `apps/social_care_bff/contracts/` → `kernel/contracts/` (path: `../../../kernel/contracts`)
- `apps/social_care_bff/web/` → `kernel/contracts/`, `kernel/lints/` (dev), `apps/social_care_bff/contracts/`
- `apps/social_care_bff/desktop/` → `kernel/contracts/`, `infra/runtime/`, `infra/transport/`, `infra/storage/`, `apps/social_care_bff/contracts/`

Cada app consome shared libs apenas via path deps explicitos no pubspec.yaml — nunca importação implícita por workspace.

## Melos scripts (cross-cutting + scope)

```bash
# Tudo
melos run analyze              # dart analyze em todos os packages
melos run test                 # flutter test em packages com Flutter SDK
melos run test:dart            # dart test em packages Dart-only
melos run format               # check formatação
melos run format:fix           # aplica formatação

# Por bucket
melos run analyze:kernel       # só kernel/contracts + kernel/lints
melos run analyze:infra        # só infra/runtime + infra/transport + infra/storage
melos run analyze:bff          # só apps/social_care_bff/*

# Build runner (drift codegen, json_serializable etc.)
melos run build_runner
```

## Promoção a workspace independente (futuro Padrão B)

Quando uma app precisar divergir em versões de deps (ex: Flutter SDK próprio, Riverpod 4 enquanto outra app fica em 3), a promoção é mecânica:

1. Adicionar `pubspec.yaml` raiz na app com `workspace: [<members internos>]`
2. Remover entries da app do `pubspec.yaml` raiz do monorepo
3. Atualizar Melos: `--scope` continua funcionando; bootstrap roda ambos workspaces
4. CI ganha jobs separados por workspace

Sem necessidade de mover pastas. O layout já está preparado.

## Validação pós-migração (2026-05-01)

| Métrica | Antes (packages/+bff/) | Depois (kernel/+infra/+apps/) |
|---------|------------------------|-------------------------------|
| Workspace entries | 13 (incluindo 5 deletados em D1.C) | 8 |
| `dart analyze` errors em src/ | 0 | 0 |
| Tests GREEN | 2036 | 2036 |
| Imports `package:X` quebrados | — | 0 |
| ADR registrado | — | ADR-022 |

## Referência cruzada

- `pubspec.yaml` (raiz) — workspace + Melos config
- `handbook/architecture/DECISIONS.md` ADR-022 — decisão formal
- `.pipeline/phase-5-cli-first/STATE.md` — destino atual (CLI inicia neste layout)

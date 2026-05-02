# Codebase — frontend (Conecta Raros)

> Mapa dos modulos internos, contratos e convencoes de pasta.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Layout `kernel/infra/apps/`. Estado anterior (`packages/+bff/+apps/acdg_system`) preservado em [../reports/](../reports/) e historico de commits.
> **Layout canonico:** [../architecture/MONOREPO_LAYOUT.md](../architecture/MONOREPO_LAYOUT.md).

---

## 1. Mapa de Packages (atual)

### kernel/ — Dart-pure foundation

| Path | Package name | Tipo | Descricao |
|------|--------------|------|-----------|
| `kernel/contracts/` | `core_contracts` | Library | Result<T>, branded types (extension type), base contracts |
| `kernel/lints/` | `acdg_lints` | Library | Custom lint rules via `custom_lint` (no_sealed_class_downcast) |

### infra/ — Flutter-coupled implementacao concreta

| Path | Package name | Tipo | Descricao |
|------|--------------|------|-----------|
| `infra/runtime/` | `core` | Library | AcdgLogger, JWT parsing, Sentry, Command pattern, base classes |
| `infra/transport/` | `network` | Library | Dio wrapper, connectivity_plus |
| `infra/storage/` | `persistence` | Library | Drift + sqlite (offline cache) |

### apps/ — unidades entregaveis

| Path | Package name | Tipo | Descricao |
|------|--------------|------|-----------|
| `apps/social_care_bff/contracts/` | `shared` | Library | DTOs Contract A + 11 sub-contracts + Fakes |
| `apps/social_care_bff/web/` | `social_care_web` | App | Servidor HTTP shelf, OIDC, proxy backend (entrypoint: `bin/server.dart`) |
| `apps/social_care_bff/desktop/` | `social_care_desktop` | App | Lib in-process com cache Drift + sync engine |
| `apps/cli/` | `acdg_cli` | App | **Phase 5** — CLI Dart puro consumindo BFF Web via HTTP |
| `apps/social_care_ui/` | TBD | App | **Phase 6+** (futuro) — UI Flutter |
| `apps/analytics_bi/` | TBD | App | **Phase 7+** (futuro) — dashboards |

---

## 2. Dependencias entre Packages

### kernel deps
- `kernel/contracts` — sem deps internas
- `kernel/lints` — sem deps internas

### infra deps
- `infra/runtime` -> `kernel/contracts`, `infra/storage`
- `infra/transport` — sem deps internas
- `infra/storage` — sem deps internas

### apps deps
- `apps/social_care_bff/contracts` -> `kernel/contracts`
- `apps/social_care_bff/web` -> `kernel/contracts`, `kernel/lints` (dev), `apps/social_care_bff/contracts`
- `apps/social_care_bff/desktop` -> `kernel/contracts`, `infra/runtime`, `infra/transport`, `infra/storage`, `apps/social_care_bff/contracts`
- `apps/cli` (Phase 5) -> `apps/social_care_bff/contracts`, `kernel/contracts`, dio, args, oidc

**Regra:** apps NAO dependem umas das outras. Comunicacao entre apps acontece via:
- BFF Web HTTP (CLI -> BFF web)
- in-process import (futura UI Flutter desktop -> apps/social_care_bff/desktop como facade)

---

## 3. Contracts BFF — Contract A vs Contract B

### Contract A (APP <-> BFF — publico)
DTOs em `apps/social_care_bff/contracts/lib/src/contract/dto/{requests,responses}/`.
35 acoes funcionais distribuidas em **11 sub-contracts**:
- `AuthContract` (5 acoes)
- `RegistryContract` (11 acoes — patient + family + identity + lifecycle)
- `AssessmentContract` (7 fichas)
- `CareContract` (2 acoes)
- `ProtectionContract` (3 acoes)
- `LookupContract` (9 acoes — incluindo batch)
- `TeamContract` (9 acoes)
- `AuditContract` (1 acao)
- `AnalyticsContract` (1 acao — futuro)
- `HealthContract` (2 probes)
- `PeopleContract` (interno — nao exportado)

Spec completa: [../architecture/CONTRACT_A_SPEC.md](../architecture/CONTRACT_A_SPEC.md).

### Contract B (BFF <-> backends Swift/Vapor — interno)
Backend agnostic dos detalhes de upstream. Mesmas 11 abstract interface classes em `apps/social_care_bff/contracts/lib/src/contract/sub_contracts/`. Implementacoes:
- Web: `apps/social_care_bff/web/lib/src/remote/*_remote.dart` (Dio + JWT)
- Desktop: `apps/social_care_bff/desktop/lib/src/remote/*_remote.dart` (Dio direto, Bearer)

---

## 4. Layout interno por app

### apps/social_care_bff/web/
```
lib/
  social_care_web.dart          # barrel
  src/
    config/                     # ServerConfig
    auth/                       # OidcServerClient, SessionStore
    middleware/                 # session, auth_guard, observability, (Phase 5: bearer)
    handlers/                   # auth, registry_patient, registry_family, assessment, care,
                                #   protection, lookup, team, health (1 por sub-contract)
    intents/                    # parseFromBody/parseFromQuery/parseFromPath por endpoint
    use_cases/                  # orquestracao com sub-contracts via Cascade DI
    server/                     # app_router, shelf_server
bin/server.dart                 # entrypoint
test/                           # 1075 GREEN baseline
```

### apps/social_care_bff/desktop/
```
lib/
  social_care_desktop.dart      # barrel + facade `SocialCareDesktop`
  src/
    facade/                     # 7 sub-facades + 42 metodos delegating
    remote/                     # 7 thin remotes implementando sub-contracts via Dio
    cache/                      # 5 cache contracts Aggregate-Root aligned (Drift + FTS5)
    sync/                       # SyncDatabase separado, 27 SyncMutation sealed classes,
                                #   SyncEngine state machine + outbox + retry policy
    use_cases/                  # 42 use cases em 3 patterns canonicos
test/                           # 426 GREEN +1 skip baseline
```

### apps/social_care_bff/contracts/
```
lib/
  shared.dart                   # barrel
  src/
    contract/
      dto/{requests,responses}/   # 35 request DTOs + 34 response DTOs
      sub_contracts/              # 11 abstract interface classes
    domain/                       # VOs, kernel, registry, assessment, care, protection
    services/                     # patient_enrichment_service
    testing/                      # 11 fakes per sub-contract + 6 InMemory stores
    infrastructure/               # PeopleContextClient (interno)
test/                           # 535 GREEN baseline
```

### apps/cli/ (Phase 5 — futuro)
```
bin/acdg.dart                   # entrypoint
lib/
  src/
    cli_runner.dart             # CommandRunner
    commands/                   # auth, patient, family, assessment, care, protection, lookup, team
    formatters/                 # json, table, yaml
    session/                    # PKCE flow + credential store
test/
  commands/                     # unit tests
  golden/                       # ~50 snapshot tests
  _fixtures/                    # BFF response samples
```

---

## 5. Convencoes de Arquivo

### BFF
| Tipo | Sufixo | Exemplo |
|------|--------|---------|
| Handler | `_handler.dart` | `registry_patient_handler.dart` |
| Intent | `_intent.dart` | `register_patient_intent.dart` |
| UseCase | `_use_case.dart` | `register_patient_use_case.dart` |
| Sub-contract | `_contract.dart` | `registry_contract.dart` |
| Remote | `_remote.dart` | `registry_remote.dart` |
| Cache | `_cache.dart` | `patients_cache.dart` |
| Mutation | `_mutation.dart` | `register_patient_mutation.dart` |
| Fake | `fake_*.dart` | `fake_registry_bff.dart` |
| InMemory store | `in_memory_*.dart` | `in_memory_patient_store.dart` |
| Test | `_test.dart` | `register_patient_use_case_test.dart` |

### CLI (Phase 5)
| Tipo | Sufixo | Exemplo |
|------|--------|---------|
| Command | `_command.dart` | `patient_command.dart` |
| Formatter | `_formatter.dart` | `json_formatter.dart` |
| Session | `_session.dart`, `_store.dart` | `credential_store.dart` |

---

## 6. Path deps cruzados (referencia)

```
apps/social_care_bff/web/
├── shared           → ../contracts
├── core_contracts   → ../../../kernel/contracts
└── acdg_lints (dev) → ../../../kernel/lints

apps/social_care_bff/desktop/
├── shared           → ../contracts
├── core_contracts   → ../../../kernel/contracts
├── core             → ../../../infra/runtime
├── network          → ../../../infra/transport
└── persistence      → ../../../infra/storage

apps/social_care_bff/contracts/
└── core_contracts   → ../../../kernel/contracts

infra/runtime/
├── core_contracts   → ../../kernel/contracts
└── persistence      → ../storage
```

Quando criar nova app em `apps/<name>/`:
- Path deps relativos a `../../kernel/X` ou `../../infra/X`
- Reusar names de packages existentes; nunca duplicar

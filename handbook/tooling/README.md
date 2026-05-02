# Tooling — frontend (Conecta Raros)

> Stack tecnologico, bibliotecas core e automacoes.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Stack atual cobre BFF (Dart puro/Flutter coupled) + CLI (Phase 5 — Dart puro). Stack Flutter UI (Provider, GoRouter, ValueNotifier) reservado para Phase 6+ quando UI for ressuscitada.

---

## 1. Stack Tecnologico (atual)

### Backend-for-Frontend (apps/social_care_bff/)
| Camada | Tecnologia | Versao | Motivo |
|--------|-----------|--------|--------|
| **Linguagem** | Dart | 3.11+ | OOP forte, AOT, compartilha types entre web e desktop |
| **HTTP Server (web)** | shelf + shelf_router | ^1.4 | Idiomatico Dart, middleware composavel |
| **HTTP Client (backends)** | Dio | ^5.7 | Interceptors, retry, cancel tokens |
| **Auth Web** | OIDC + JWT | dart_jsonwebtoken ^3.0 | Zitadel issuer, JWKS validation |
| **Storage Desktop** | Drift + sqlite | drift ^2.31 | Offline cache + sync (ADR-021 supersede ADR-005 Isar) |
| **Sync orchestration** | drift + state machine custom | — | Outbox pattern, sync_engine + sync_database arquivo separado |
| **Connectivity** | connectivity_plus | ^7.0 | Online/offline detection no Desktop |
| **UUID** | uuid | ^4.0 | Mutation IDs |
| **Test framework** | test, flutter_test | ^1.24 | Widget test no Desktop, dart test no contracts/web |
| **Mocks** | mocktail | ^1.0 | Mocks tipados (so quando inevitavel) |

### CLI (apps/cli/ — Phase 5)
| Camada | Tecnologia | Versao | Motivo |
|--------|-----------|--------|--------|
| **Linguagem** | Dart | 3.11+ | Sem Flutter SDK dep — `dart run`/`dart compile exe` |
| **Args parsing** | args | ^2.x | Padrao Dart CLI |
| **HTTP Client** | Dio | ^5.7 | Mesmo do BFF, interceptor pra Bearer |
| **OIDC PKCE** | openid_client OU oauth2 + custom | TBD | RFC 8252 Loopback flow |
| **Output color** | ansicolor | ^2.x | Tabelas coloridas |
| **YAML output** | yaml | ^3.x | `--output=yaml` |

### Monorepo orchestration
| Ferramenta | Uso |
|------------|-----|
| **Dart Workspaces** | Single `pubspec.lock` raiz; `resolution: workspace` em cada member (Dart 3.6+) |
| **Melos 7.x** | Scripts cross-cutting com bucket scopes (`analyze:kernel`, `analyze:infra`, `analyze:bff`, `test:bff`) |
| **build_runner** | Codegen drift, json_serializable |
| **custom_lint** | Custom rules via `kernel/lints/` (no_sealed_class_downcast) |

---

## 2. Dependencias chave (referencia)

### kernel/contracts (`core_contracts`)
```yaml
dependencies:
  meta: ^1.11.0
  logging: ^1.2.0
```
Dart-puro. Sem deps de Flutter. **Base do projeto inteiro** — Result<T>, branded types.

### apps/social_care_bff/web (`social_care_web`)
```yaml
dependencies:
  shared: { path: ../contracts }
  core_contracts: { path: ../../../kernel/contracts }
  shelf: ^1.4.2
  shelf_router: ^1.1.4
  logging: ^1.2.0
  dio: ^5.9.2
  http: ^1.4.0
  dart_jsonwebtoken: ^3.0.0
  crypto: ^3.0.6

dev_dependencies:
  custom_lint: ^0.8.1
  acdg_lints: { path: ../../../kernel/lints }
```

### apps/social_care_bff/desktop (`social_care_desktop`)
```yaml
dependencies:
  shared: { path: ../contracts }
  core_contracts: { path: ../../../kernel/contracts }
  network: { path: ../../../infra/transport }
  persistence: { path: ../../../infra/storage }
  core: { path: ../../../infra/runtime }
  flutter: { sdk: flutter }
  dio: ^5.9.2
  drift: ^2.31.0
  sqlite3_flutter_libs: ^0.5.28
  connectivity_plus: ^7.0.0
  uuid: ^4.0.0
```

### apps/cli/ (Phase 5 — projetado)
```yaml
dependencies:
  shared: { path: ../social_care_bff/contracts }
  core_contracts: { path: ../../kernel/contracts }
  args: ^2.x
  dio: ^5.x
  openid_client: ^x.x   # ou oauth2 + custom PKCE
  ansicolor: ^2.x
  yaml: ^3.x
```

---

## 3. Dev Tools

| Ferramenta | Uso |
|------------|-----|
| `dart analyze` | Analise estatica (zero errors em src/ enforce) |
| `dart format` | Formatacao automatica (setExitIfChanged em CI) |
| `dart test` | Testes Dart-only (kernel/, contracts/, web/) |
| `flutter test` | Testes Flutter-coupled (desktop/) |
| `dart compile exe` | Build BFF web (`bin/server.dart`) e CLI binarios |
| `dart pub get` | Resolve workspace global |
| `melos bs` | Bootstrap monorepo |
| `melos run analyze` | Analyze em todos os packages |
| `melos run test:bff` | Testes do BFF (~2036 GREEN baseline) |
| `melos run analyze:kernel` | Analyze so kernel/* |
| `melos run analyze:infra` | Analyze so infra/* |
| `melos run analyze:bff` | Analyze so apps/social_care_bff/* |
| `melos run build_runner` | Codegen Drift + json_serializable |
| `melos run format:fix` | `dart format` em todos |

---

## 4. Lint Rules

### kernel/lints (custom rules)
- `no_sealed_class_downcast` — proibe `as ConcreteSubclass` em sealed classes (forca map/flatMap/combineWith)

### Built-in (pubspec analysis_options)
- `flutter_lints` (em packages Flutter-coupled)
- `lints` (em packages Dart-only)
- Regras adicionais por package conforme necessidade

### Custom enforce (PRs)
- Hooks pre-commit (futuro): rodar `dart format` + analyze parcial

---

## 5. Automacoes

| Automacao | Ferramenta | Descricao |
|-----------|-----------|-----------|
| Monorepo scripts | Melos 7.x | `melos bs`, `melos run analyze`, `melos run test:bff` |
| Code generation | build_runner | Drift schemas, JSON serialization |
| CI lint | GitHub Actions | `dart analyze --fatal-infos` em todo PR |
| CI test | GitHub Actions | `flutter test`/`dart test` em todo PR |
| CI build | GitHub Actions | `apps/social_care_bff/web` Docker image (`social_care_bff_image.yml`) |
| CI release | GitHub Actions | (Phase 5 C11) Multi-OS binarios da CLI |
| Custom lints | custom_lint | `dart run custom_lint` em CI |

### Workflows ativos
- `.github/workflows/ci.yml` — lint + test
- `.github/workflows/social_care_bff_image.yml` — Docker image do BFF Web

### Workflows removidos (D1.C)
- `conecta_web_image.yml` (Flutter Web image build) — **deletado 2026-05-01**, app deletado
- `windows_build_msix.yml` (Windows MSIX) — **deletado 2026-05-01**, app deletado

### Workflows futuros (Phase 5)
- C11 — `cli_release.yml` — multi-OS binarios CLI (macos arm64/x64, linux x64, windows x64)

---

## 6. Tooling reservado para Phase 6+ (Future UI Flutter)

Quando UI Flutter ressuscitar, seguintes ferramentas voltam ao stack:
- **Flutter** 3.x (Web WASM + Desktop nativo)
- **Provider** ^6.x (DI, escopo por rota)
- **GoRouter** ^14.x (deferred loading)
- **ValueNotifier + ChangeNotifier** (state atomico)
- **flutter_secure_storage** (Keychain/DPAPI/libsecret)
- **package:oidc** (Bdaya-Dev — OIDC PKCE Flutter)
- **Atomic Design** (Figma ACDG — referencia visual)

Ate la, tooling fica dormente.

---

## 7. Referencia cruzada

- [../architecture/MONOREPO_LAYOUT.md](../architecture/MONOREPO_LAYOUT.md) — layout canonico
- [../architecture/DECISIONS.md](../architecture/DECISIONS.md) ADR-021, ADR-022
- [../codebase/README.md](../codebase/README.md) — mapa de packages
- [../process/README.md](../process/README.md) — pipeline TDD 4-agent

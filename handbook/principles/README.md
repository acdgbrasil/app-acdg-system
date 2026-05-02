# Principios — frontend (Conecta Raros)

> Diretrizes fundamentais de design, patterns e convencoes de codigo.
> Estes principios sao **inegociaveis** — qualquer desvio deve ser registrado como ADR.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Principios de UI Flutter (MVVM, Atomic Design, Provider) ficam reservados para Phase 6+ (UI futura). Hoje vale o canon de BFF + CLI.

---

## 0. Diretriz Operacional Nuclear

**[HANDBOOK_AS_SOURCE_OF_TRUTH.md](HANDBOOK_AS_SOURCE_OF_TRUTH.md)** — Memoria de agente nao e canonica. Tudo que e fato sobre o projeto vai pro handbook em git, **nao em memoria de LLM**. Auditar e atualizar quando mudancas estruturais ocorrerem.

---

## 1. Principios Cross-cutting (BFF + CLI + futura UI)

### 1.1 Imutabilidade Total
- Todos os models: `final` em todos os campos
- Mudancas via `copyWith()` — nunca mutacao direta
- Listas: `List.unmodifiable()` ou `const []`
- Use Equatable em todos os DTOs (ENCAPSULATION_POLICY H6)

### 1.2 Result<T> end-to-end
- Erros sao valores, nao excecoes
- `try/catch` SOMENTE no adapter boundary (services HTTP, repositorios), com conversao para `Result<T>` antes de retornar
- Combinadores idiomaticos: `map`, `flatMap`, `combineWith` (de `core_contracts/`)
- **NUNCA fazer sealed-class downcast** — `acdg_lints/no_sealed_class_downcast` enforce em CI

### 1.3 Models como Schemas
- Models no Flutter (e CLI) sao **schemas puros** — sem logica de negocio
- Toda validacao, transformacao e regra de dominio vive no **BFF**
- Models tem: campos, `fromJson()`, `toJson()`, `copyWith()`, `==`, `hashCode`

### 1.4 Separation of Concerns
- Cada classe tem UMA responsabilidade
- Dependencias fluem para dentro do dominio (boundary -> domain -> kernel)
- Camadas inferiores nao conhecem camadas superiores

### 1.5 Imports
- Use `import type { X }` ou `import 'package:X' show ...` para narrar intent
- Ordem obrigatoria:
  ```dart
  // 1. Dart SDK
  import 'dart:async';

  // 2. Flutter SDK (quando aplicavel)
  import 'package:flutter/foundation.dart';

  // 3. Packages externos (pub.dev)
  import 'package:dio/dio.dart';

  // 4. Packages internos (monorepo — kernel/infra/apps)
  import 'package:core_contracts/core_contracts.dart';
  import 'package:shared/shared.dart';

  // 5. Imports relativos (mesmo package)
  import '../intents/x_intent.dart';
  ```

---

## 2. Principios BFF (apps/social_care_bff/)

### 2.1 Sub-contracts (11 atual: ADR-022)
`AuthContract`, `RegistryContract`, `AssessmentContract`, `CareContract`, `ProtectionContract`, `LookupContract`, `TeamContract`, `AuditContract`, `AnalyticsContract`, `HealthContract`, `PeopleContract` (interno).

### 2.2 ENCAPSULATION_POLICY (H1-H9)
Ver [../architecture/ENCAPSULATION_POLICY.md](../architecture/ENCAPSULATION_POLICY.md).
H6 = Equatable em DTOs; H7 = composition over inheritance; H8 = SRP; H9 = abstract interface class para tipos cross-layer.

### 2.3 PATTERN_MATCHING_POLICY (P1-P5)
Ver [../architecture/PATTERN_MATCHING_POLICY.md](../architecture/PATTERN_MATCHING_POLICY.md).
P1 = state matrix; P2 = if-case default; P2b = try/catch edge case; P3 = tear-offs; P4 = `Never`; P5 = exhaustive switch.

### 2.4 Cascade DI
Ordem canonica de injecao:
`patient -> family -> assessment -> care -> protection -> lookup -> team -> audit -> auth`

### 2.5 Error code convention
- `INVALID_*` — 400 BFF-local (parse/validation falha)
- `<PREFIX>-<NNN>` — passthrough de BackendErrorResponse upstream

### 2.6 Response wrapping
`StandardResponse<T>` com `meta.timestamp` em todos os success responses.

### 2.7 UUID validation
Toda path-param UUID deve passar por `validateUuidPathParam` (canon A23).

---

## 3. Principios CLI (apps/cli/ — Phase 5)

### 3.1 Output formatters
- `table` (default) — colunas truncadas, cores ANSI
- `json` — `--output=json`
- `yaml` — `--output=yaml`

### 3.2 Auth — D3.C γ híbrido
- BFF aceita ambos: cookie `__Host-session` (browser) e `Authorization: Bearer` (CLI)
- CLI faz OIDC PKCE Loopback (RFC 8252) direto no Zitadel
- Tokens em `~/.config/acdg/credentials` (chmod 600)

### 3.3 Comando estilo `gh`
- `acdg <noun> <verb> [args]` (ex: `acdg patient register`, `acdg lookup get`)
- Sub-comandos por sub-contract BFF
- `--from-yaml=path` para payloads complexos

---

## 4. Convencoes de Codigo (todos os contextos)

### 4.1 Nomenclatura

| Elemento | Convencao | Exemplo |
|----------|-----------|---------|
| Classes | PascalCase | `RegistryHandler`, `RegisterPatientIntent` |
| Variaveis/Metodos | camelCase | `patientId`, `parseFromBody()` |
| Constantes | camelCase com `k` prefix | `kDefaultTimeout` |
| Arquivos | snake_case | `register_patient_intent.dart` |
| Packages | snake_case | `core_contracts`, `social_care_web` |
| Sufixos BFF | Tipo da classe | `*Handler`, `*Intent`, `*UseCase`, `*Contract`, `*Remote`, `*Cache` |
| Sufixos CLI | Tipo da classe | `*Command`, `*Formatter`, `*Session` |

### 4.2 Documentacao
- Classes publicas: documentacao obrigatoria (`///`)
- Metodos privados: documentar se a logica nao for auto-evidente
- UI PT-BR (quando UI existir), Code EN — sem excecao
- Mensagens de error code: structural (PII-safe), nao concatenam variavel

### 4.3 Testes
- Cada Intent/UseCase/Handler tem suite de testes correspondente
- Naming: `<nome_original>_test.dart`
- Estrutura: `group()` + `test()` em ingles
- TDD obrigatorio em pipeline 4-agent (test-writer -> implementer -> reviewer -> quality-checker)
- **REGRA #2 (CLAUDE.md):** No test cheating — verbalizar 4 pontos antes de mexer em teste vermelho

---

## 5. Anti-patterns proibidos

- **God Object** — nenhuma classe com mais de ~200 linhas
- **Magic Strings** — constantes sempre tipadas (use enums ou `const` String)
- **`throw`** fora do adapter boundary (use `Result<T>`)
- **`as` cast sem justificativa** documentada (sealed-class downcast e enforce-banido por lint)
- **Memory de agente como source of truth** — sempre handbook (ver HANDBOOK_AS_SOURCE_OF_TRUTH)

---

## 6. Principios reservados para Phase 6+ (UI Flutter futura)

Estes principios estavam ativos antes de D1.C delete; ficam **dormentes** ate UI Flutter ser ressuscitada:
- MVVM estrito (ViewModel concentra estado, View nao decide)
- Estado atomico via ValueNotifier
- Atomic Design (Page/Template/Cell/Atom)
- Provider para DI
- Adaptive design (3 Pages: Desktop/Web/Mobile)
- GoRouter com deferred loading
- Offline First com Drift (ADR-021)

Ao ressuscitar UI Flutter, revisar estes principios contra estado atual antes de aplicar.

---

## Referencia cruzada

- [HANDBOOK_AS_SOURCE_OF_TRUTH.md](HANDBOOK_AS_SOURCE_OF_TRUTH.md) — diretriz nuclear
- [DECISION_HEURISTICS.md](DECISION_HEURISTICS.md) — heuristicas H1-H6 validadas
- [ARCHITECTURAL_GOLD_STANDARD.md](ARCHITECTURAL_GOLD_STANDARD.md) — gold standard arquitetural
- [../architecture/MONOREPO_LAYOUT.md](../architecture/MONOREPO_LAYOUT.md) — layout canonico
- [../architecture/DECISIONS.md](../architecture/DECISIONS.md) — ADRs
- [../architecture/ENCAPSULATION_POLICY.md](../architecture/ENCAPSULATION_POLICY.md)
- [../architecture/PATTERN_MATCHING_POLICY.md](../architecture/PATTERN_MATCHING_POLICY.md)

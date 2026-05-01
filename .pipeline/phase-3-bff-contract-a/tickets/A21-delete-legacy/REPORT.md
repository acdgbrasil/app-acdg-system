# A21 — Delete Legacy REPORT

## Status: GREEN (BFF-side closed) | DEFERRED (packages/-side → Phase 4)
Closed: 2026-05-01

## Split de escopo

A21 original previa cleanup duplo (BFF + Flutter). Aplicada decisão:
- **BFF-side:** absorvido (parcialmente em A19, complementado neste ticket).
- **packages/social_care/-side e apps/acdg_system/-side:** deferido a Phase 4 (memória `feedback_packages_user_owned` — não modificar packages/ em tickets BFF).

## BFF-side — DELETADO neste ticket

### `bff/shared/lib/src/infrastructure/`
- `patient_translator.dart` — god-class ACL com 16+ delegations (Patient/Assessment/Care/Protection mappers). Zero consumers em código de produção do BFF.
- `mappers/` (folder inteiro):
  - `registry_mapper.dart`
  - `assessment_mapper.dart`
  - `care_mapper.dart`
  - `protection_mapper.dart`
  - `json_helpers.dart`
- Export `'src/infrastructure/patient_translator.dart'` removido de `bff/shared/lib/shared.dart:43`.

### `bff/shared/test/infrastructure/`
- `patient_translator_test.dart` (14 tests deletados — eram self-tests do translator)

### Comentários atualizados (referências mortas a `SocialCareContract`)
- `bff/social_care_web/lib/social_care_web.dart:23-24` — bloco "Legacy handlers remain in-tree but are NOT exported" removido (handlers canônicos A07-A15 substituíram).
- `bff/social_care_web/lib/src/handlers/handler_utils.dart:9-12` — docstring `ContractFactory` reescrita para refletir que retorna sub-contracts (Auth/Registry/Assessment/...) em vez de `SocialCareContract` deletada.
- `bff/shared/lib/shared.dart:38-40` — comentário "Remote Models (legacy — to be replaced by contract DTOs)" atualizado para "consumed only by packages/social_care/ — to be deleted in Phase 4".

## BFF-side — ABSORVIDO em A19 (registrado aqui para fechamento)
- `bff/social_care_web/lib/src/remote/social_care_api_client.dart` (917 LoC, god-class implementando `SocialCareContract` deletada em A05) → DELETADO em A19.
- `bff/social_care_web/test/remote/social_care_api_client_test.dart` → DELETADO em A19.
- `bff/social_care_web/lib/src/handlers/health_handler.dart` → REFATORADO em A19 para depender de `HealthContract` canônico.
- `bff/social_care_web/test/handlers/health_handler_test.dart` → REFATORADO em A19 para usar `FakeHealthBff`.

## DEFERIDO a Phase 4

### `packages/social_care/lib/src/`
- `data/services/http_social_care_client.dart` (643 LoC implementando `SocialCareContract` deletada)
- `data/services/http/` split (8 arquivos: `assessment_http_client.dart`, `care_http_client.dart`, `health_http_client.dart`, `lookup_http_client.dart`, `people_http_client.dart`, `protection_http_client.dart`, `registry_http_client.dart`, `_http_shared.dart`, `http_clients.dart`)
- `data/services/patient_service.dart` (consome `SocialCareContract`)
- `data/repositories/bff_patient_repository.dart` (consome `SocialCareContract`)
- `data/repositories/bff_lookup_repository.dart` (consome `SocialCareContract`)
- `logic/use_case/registry/register_patient_use_case.dart` (consome `PatientTranslator`)

### `packages/social_care/test/`
- `data/services/http_social_care_client_test.dart`
- `ui/family_composition/family_composition_bugs_test.dart`

### `apps/acdg_system/lib/logic/di/`
- `infrastructure_providers.dart` (referência a `SocialCareContract`)
- `app_providers.dart`
- `dependency_builders.dart`
- `social_care_providers.dart`

### `bff/shared/lib/src/infrastructure/dtos/` (deferred)
- `patient_remote.dart` (+ `.g.dart`) — consumido apenas por `packages/social_care/`.
- `patient_overview.dart` (+ `.g.dart`) — idem.
- Test em `bff/shared/test/infrastructure/dtos/patient_remote_test.dart` permanece passando.
- **Phase 4** vai deletar simultaneamente: consumers em `packages/` + DTOs + testes.

## Critérios de aceitação

- [x] `grep -r "SocialCareContract" bff/` → vazio (3 matches restantes só em `packages/` e `apps/` — reservados a Phase 4).
- [x] `grep -r "PatientTranslator" bff/` → vazio.
- [x] `grep -r "HttpSocialCareClient" bff/` → vazio.
- [x] `dart analyze bff/{shared,social_care_web,social_care_desktop}/lib/` → zero errors (2 infos não-bloqueantes em `rg_document.dart`).
- [x] Flutter app não-quebrado: `packages/social_care/` continua quebrado (esperado, não regrediu).

## Test suites pós-A21

| Módulo | Tests antes A19 | Tests após A19 | Tests após A21 | Δ A21 |
|--------|:---------------:|:--------------:|:--------------:|:-----:|
| `bff/shared/` | 549 (com 1 fail pre-existing) | 549 (não alterado por A19) | **535** | -14 (patient_translator_test) |
| `bff/social_care_web/` | 1071 (com 1 fail pre-existing) | 1075 | **1075** | 0 |
| `bff/social_care_desktop/` | 426 +1 skip | 426 +1 skip | **426 +1 skip** | 0 |
| **Total GREEN** | 2046 (+2 fail) | 2050 | **2036** | -14 |

Net story: A19 ganhou +4 GREEN absorvendo as 2 falhas pré-existentes; A21 perdeu -14 GREEN deletando os tests do `PatientTranslator` (esperado).

## Comandos de verificação

```bash
grep -rn "SocialCareContract\b\|PatientTranslator\b\|HttpSocialCareClient\b" bff/  # vazio
grep -rln "SocialCareContract\b\|PatientTranslator\b\|HttpSocialCareClient\b" packages/ apps/  # 12 arquivos (Phase 4 cleanup)

dart analyze bff/shared/lib/ bff/social_care_web/lib/ bff/social_care_desktop/lib/  # 2 infos
```

## Próximo

**Phase 3 BFF Contract A: FECHADA.** STATE.md da fase atualizado para `phase: done`.
**Phase 4 (`.pipeline/phase-4-flutter-migration/`)** destrava com inventário herdado documentado acima.

# A11 Wave 1 REPORT — Implementer (Care: appointment + intake)

## Status: COMPLETED — 57/57 A11 GREEN · 482/482 canon GREEN

- **A11 scope**: `+57` (5 test files)
- **Canon scope** (test/intents + test/use_cases + 5 handler tests canônicos): `+482`
- Zero regressões A07/A08/A09/A10
- `dart analyze` **zero errors** no escopo A11

## Files created (4)

### `lib/src/intents/`
- `register_appointment_intent.dart` — P2 if-case com 1 required field
- `update_intake_info_intent.dart` — P2 if-case com 2 required fields + enumeração dinâmica de missing

### `lib/src/use_cases/`
- `register_appointment_use_case.dart` — retorna `StandardIdResponse`; `completed` carrega `appointmentId` (UUID, não-PII)
- `update_intake_info_use_case.dart` — retorna `StandardResponse<void>`; `received` apenas `{patientId}`

## Files rewritten (1)

- `lib/src/handlers/care_handler.dart` — **DELETE** do legacy A05 (`CareContractFactory` + try/catch sobre fromJson) + **CREATE** novo `CareHandler({required registerAppointment, required updateIntakeInfo})`. Helpers copiados verbatim de `RegistryPatientHandler`.

## Files modified (wiring — 2)

- `lib/src/server/app_router.dart` — novo `required CareContract careContract` + `buildCareHandler(...)` factory + Cascade ordem **patient → family → assessment → care**
- `bin/server.dart` — `FakeCareBff()` injetado em `AppRouter`

## 400 codes pinados

| Route | Condition | Code |
|---|---|---|
| POST `/appointments` | Invalid JSON body | `INVALID_JSON` |
| POST `/appointments` | Missing `professionalId` | `INVALID_APPOINTMENT_BODY` |
| PUT `/intake` | Invalid JSON body | `INVALID_JSON` |
| PUT `/intake` | Missing `ingressTypeId` e/ou `serviceReason` | `INVALID_INTAKE_BODY` |

## Event namespaces

| UseCase | received | completed | failed |
|---|---|---|---|
| RegisterAppointmentUseCase | `care.appointment.register.received` `{patientId}` | `care.appointment.register.completed` `{appointmentId}` | `care.appointment.register.failed` `{errorCode}` |
| UpdateIntakeInfoUseCase | `care.intake.update.received` `{patientId}` | `care.intake.update.completed` (no data) | `care.intake.update.failed` `{errorCode}` |

## Decisões técnicas

1. **P2 if-case manual, NÃO P2b** — Wave 0 pinou (≤2 required, non-PII-dense). Zero `try/catch` sobre `fromJson`, honrando ADR-019.
2. **`_UpdateIntakeInfoParseError` NÃO é `const`** — mensagem dinâmica (`missing.join(', ')`). Já `_RegisterAppointmentParseError` É `const` (literal estática). Ambos `final class with Equatable implements Exception`.
3. **`linkedSocialPrograms` tolerante** — malformed (`'not-a-list'`) degrada para `const <ProgramLinkDraftDto>[]`, mesmo shape de `_parseDiagnoses` em `register_patient_intent.dart`.
4. **UseCase void (Intake)** devolve `StandardResponse<void>(data: null, meta: ResponseMeta(...))` — mesmo wrap de `AdmitPatientUseCase`.
5. **UseCase com id (Appointment)** propaga o `StandardIdResponse` do contract verbatim; `.completed` carrega `value.data.id` como `appointmentId`.
6. **Cascade ordem** `patient → family → assessment → care` preserva matching determinístico e não colide com rotas A07–A10.

## PII invariants (verificados)

- **Parse Failure messages**: não contêm `summary`, `actionPlan`, `originName`, `originContact` ou `serviceReason` — só nomes estruturais de campos missing
- **UseCase breadcrumbs**: apenas `patientId`, `appointmentId`, `errorCode` — testes rodam em happy + failure paths
- **Handler 500 body**: `{code: 'INTERNAL', message: 'Internal server error'}` — jamais `'leak marker'`, `'Exception:'`, `'#0'`
- **Handler 400 body**: ecoa apenas a mensagem estrutural do parser, nunca valor bruto

## Aprendizado — P2 vs P2b (primeira aplicação post-ADR-019)

A11 **validou a decision tree** de `PATTERN_MATCHING_POLICY.md §P2b`. Lições aplicáveis a A12–A15:

- Para **1 required** (Appointment), `if (body case {'field': final String x} when x.isNotEmpty)` cobre tudo em 4 linhas.
- Para **2 required** (Intake), padrão manual com `missing.add(...)` é **inevitável** porque a mensagem precisa enumerar múltiplos campos ausentes — try/catch sobre `fromJson` não entrega isso.
- Reproduzir P2b aqui seria **reprovação automática por ADR-019**. P2 default vence quando o DTO é "raso" (≤9 required, não-densamente-PII).
- Heurística consolidada: **conte os required fields + avalie PII sensitivity**; se falhar qualquer condição do gatilho, use P2.

## Validação executada (Dart MCP Server)

- `dart_format` → 5 arquivos reformatados (cosmético)
- `analyze_files` escopo A11 → **No errors**
- `analyze_files` full lib/ → apenas pré-existentes em `lookup_handler`, `protection_handler`, `health_handler`, `social_care_api_client` (A12-A15 + A21)
- `run_tests` A11 → **57/57 pass**
- `run_tests` canon → **482/482 pass**, zero regressões

## Regras invioláveis — checklist

- [x] Zero `try/catch` sobre `fromJson` em adapter (P2 if-case puro)
- [x] Zero `throw` em domain/use-cases
- [x] Equatable em Intents + `_XxxParseError`
- [x] Code EN / comments EN
- [x] Dart 3+ (switch expression, if-case P2, tuple destructuring)
- [x] Lints Camada 2 compatíveis (analyzer clean)
- [x] PII: breadcrumb data NUNCA carrega `originName`, `originContact`, `serviceReason`, `summary`, `actionPlan`
- [x] A07/A08/A09/A10 intocados — Cascade apenas APPEND

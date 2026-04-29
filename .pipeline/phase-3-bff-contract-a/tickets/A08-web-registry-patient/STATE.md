# Ticket State: A08-web-registry-patient

phase: implementation
agent: TDD
status: A08 COMPLETED 2026-04-17 — Wave 0 RED + Wave 1 GREEN. 133/133 A08 tests passing; canonical pattern preserved; zero `dart analyze` errors in A08 scope.

## Escopo
7 endpoints (POST composto, 2 scatter-gather, 4 lifecycle). Reusa ObservabilityContext + middleware + unreachable do A07.

## Wave 0 — RED
- 7 intent tests (register, list, get, admit, discharge, readmit, withdraw)
- 7 usecase tests (com FakeRegistryBff + FakePeopleBff)
- 1 handler test (7 endpoints)
- 1 pii_mask test (maskCpf, maskName, maskCns)

Total: 16 arquivos `test/`. Todos verificados RED via `dart analyze` (undefined names / shape mismatches).

## Próxima Wave
Wave 1 — implementer: 7 intents + 7 usecases + 1 handler + 1 pii_mask helper em `lib/src/`. Atualizar `app_router.dart` e `server.dart`.

---

# A08 Wave 0 REPORT — Test Writer

## Status: COMPLETED (RED)

## Arquivos criados (16)

### Intents (7) — `bff/social_care_web/test/intents/`
- `register_patient_intent_test.dart` — envelope around `RegisterPatientRequest`, `parseFromBody` with P2 if-case, PII guard on CPF + name in failure messages
- `list_patients_intent_test.dart` — `ListPatientsIntent({search?, status?, cursor?, limit?})`, `parseFromQuery` factory coerces empty strings / invalid limits to null
- `get_patient_intent_test.dart` — `GetPatientIntent({patientId})` — equality only
- `admit_patient_intent_test.dart` — `parseFromBody(patientId, body)` with `reason` + `admittedAt` required
- `discharge_patient_intent_test.dart` — `parseFromBody(patientId, body)` with `reason` required
- `readmit_patient_intent_test.dart` — `parseFromBody(patientId, body)` accepts empty body (notes optional); rejects empty patientId
- `withdraw_patient_intent_test.dart` — `parseFromBody(patientId, body)` with `reason` required

### UseCases (7) — `bff/social_care_web/test/use_cases/`
- `register_patient_use_case_test.dart` — saga de 4 passos: principal → familia (vazio p/ caso solo) → patient_create → family_add. Coverage: happy path, breadcrumbs granulares, PII masking em breadcrumbs, falha people_context propaga Failure, duplicate patient → `BackendError(PATIENT_DUPLICATE)`, spy garante zero `addFamilyMember` quando `registerPatient` falha
- `list_patients_use_case_test.dart` — scatter-gather: empty list, N items, forwards filters (search/status/cursor/limit) via `_SpyRegistry`, breadcrumbs `list.received` / `list.completed {count}` / `list.failed`
- `get_patient_use_case_test.dart` — `get.received {patientId}` / `get.completed` / `get.failed`, PII guard on personal_data
- `admit_patient_use_case_test.dart`, `discharge_patient_use_case_test.dart`, `readmit_patient_use_case_test.dart`, `withdraw_patient_use_case_test.dart` — 1 chamada cada, 5 casos: happy path, received breadcrumb com patientId, completed, failure, failed breadcrumb

### Handler (1) — `bff/social_care_web/test/handlers/`
- `registry_patient_handler_test.dart` — 7 endpoints com `_FailingRegistry` para testar propagação de upstream HTTP status codes (409, 404, 400). Validação inclui:
  - POST /patients (happy, invalid JSON → 400, missing prRelationshipId → 400, duplicate → 409)
  - GET /patients (empty, seeded, query params forwarded)
  - GET /patients/<id> (found → 200, missing → 404)
  - POST /patients/<id>/{admit,discharge,readmit,withdraw} (happy, validation → 400, upstream → 409)
  - State matrix: error body não vaza stack traces nem `Exception:` prose

### PII mask (1) — `bff/social_care_web/test/observability/`
- `pii_mask_test.dart` — spec canonical com tabela exata:
  - `maskCpf('11144477735')` → `'111***35'`
  - `maskName('João Silva')` → `'J***'`
  - `maskCns('123456789012345')` → `'1234***2345'`
  - `null` → `null`, `''` → `'***'`, short input → `'***'`

## Shape contratual para Wave 1

### Arquivos a criar em `lib/src/intents/`

```dart
// register_patient_intent.dart — SUBSTITUI a versão legacy
final class RegisterPatientIntent with Equatable {
  const RegisterPatientIntent({required this.request});
  final RegisterPatientRequest request;
  static Result<RegisterPatientIntent> parseFromBody(Map<String, dynamic> body);
  @override List<Object?> get props => [request];
}

final class ListPatientsIntent with Equatable {
  const ListPatientsIntent({this.search, this.status, this.cursor, this.limit});
  final String? search;
  final String? status;
  final String? cursor;
  final int? limit;
  factory ListPatientsIntent.parseFromQuery(Map<String, String> query);
  @override List<Object?> get props => [search, status, cursor, limit];
}

final class GetPatientIntent with Equatable {
  const GetPatientIntent({required this.patientId});
  final String patientId;
  @override List<Object?> get props => [patientId];
}

final class AdmitPatientIntent with Equatable {
  const AdmitPatientIntent({required this.patientId, required this.request});
  final String patientId;
  final AdmitPatientRequest request;
  static Result<AdmitPatientIntent> parseFromBody(String patientId, Map<String, dynamic> body);
  @override List<Object?> get props => [patientId, request];
}
// idem para Discharge, Readmit, Withdraw
```

### Arquivos a criar em `lib/src/use_cases/`

```dart
final class RegisterPatientUseCase {
  const RegisterPatientUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  });
  Future<Result<StandardIdResponse>> execute(RegisterPatientIntent intent, ObservabilityContext obs);
}

final class ListPatientsUseCase {
  const ListPatientsUseCase({required RegistryContract registry, required PeopleContract people});
  Future<Result<PaginatedList<PatientSummaryResponse>>> execute(ListPatientsIntent intent, ObservabilityContext obs);
}

final class GetPatientUseCase {
  const GetPatientUseCase({required RegistryContract registry, required PeopleContract people});
  Future<Result<StandardResponse<PatientResponse>>> execute(GetPatientIntent intent, ObservabilityContext obs);
}

final class AdmitPatientUseCase {
  const AdmitPatientUseCase({required RegistryContract registry});
  Future<Result<StandardResponse<void>>> execute(AdmitPatientIntent intent, ObservabilityContext obs);
}
// idem Discharge, Readmit, Withdraw (cada um carrega seu próprio request via intent)
```

### Arquivo a criar em `lib/src/handlers/`

```dart
final class RegistryPatientHandler {
  const RegistryPatientHandler({
    required RegisterPatientUseCase register,
    required ListPatientsUseCase list,
    required GetPatientUseCase get,
    required AdmitPatientUseCase admit,
    required DischargePatientUseCase discharge,
    required ReadmitPatientUseCase readmit,
    required WithdrawPatientUseCase withdraw,
  });
  Router get router; // POST /patients, GET /patients, GET /patients/<id>,
                    // POST /patients/<id>/{admit,discharge,readmit,withdraw}
}
```

Response envelope segue padrão do `FakeRegistryBff`: lista em `{"data": [...], "meta": {...}}`; detalhe em `{"data": {...}, "meta": {"timestamp": ...}}`; id em `{"data": {"id": "..."}, "meta": ...}`.

### Arquivo a criar em `lib/src/observability/`

```dart
// pii_mask.dart
String? maskCpf(String? cpf);   // '11144477735' → '111***35'
String? maskName(String? name); // 'João Silva'   → 'J***'
String? maskCns(String? cns);   // '123456789012345' → '1234***2345'
// null passa verbatim; '' / short → '***'
// funções puras, nunca throw
```

## Complexidade RegisterPatientUseCase

### Orquestração esperada (Wave 1)
1. `obs.breadcrumb('registry.patient.register.received', {memberCount})`
2. `obs.breadcrumb('registry.patient.register.people_context.reference_start')`
   - `people.registerPerson(...)` para o principal (usa `intent.request.personalData?.firstName + lastName` e `civilDocuments?.cpf`)
   - resolvedPersonId → overwrite em `request.personId`
3. `obs.breadcrumb('registry.patient.register.people_context.family_start', {count: 0})` — solo no teste atual
4. `obs.breadcrumb('registry.patient.register.social_care.patient_create')`
   - `registry.registerPatient(resolvedRequest)` → on Failure: `obs.breadcrumb('registry.patient.register.failed'); return Failure(error);`
5. `obs.breadcrumb('registry.patient.register.social_care.family_add_start', {count})` — loop (empty no solo test)
6. `obs.breadcrumb('registry.patient.register.completed', {patientId, familyCount: 0})` → `return Success(idResponse);`

### Saga compensation
Não compensar. Se step 4 falha após step 2 (pessoas já registradas em People Context), apenas logar `registry.patient.register.failed` e retornar `Failure`. Spy `_FailingRegistry.addFamilyMemberCallCount` garante que step 5 NÃO é executado — se for, test falha.

### Teste crítico
`'does NOT call addFamilyMember when registerPatient fails (no orphan calls)'` — valida que o early-return após falha de `registerPatient` bloqueia qualquer chamada adicional a `addFamilyMember`. Wave 1 deve implementar isso como **early return switch case** no resultado de `registerPatient`.

## PII mask pattern

Padrão canônico (pinned pelos tests):

| Input            | Masked          | Rationale                                    |
| ---------------- | --------------- | -------------------------------------------- |
| `'11144477735'`  | `'111***35'`    | First 3 + last 2 digits; meaningful prefix   |
| `null`           | `null`          | Verbatim pass-through for conditional spread |
| `''`             | `'***'`         | "Present but redacted" marker                |
| `'123'` (short)  | `'***'`         | Never leak full short input                  |
| `'João Silva'`   | `'J***'`        | Only first character preserved               |
| `'123456789012345'` | `'1234***2345'` | First 4 + last 4; more chars for CNS ID     |

Reutilizar em todos os breadcrumbs que tocam PII — nunca inline `.substring(...)` no call site, sempre através dos 3 helpers.

## Notes for implementer (Wave 1)

### Gotchas confirmados
1. **Legacy files existem**: `lib/src/intents/register_patient_intent.dart` e `lib/src/use_cases/register_patient_use_case.dart` têm código pre-A07 — **substituir completamente** (estão quebrando o análise com os novos testes: sinal verde). Mesmo vale para os handlers antigos em `registry_handler.dart` — delegar para `RegistryPatientHandler` no `app_router.dart`.
2. **Dead-code warnings** em `switch (result) { Success => ... Failure => fail(...) }` aparecem até Wave 1 implementar a classe real. Ignorar — seguem padrão de A07.
3. **`FakeRegistryBff.fetchPatient` retorna `Failure(String)`** quando patient não existe — handler deve traduzir a ausência de `BackendError.http` para **404** no handler (ver teste `returns 404 when patient does not exist`).
4. **`AdmitPatientRequest.admittedAt`** é String ISO (não DateTime).
5. **`RegisterPatientRequest` tem `personId: ''`** permitido — o UseCase resolve para o personId real via PeopleContext antes de enviar ao registry.
6. **`FakeRegistryBff.addFamilyMember` tem parâmetro opcional `cpf`** — Wave 1 UseCase pode passar `cpf` do familiar para enriquecimento idempotente (não testado explicitamente; fica à discrição do implementer).

### Reutilização obrigatória
- Matchers `hasEvent` / `hasEventWithData` via import relativo de `test/use_cases/test_observability.dart` (já existe de A07).
- `ObservabilityContext.noop()` para criar contexto de teste.
- `FakeRegistryBff` (com `store` público), `FakePeopleBff` (com `store` + `inactivePeople`), `InMemoryPatientStore`, `InMemoryPeopleStore` — não criar novos fakes.
- Sub-classes privadas `_FailingRegistry` / `_FailingPeople` em cada test file — pattern feedback_mapper_per_request: cada endpoint tem sua forma específica de falha.

### Políticas aplicadas (Wave 1 deve manter)
- H1–H9 encapsulation: intents `final class`, Equatable, props imutáveis.
- P1 switch state matrix: `return switch (result) { Success(:final value) => ..., Failure(:final error) => ... };`.
- P2 if-case em todo `parseFromBody`/`parseFromQuery`: `if (body case {'reason': final String r, ...} when r.isNotEmpty) { return Success(...); }`.
- P3 tear-offs em `.map(X.fromJson)` — relevante em `RegisterPatientIntent.parseFromBody` para `initialDiagnoses`.
- P4 `unreachable('...', module: 'bff-web/...')` em lugar de `throw StateError`.

### PII canon pinned
- **CPF**, **CNS**, **nome completo**, **NIS**, **RG.number** brutos NUNCA em `obs.breadcrumb(..., data:)`.
- **patientId**, **personId**, **requestId** (UUIDs) ok.
- **birthDate** isolado ok (não é PII suficiente sem outro quasi-id).
- `errorCode` em failure breadcrumbs é obrigatório: `{'errorCode': e is BackendError ? e.code : 'UNKNOWN'}`.


# A08 — Web: Registry (Patient)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A07 ✅ (padrão canônico)

## Escopo

**7 endpoints** de paciente — **maior ticket da Onda 3** por ter endpoint composto:

| # | Método + rota | Complexidade |
|---|--------------|:------------:|
| 1 | `POST /api/patients` | **COMPOSTO** — orquestra PeopleContext + SocialCare (5+ chamadas) |
| 2 | `GET /api/patients?search=&status=&cursor=&limit=` | scatter-gather (enriched) |
| 3 | `GET /api/patients/{id}` | scatter-gather (aggregate) |
| 4 | `POST /api/patients/{id}/admit` | simples |
| 5 | `POST /api/patients/{id}/discharge` | simples |
| 6 | `POST /api/patients/{id}/readmit` | simples |
| 7 | `POST /api/patients/{id}/withdraw` | simples |

## Padrão canônico herdado de A07

**Não reinventa nada.** Reutiliza:
- `ObservabilityContext` (em `lib/src/observability/`)
- `observabilityMiddleware()` (em `lib/src/middleware/observability.dart`)
- `unreachable` do `package:core_contracts`
- `FakeRegistryBff` + `FakePeopleBff` + `InMemoryPatientStore` (de A06/A06b)

## Intents (7)

Todos `final class with Equatable` em `lib/src/intents/`:

1. `RegisterPatientIntent({required PatientRegisterPayload payload})` — envelope do DTO composto
2. `ListPatientsIntent({String? search, String? status, String? cursor, int? limit})`
3. `GetPatientIntent({required String patientId})`
4. `AdmitPatientIntent({required String patientId, required AdmitPatientRequest request})`
5. `DischargePatientIntent({required String patientId, required DischargePatientRequest request})`
6. `ReadmitPatientIntent({required String patientId, required ReadmitPatientRequest request})`
7. `WithdrawPatientIntent({required String patientId, required WithdrawPatientRequest request})`

Factories `parseFromBody(Map)` / `parseFromQuery(Map)` retornando `Result<Intent>` com P2 if-case. **Nunca** ecoar conteúdo sensível no erro (ex: CPF não aparece em mensagem de validação).

## UseCases (7)

Todos `final class` com `_registry` + `_people` privados quando precisar:

### `RegisterPatientUseCase` — composto
```dart
const RegisterPatientUseCase({
  required RegistryContract registry,
  required PeopleContract people,
});

Future<Result<StandardIdResponse>> execute(
  RegisterPatientIntent intent,
  ObservabilityContext obs,
);
```

Orquestração interna (com breadcrumbs granulares):
1. `obs.breadcrumb('registry.patient.register.received')`
2. `obs.breadcrumb('registry.patient.register.people_context.reference_start')`
   - `people.registerPerson(principal)` ou `people.findPersonByCpf(cpf)` se já existe
3. `obs.breadcrumb('registry.patient.register.people_context.family_start {count}')`
   - loop familiares: `people.registerPerson(...)` para cada (se cpf fornecido)
4. `obs.breadcrumb('registry.patient.register.social_care.patient_create')`
   - `registry.registerPatient(resolvedPayload)`
5. `obs.breadcrumb('registry.patient.register.social_care.family_add_start')`
   - loop: `registry.addFamilyMember(...)`
6. `obs.breadcrumb('registry.patient.register.completed {patientId, familyCount}')`

**Saga compensation:** se step 4 falha após steps 1-3, pessoas ficam registradas no PeopleContext sem paciente. Por ora: **não compensar** — log warning e retornar Failure. Ticket futuro pode adicionar cleanup job.

### `ListPatientsUseCase` — scatter-gather
Chama `registry.fetchPatients(...)` → enriquece com `people.batchGetByIds(personIds)` (se existir — senão retorna sem enrichment). Retorna `Result<PaginatedList<PatientSummaryResponse>>`.

### `GetPatientUseCase` — scatter-gather
`registry.fetchPatient(id)` → `people.batchGetByIds(familyPersonIds)` → combina. **Considerar `Isolate.run` (C1)** se aggregate passar de ~50kb.

### `AdmitPatientUseCase`, `DischargePatientUseCase`, `ReadmitPatientUseCase`, `WithdrawPatientUseCase`
Triviais — 1 chamada a `registry.X(patientId, request)`.

## Handler

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

  Router get router => Router()
    ..post('/patients', _handleRegister)
    ..get('/patients', _handleList)
    ..get('/patients/<id>', _handleGet)
    ..post('/patients/<id>/admit', _handleAdmit)
    ..post('/patients/<id>/discharge', _handleDischarge)
    ..post('/patients/<id>/readmit', _handleReadmit)
    ..post('/patients/<id>/withdraw', _handleWithdraw);
}
```

P1 state matrix em cada handler. Factory `buildRegistryPatientHandler(RegistryContract, PeopleContract)` em `app_router.dart`.

## Observability breadcrumb canon (estende A07)

| Endpoint | Received | Success | Failure |
|----------|----------|---------|---------|
| POST /patients | `registry.patient.register.received {memberCount}` | `registry.patient.register.completed {patientId}` + sub-breadcrumbs granulares | `registry.patient.register.failed` |
| GET /patients | `registry.patient.list.received {search, cursor}` | `registry.patient.list.completed {count}` | `registry.patient.list.failed` |
| GET /patients/:id | `registry.patient.get.received {patientId}` | `registry.patient.get.completed` | `registry.patient.get.failed` |
| POST /admit | `registry.patient.admit.received {patientId}` | `registry.patient.admit.completed` | `registry.patient.admit.failed` |
| POST /discharge | `registry.patient.discharge.received` | `registry.patient.discharge.completed` | `registry.patient.discharge.failed` |
| POST /readmit | `registry.patient.readmit.*` | idem | idem |
| POST /withdraw | `registry.patient.withdraw.*` | idem | idem |

## PII obrigatório mascarar

- `cpf`, `cns`, `rg.number`, `nis` brutos **proibidos** em breadcrumbs
- `fullName` **proibido** raw — usar primeira inicial (`J***`)
- `birthDate` em breadcrumbs ok (não é PII suficiente isolado)
- `patientId`, `personId` UUIDs ok

Helper sugerido em `lib/src/observability/pii_mask.dart` — função `maskCpf`, `maskName`, `maskCns`.

## Políticas aplicáveis

- **H1–H9** (encapsulation) — aplicar todas
- **P1** switch state matrix em cada handler
- **P2** if case em parseFromBody/Query de cada Intent
- **P3** tear-offs em `.map(X.fromJson)` no parse de listas
- **P4** `unreachable` em switches inatingíveis
- **C1** `Isolate.run` para parsing de GET /patients/:id se response for grande

## TDD

### Wave 0 — test-writer
- 7 intents tests
- 7 usecase tests (com `FakeRegistryBff` + `FakePeopleBff`)
- 1 handler test com os 7 endpoints
- PII mask test em `observability/pii_mask_test.dart`

### Wave 1 — implementer
- 7 intents + 7 usecases + 1 handler + pii_mask helper
- Update `app_router.dart` com `buildRegistryPatientHandler`
- Update `server.dart` com wiring

## Critérios de aceitação
- [ ] 7 endpoints funcionais com TDD
- [ ] Orquestração composta de POST /patients com breadcrumbs granulares
- [ ] Enrichment de PeopleContext em list/get
- [ ] PII masking via `pii_mask.dart` helper reutilizável
- [ ] Zero `throw` solto (usar `unreachable`)
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze` zero errors no escopo do ticket
- [ ] Padrão canônico de A07 aplicado integralmente

## Não faça
- Não migre outros handlers (A09-A15 cuidam)
- Não implemente saga compensation (futuro)
- Não altere contracts/DTOs/fakes (kernel está estável)

## Status
ready to dispatch Wave 0

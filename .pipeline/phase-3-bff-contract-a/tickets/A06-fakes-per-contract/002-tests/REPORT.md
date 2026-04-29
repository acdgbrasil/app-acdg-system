# A06 Wave 0 REPORT — Test Writer (Fakes)

## Status: COMPLETED (tests RED)

## 11 test files criados
`bff/shared/test/testing/fakes/`:
- `fake_analytics_bff_test.dart`
- `fake_assessment_bff_test.dart`
- `fake_audit_bff_test.dart`
- `fake_auth_bff_test.dart`
- `fake_care_bff_test.dart`
- `fake_health_bff_test.dart`
- `fake_lookup_bff_test.dart`
- `fake_people_bff_test.dart`
- `fake_protection_bff_test.dart`
- `fake_registry_bff_test.dart`
- `fake_team_bff_test.dart`

## Shape esperado de cada Fake (API pública chamada pelos testes)

| Fake | Implementa | Operações testadas |
|------|-----------|---------------------|
| `FakeAnalyticsBff` | AnalyticsContract | `getIndicators(axis)` → Success, `getAxesMetadata()` → Success |
| `FakeAssessmentBff` | AssessmentContract | `updateHousingCondition(id, req)` → Success<void> |
| `FakeAuditBff` | AuditContract | `getAuditTrail(id)` → Success (lista vazia) |
| `FakeAuthBff` | AuthContract | `login()` → Success<String>, `me()` → Success<MeResponse> |
| `FakeCareBff` | CareContract | `registerAppointment(id, req)` → StandardIdResponse |
| `FakeHealthBff` | HealthContract | `checkHealth()`, `checkReady()` → Success<void> |
| `FakeLookupBff` | LookupContract | `createLookupItem + getLookupTable` — state preservado |
| `FakePeopleBff` | PeopleContract | `registerPerson + getPerson` — id preservado |
| `FakeProtectionBff` | ProtectionContract | `reportViolation(id, req)` → StandardIdResponse |
| `FakeRegistryBff` | RegistryContract | `registerPatient + fetchPatients` — paciente retorna no list |
| `FakeTeamBff` | TeamContract | `registerWorker + listTeam` — worker retorna no list |

## Resultado do `dart test`

Todos os 11 falham no load com: `Method not found: 'Fake<X>Bff'` — esperado.

**Bônus (não é culpa dos testes):** `lib/src/testing/fake_social_care_bff.dart` quebrado porque importa `contract/social_care_contract.dart` deletado em A05. Wave 1 precisa deletar este arquivo.

## Notes for implementer (Wave 1) — **CRITICAL**

### 1. `Result` usa `Success`/`Failure` (NÃO `Ok`/`Error`)
O `core_contracts` do projeto define `Result<T>` com `Success<T>` (valor) e `Failure<T>` (erro). Meu prompt inicial mencionou "Ok/Error" por engano — **ignore**. Use `Success(...)` / `Failure(...)`.

### 2. State in-memory
- `Map<String, X>` por id para entidades simples (Person, Patient, Appointment, ...)
- `Map<String, List<X>>` para items indexados por chave (ex: `LookupItem` por tableName)
- `List<X>` para sequências simples (ex: AuditEvent trail)

### 3. Wrappers esperados
- `StandardResponse<T>(data: x, meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()))`
- `StandardIdResponse` é alias para `StandardResponse<IdData>` (onde `IdData` tem `.id`)

### 4. Geração de IDs
Para `create*`: `DateTime.now().microsecondsSinceEpoch.toString()` ou contador incremental interno (`_nextId++`).

### 5. DELETAR `bff/shared/lib/src/testing/fake_social_care_bff.dart`
- Remover o export correspondente em `bff/shared/lib/shared.dart` (linha 149)
- Adicionar 11 novos exports `src/testing/fake_<context>_bff.dart`

### 6. Sem lógica de negócio
Fakes são test doubles. Nenhuma validação, nenhuma regra. Só CRUD básico.

### 7. Bug específico: `RegisterPatientRequest`
Exige `initialDiagnoses` e `prRelationshipId` (não opcionais). Teste do registry usa `DiagnosisDraftDto` mínimo — conferir nos teste para shape correto.

## STATE.md
Atualizado marcando Wave 0 completed.

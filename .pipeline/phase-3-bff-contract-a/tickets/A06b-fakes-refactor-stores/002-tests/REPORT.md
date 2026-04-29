# A06b Wave 0 REPORT — Test Writer (Stores)

## Status: COMPLETED (RED)

## 6 test files criados (41 smoke tests totais)
`bff/shared/test/testing/stores/`:
- `in_memory_patient_store_test.dart` (6 tests)
- `in_memory_people_store_test.dart` (7 tests)
- `in_memory_lookup_store_test.dart` (7 tests)
- `in_memory_team_store_test.dart` (7 tests)
- `in_memory_care_store_test.dart` (7 tests)
- `in_memory_protection_store_test.dart` (7 tests)

## Shape esperado — por Store

### 1. `InMemoryPatientStore`
- **Fields:** `Map<String, PatientResponse> patients`, `Map<String, PatientSummaryResponse> summaries`
- **Methods:** `save(patient, summary)`, `get(id) → PatientResponse?`, `listSummaries()`, `clear()`

### 2. `InMemoryPeopleStore`
- **Fields:** `Map<String, PersonResponse> people`, `Map<String, List<PersonRoleResponse>> rolesByPersonId`
- **Methods:** `register(person)`, `get(id)`, `findByCpf(cpf)`, `assignRole(personId, role)`, `listRoles(personId)`, `deactivateRole(personId, roleId)`, `clear()`

### 3. `InMemoryLookupStore`
- **Fields:** `Map<String, List<LookupItemResponse>> tables`, `List<LookupRequestResponse> requests`
- **Methods:** `addItem(tableName, item)`, `getTable(tableName)`, `toggleItem(tableName, itemId, active)`, `addRequest(request)`, `approveRequest(id)`, `rejectRequest(id)`, `clear()`

### 4. `InMemoryTeamStore`
- **Fields:** `Map<String, TeamMemberResponse> members`, `Map<String, List<PersonRoleResponse>> rolesByMemberId`
- **Methods:** `register(member)`, `get(id)`, `list({role, active, search})`, `deactivate(id)`, `reactivate(id)`, `assignRole(memberId, role)`, `clear()`

### 5. `InMemoryCareStore`
- **Fields:** `Map<String, List<AppointmentResponse>> appointments`, `Map<String, IngressInfoResponse> intakes` — **ambos keyed por patientId**
- **Methods:** `addAppointment(patientId, appointment)`, `setIntake(patientId, intake)`, `listAppointments(patientId)`, `getIntake(patientId)`, `clear()`

### 6. `InMemoryProtectionStore`
- **Fields:** `List<ViolationReportResponse> violations`, `List<ReferralResponse> referrals`, `Map<String, PlacementHistoryResponse> placementByPatient`
- **Methods:** `reportViolation(violation)`, `createReferral(referral)`, `setPlacement(patientId, placement)`, `listViolations()`, `clear()`

## Política aplicada
- **Todos os campos PÚBLICOS** (sem `_`) conforme `ENCAPSULATION_POLICY.md`
- Testes asseguram `store.patients`, `store.tables`, etc. **diretamente**
- Sem getters opacos

## Resultado `dart test`
```
+0 -6: Some tests failed.
Method not found: 'InMemoryPatientStore', 'InMemoryPeopleStore', ...
```
Todos RED (esperado).

## Notes for Wave 1 implementer — **OBRIGATÓRIO LER**

### Regras estruturais
1. **Default no-arg constructor** — tests chamam `InMemoryXStore()` sem args
2. **`same()` reference checks** — tests usam `same()` para `get()`/`getIntake()`. Store deve retornar a **mesma referência** armazenada (sem copiar/rebuildar)
3. **Exportar em `shared.dart`** — tests importam via `package:shared/shared.dart`

### Regras de imutabilidade (DTOs são imutáveis!)
4. **`deactivateRole`** — deve **rebuildar** `PersonRoleResponse` com `active: false` no mesmo índice da lista (test assert `roles.first.active == false` após deactivate em pessoa com 1 role)
5. **`deactivate`/`reactivate` em TeamStore** — deve rebuildar o `TeamMemberResponse` stored com `active` flipped

### Regras de filtro
6. **`list({active: true})` em InMemoryTeamStore** — filtra pela flag `active`. Test registra 1 active + 1 inactive e espera 1 resultado.

### CareStore — shape mismatch com fake atual ⚠️
7. `FakeCareBff` atual guarda `Map<String, RegisterAppointmentRequest> _appointments` por **id**.
   Novo store espera `Map<String, List<AppointmentResponse>> appointments` por **patientId** (com grouping).
   Implementer **deve adaptar o FakeCareBff** para mapear `RegisterAppointmentRequest → AppointmentResponse` e agrupar por patientId.

### Regression guard
8. **25 testes de fakes em A06** (`test/testing/fakes/`) **devem permanecer GREEN** após refatoração.
   Qualquer breakage = bug do fake layer, não dos testes.

## STATE.md
Atualizado marcando Wave 0 completed com instruções para Wave 1.

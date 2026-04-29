# A06b — Fakes Refactor: Extract Stores

## Onda: 2 (sub-ticket) | Profile: bff/shared/testing | Depende de: A06 ✅

## Motivação
A06 criou 11 fakes state-preserving. Alguns guardam state em `_maps` e `_lists` privados, o que viola a política `handbook/architecture/ENCAPSULATION_POLICY.md`:
> Se você está criando `Map<String, X> _thing = {}` dentro de uma classe, pergunte: "isso merece ser uma classe `ThingStore`?"

Aplicar **composition + SRP**: extrair `InMemory*Store` como classes colaboradoras públicas.

## Escopo — Stores a criar

Em `bff/shared/lib/src/testing/stores/` (nova pasta):

| # | Store | Estado armazenado | Usado por |
|---|-------|-------------------|-----------|
| 1 | `InMemoryPatientStore` | `summaries`, `patients`, audit trail | FakeRegistryBff + FakeAuditBff |
| 2 | `InMemoryPeopleStore` | `people` (por id/cpf), `roles` (por personId) | FakePeopleBff + FakeTeamBff |
| 3 | `InMemoryLookupStore` | tables (por tableName), governance requests | FakeLookupBff |
| 4 | `InMemoryTeamStore` | team members, roles per member | FakeTeamBff |
| 5 | `InMemoryCareStore` | appointments, intake info | FakeCareBff |
| 6 | `InMemoryProtectionStore` | violations, referrals, placement history | FakeProtectionBff |

**Fakes que permanecem stateless** (sem store, nenhum `_`):
- `FakeHealthBff` — só retorna `Success(null)`
- `FakeAnalyticsBff` — retorna datasets vazios (sem state)
- `FakeAssessmentBff` — updates atuais são no-op (stateless — se precisar de history, ticket futuro)

**Fakes com configuração** (injeção via construtor, não store):
- `FakeAuthBff` — recebe `MeResponse` opcional via construtor (config, não state mutável)

## Padrão dos stores (conforme ENCAPSULATION_POLICY.md)

```dart
class InMemoryPatientStore {
  InMemoryPatientStore();

  // Estado público — testes inspecionam livremente
  final Map<String, PatientResponse> patients = {};
  final Map<String, PatientSummaryResponse> summaries = {};

  // Operações preservam invariantes
  void save(PatientResponse patient, PatientSummaryResponse summary) {
    patients[patient.patientId] = patient;
    summaries[patient.patientId] = summary;
  }

  PatientResponse? get(String id) => patients[id];
  List<PatientSummaryResponse> listSummaries() => summaries.values.toList();
  void clear() { patients.clear(); summaries.clear(); }
}
```

- **Sem `_`** nos campos (são estado inspecionável)
- **Com métodos** que preservam consistência (save atômico, etc.)
- **Default constructor** + clear() para facilitar reset entre testes

## Padrão do fake refatorado

```dart
class FakeRegistryBff implements RegistryContract {
  FakeRegistryBff({InMemoryPatientStore? store})
      : store = store ?? InMemoryPatientStore();

  final InMemoryPatientStore store;  // sem _ — colaborador explícito

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    store.save(
      PatientResponse(patientId: id, personId: request.personId, /*...*/),
      PatientSummaryResponse(patientId: id, /*...*/),
    );
    return Success(StandardIdResponse(
      data: IdData(id: id),
      meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
    ));
  }
}
```

## TDD (Wave 0 → Wave 1)

### Wave 0 — test-writer
Criar testes diretos dos 6 stores em `bff/shared/test/testing/stores/`:
- `in_memory_patient_store_test.dart` — save/get/listSummaries/clear
- `in_memory_people_store_test.dart`
- `in_memory_lookup_store_test.dart`
- `in_memory_team_store_test.dart`
- `in_memory_care_store_test.dart`
- `in_memory_protection_store_test.dart`

Cada arquivo com 3-5 testes de comportamento (CRUD básico, invariantes).

**Testes devem falhar no início** — stores não existem.

### Wave 1 — implementer
1. Criar 6 `InMemory*Store` em `bff/shared/lib/src/testing/stores/`
2. Refatorar 11 fakes para usar stores (ou permanecer stateless)
3. Exportar stores em `shared.dart`
4. **Todos os 25 testes A06 de fakes devem continuar GREEN** (não-regressão)
5. Novos testes de stores também GREEN
6. `dart analyze bff/shared/lib` zero errors

## Critérios de aceitação
- [ ] 6 stores criados em `stores/`
- [ ] 6 testes smoke de stores GREEN
- [ ] 11 fakes refatorados (7 usam store, 4 stateless/config-only)
- [ ] Zero `_map` ou `_list` em fakes (só `_field` em deps injetadas reais, se houver)
- [ ] 25 testes de A06 continuam GREEN (não-regressão)
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `shared.dart` atualizado com exports dos stores

## Não faça
- NÃO alterar contracts
- NÃO alterar DTOs
- NÃO mexer em BFF Web/Desktop (tickets A07+)
- NÃO alterar testes de A06 (exceto se a refatoração exigir ajuste mínimo nas importações — documentar)

## Status
ready to dispatch Wave 0

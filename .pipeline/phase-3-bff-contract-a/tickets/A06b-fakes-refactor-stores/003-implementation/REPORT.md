# A06b Wave 1 REPORT — Implementer

## Status: COMPLETED (tests GREEN)

## 6 Stores criados
`bff/shared/lib/src/testing/stores/`:
- `in_memory_patient_store.dart` — fields `patients`, `summaries`
- `in_memory_people_store.dart` — fields `people`, `rolesByPersonId`
- `in_memory_lookup_store.dart` — fields `tables`, `requests`
- `in_memory_team_store.dart` — fields `members`, `rolesByMemberId`
- `in_memory_care_store.dart` — fields `appointments` (por patientId), `intakes`
- `in_memory_protection_store.dart` — fields `violations`, `referrals`, `placementByPatient`

## 11 Fakes refatorados
- **Com store (7):** Registry, People, Lookup, Team, Care, Protection, Audit (simplified in-place)
- **Stateless/config-only (4):** Health, Analytics, Assessment, Auth

## Decisões técnicas

### CareStore shape mismatch (resolvido)
`FakeCareBff.registerAppointment` agora constrói `AppointmentResponse` a partir do `RegisterAppointmentRequest` (defaults: date=`DateTime.now().toIso8601String()`, type=`'intake'`, summary/actionPlan=`''` quando null) e agrupa por patientId.

### Imutabilidade em deactivate/reactivate
Stores rebuildam o DTO in-place no mesmo índice (`PersonRoleResponse`, `TeamMemberResponse`, `LookupRequestResponse`). Zero mutação dos originais.
Helpers privados (em stores): `_flipRoleActive`, `_flipMemberActive`, `_flipRequestStatus` — DRY sem ampliar API.

### InMemoryAuditStore não criado
Audit trail é single map sem invariantes cross-collection. Expor `trails` como field público no fake já satisfaz a política. Se audit surface crescer, extrair depois.

### `FakePeopleBff.inactivePeople`
`Set<String>` público no próprio fake (não store), porque `PersonResponse` não tem campo `active` que modele isso. Detalhe de contrato fora do "people + roles" collaborator. Revisitar quando DTO ganhar `active`.

### `FakeAuthBff.currentMe`
Renomeado de `_me` → `currentMe`. Não pôde ser `me` por conflito com método `me()` do contract. `setMe(next)` preservado.

### Reference equality garantida
Todos os `get(id)` / `getIntake(id)` retornam a referência exata armazenada (sem cópia). Satisfaz `same()` matchers.

## shared.dart
Nova seção `// Testing — Stores (A06b)` com 6 exports após fake exports.

## Resultado dos testes
| Suite | Testes |
|-------|:------:|
| Stores (`test/testing/stores/`) | 41 GREEN |
| Fakes A06 (`test/testing/fakes/`) | 25 GREEN (não-regressão) |
| `test/testing/` total | 66 GREEN |
| Full package `dart test` | **377 GREEN** |

## Resultado dart analyze
- `dart analyze lib` → **0 issues**
- `dart analyze` (full package) → **0 issues**

## Exceções `_` justificadas

Legitimas por política (rule 2 — helpers de arquivo):
- `_wrap<T>`, `_wrapId`, `_nextId` em cada fake
- `_flipRoleActive`, `_flipMemberActive`, `_flipRequestStatus` em stores

**Nenhum `_field` de coleção sobrevive.** Todas as coleções estão em `InMemory*Store` (fields públicos) ou inexistentes (4 fakes stateless).

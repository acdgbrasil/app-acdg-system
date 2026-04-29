# A04 REPORT — Sub-Contracts Consolidation

## Status: COMPLETED

## Contexto
Agente delegado timeout com 0 arquivos criados após ~15min (908s, 3 tool uses). Maestro completou manualmente — escopo era trivial (3 interfaces abstract, 23 métodos totais).

## Arquivos criados (3)

1. `bff/shared/lib/src/contract/sub_contracts/auth_contract.dart` — 5 métodos
2. `bff/shared/lib/src/contract/sub_contracts/lookup_contract.dart` — 9 métodos
3. `bff/shared/lib/src/contract/sub_contracts/team_contract.dart` — 9 métodos

## Assinaturas

### `AuthContract`
```dart
Future<Result<String>> login();
Future<Result<StandardResponse<void>>> callback({required String code, required String state});
Future<Result<StandardResponse<void>>> logout();
Future<Result<StandardResponse<void>>> refresh();
Future<Result<StandardResponse<MeResponse>>> me();
```

### `LookupContract`
```dart
// Item queries
Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(String tableName);
Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(List<String> tables);

// Item admin
Future<Result<StandardIdResponse>> createLookupItem(String tableName, CreateLookupItemRequest request);
Future<Result<StandardResponse<void>>> updateLookupItem(String tableName, String itemId, UpdateLookupItemRequest request);
Future<Result<StandardResponse<void>>> toggleLookupItem(String tableName, String itemId, ToggleLookupItemRequest request);

// Governance
Future<Result<StandardResponse<List<LookupRequestResponse>>>> getLookupRequests();
Future<Result<StandardIdResponse>> createLookupRequest(CreateLookupRequestRequest request);
Future<Result<StandardResponse<void>>> approveLookupRequest(String requestId);
Future<Result<StandardResponse<void>>> rejectLookupRequest(String requestId);
```

### `TeamContract`
```dart
Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({String? role, bool? active, String? search});
Future<Result<StandardIdResponse>> registerWorker(RegisterPersonWithLoginRequest request);
Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(String memberId);
Future<Result<StandardResponse<void>>> deactivateWorker(String memberId);
Future<Result<StandardResponse<void>>> reactivateWorker(String memberId);
Future<Result<StandardResponse<void>>> resetPassword(String memberId);
Future<Result<StandardIdResponse>> assignRole(String memberId, AssignRoleRequest request);
Future<Result<StandardResponse<void>>> deactivateRole(String memberId, String roleId);
Future<Result<StandardResponse<void>>> reactivateRole(String memberId, String roleId);
```

## Exports adicionados em `bff/shared/lib/shared.dart`

```dart
// Sub-contracts (A04 — new additions)
export 'src/contract/sub_contracts/auth_contract.dart';
export 'src/contract/sub_contracts/lookup_contract.dart';
export 'src/contract/sub_contracts/team_contract.dart';
```

## Resultado `dart analyze bff/shared/lib`

**`No issues found!`** (zero errors, warnings, infos)

## Decisões

- **TDD não aplicado** — interfaces abstract não têm comportamento; type-check do compilador Dart já garante consistência. TDD volta em A06 (Fakes).
- **`registerWorker` usa `RegisterPersonWithLoginRequest`** — reutiliza DTO existente em `people/` (pessoa com login é o shape correto para profissionais de equipe).
- **`assignRole` usa `AssignRoleRequest`** — reutiliza DTO existente em `people/`.
- **AuthContract pattern** — métodos retornam `Result<StandardResponse<void>>` onde a "ação aconteceu com sucesso" é o valor; session viaja por cookie (HttpOnly), não por payload.
- **Não alterado:** `social_care_contract.dart` (será deletado em A05), `sub_contracts/*` existentes.

## Próximo passo
A05 — deletar `social_care_contract.dart` (god-interface) e ajustar consumidores.

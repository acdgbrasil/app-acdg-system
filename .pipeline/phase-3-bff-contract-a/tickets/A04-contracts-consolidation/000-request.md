# A04 — Sub-Contracts Consolidation (Contract B)

## Onda: 2 | Profile: bff/shared | Depende de: A02 ✅, A03 ✅

## Contexto real (descoberto em 2026-04-17)
`bff/shared/lib/src/contract/sub_contracts/` **já existe** com 8 sub-contracts:
- `analytics_contract.dart` ✅
- `assessment_contract.dart` ✅
- `audit_contract.dart` ✅
- `care_contract.dart` ✅
- `health_contract.dart` ✅
- `people_contract.dart` ✅ (usado internamente pelo BFF para People Context)
- `protection_contract.dart` ✅
- `registry_contract.dart` ✅

## Escopo real
Adicionar os **3 sub-contracts faltantes** do Contract A:

1. `sub_contracts/auth_contract.dart` — 5 métodos (login, callback, logout, refresh, me)
2. `sub_contracts/lookup_contract.dart` — 9 métodos (getLookupTable, getLookupsBatch, createLookupItem, updateLookupItem, toggleLookupItem, getLookupRequests, createLookupRequest, approveLookupRequest, rejectLookupRequest)
3. `sub_contracts/team_contract.dart` — 9 métodos (listTeam, registerWorker, getTeamMember, deactivateWorker, reactivateWorker, resetPassword, assignRole, deactivateRole, reactivateRole)

## Decisão: TDD?

**Sem TDD formal.** Sub-contracts são interfaces puramente abstratas — sem comportamento, sem lógica. Não há o que testar (type-check já é feito pelo compilador Dart).

TDD será aplicado em **A06** (Fakes implementam as interfaces — aí há comportamento).

## Template de referência
- `registry_contract.dart` (mais completo — 11 métodos, boa estrutura, usa DTOs corretamente)
- `assessment_contract.dart` (pattern de PUT endpoints)

## Métodos detalhados (dos REPORTs A02/A03 e SPEC)

### AuthContract
```dart
abstract interface class AuthContract {
  /// Inicia fluxo OIDC — retorna URL de redirect do Zitadel.
  Future<Result<String>> login();

  /// Processa callback OIDC — troca code por tokens, cria session.
  Future<Result<StandardResponse<void>>> callback({
    required String code,
    required String state,
  });

  /// Encerra session.
  Future<Result<StandardResponse<void>>> logout();

  /// Renova access token via refresh token.
  Future<Result<StandardResponse<void>>> refresh();

  /// Retorna dados do usuário logado.
  Future<Result<StandardResponse<MeResponse>>> me();
}
```

### LookupContract
```dart
abstract interface class LookupContract {
  // Item queries
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(String tableName);
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(List<String> tables);

  // Item admin
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  );
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  );
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  );

  // Governance requests
  Future<Result<StandardResponse<List<LookupRequestResponse>>>> getLookupRequests();
  Future<Result<StandardIdResponse>> createLookupRequest(CreateLookupRequestRequest request);
  Future<Result<StandardResponse<void>>> approveLookupRequest(String requestId);
  Future<Result<StandardResponse<void>>> rejectLookupRequest(String requestId);
}
```

### TeamContract
```dart
abstract interface class TeamContract {
  Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({
    String? role,
    bool? active,
    String? search,
  });

  Future<Result<StandardIdResponse>> registerWorker(RegisterPersonWithLoginRequest request);

  Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(String memberId);

  Future<Result<StandardResponse<void>>> deactivateWorker(String memberId);
  Future<Result<StandardResponse<void>>> reactivateWorker(String memberId);
  Future<Result<StandardResponse<void>>> resetPassword(String memberId);

  // Roles
  Future<Result<StandardIdResponse>> assignRole(String memberId, AssignRoleRequest request);
  Future<Result<StandardResponse<void>>> deactivateRole(String memberId, String roleId);
  Future<Result<StandardResponse<void>>> reactivateRole(String memberId, String roleId);
}
```

## Critérios de aceitação
- [ ] 3 arquivos novos em `bff/shared/lib/src/contract/sub_contracts/`
- [ ] Cada interface `abstract interface class` (Dart 3+)
- [ ] Métodos usam DTOs criados em A02 (requests) e A03 (responses)
- [ ] Exports em `bff/shared/lib/shared.dart` (seção `// Contract — Sub-contracts`)
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] **NÃO alterar** `social_care_contract.dart` (vai ser deletado em A05)
- [ ] **NÃO alterar** sub-contracts existentes

## Agente: 1 implementer (sem test-writer necessário)

## Não faça
- TDD formal (interface sem comportamento)
- Alterar DTOs
- Alterar outros sub-contracts
- Mexer em `social_care_contract.dart`

## Status
ready to dispatch

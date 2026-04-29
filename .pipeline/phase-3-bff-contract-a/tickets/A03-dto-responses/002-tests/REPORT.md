# A03 Wave 0 REPORT — Test Writer

## Status: COMPLETED (tests RED)

All 6 test files load-fail with "Undefined name" errors, confirming the DTO classes do not yet exist. Expected RED phase state for TDD.

## Arquivos de teste criados

1. `bff/shared/test/contract/dto/responses/governance/lookup_item_response_test.dart`
2. `bff/shared/test/contract/dto/responses/governance/lookups_batch_response_test.dart`
3. `bff/shared/test/contract/dto/responses/governance/lookup_request_response_test.dart`
4. `bff/shared/test/contract/dto/responses/auth/me_response_test.dart`
5. `bff/shared/test/contract/dto/responses/team/team_member_response_test.dart`
6. `bff/shared/test/contract/dto/responses/team/team_member_detail_response_test.dart`

## Shape dos responses esperados

### `LookupItemResponse` (governance/) — items de `GET /api/lookups/{tableName}`
- `id: String`, `codigo: String`, `descricao: String`

### `LookupsBatchResponse` (governance/) — `GET /api/lookups?tables=a,b,c`
- `tables: Map<String, List<LookupItemResponse>>`

### `LookupRequestResponse` (governance/) — `GET /api/lookup-requests`
- `id, tableName, codigo, descricao: String`
- `justificativa: String?`
- `status: String` (pending/approved/rejected) — manter como String livre
- `createdAt: String` (ISO-8601)
- `requestedBy: String`

### `MeResponse` (auth/) — `GET /api/auth/me`
- `userId: String`, `email: String`, `fullName: String?`, `roles: List<String>`

### `TeamMemberResponse` (team/) — item de `GET /api/team`
- `id, personId, fullName: String`
- `email: String?`, `phone: String?`
- `active: bool`
- `primaryRole: String?`

### `TeamMemberDetailResponse` (team/) — `GET /api/team/{id}`
- `id, personId, fullName: String`
- `email: String?`, `phone: String?`
- `active: bool`
- `roles: List<PersonRoleResponse>` (reutiliza DTO existente em `people/`)
- `createdAt: String` (ISO-8601)

## Resultado do `dart test`

- `responses/governance/` → FAIL (3 suites: Undefined names)
- `responses/auth/` → FAIL (`Undefined name 'MeResponse'`)
- `responses/team/` → FAIL (2 suites: Undefined names)

Exactly the expected RED state.

## Notes for implementer (Wave 1) — **OBRIGATÓRIO LER**

### 1. Paths de DTOs a criar
- `bff/shared/lib/src/contract/dto/responses/governance/lookup_item_response.dart`
- `bff/shared/lib/src/contract/dto/responses/governance/lookups_batch_response.dart`
- `bff/shared/lib/src/contract/dto/responses/governance/lookup_request_response.dart`
- `bff/shared/lib/src/contract/dto/responses/auth/me_response.dart`
- `bff/shared/lib/src/contract/dto/responses/team/team_member_response.dart`
- `bff/shared/lib/src/contract/dto/responses/team/team_member_detail_response.dart`

### 2. Padrão (igual Phase 1)
- `@JsonSerializable()` + `part '*.g.dart'`
- Construtor `const`, campos `final`
- Sem Equatable na maioria (Phase 1 não usa)
- **Exceção:** se o teste de `LookupItemResponse` usa `expect(a, equals(b))` com instâncias, adicionar `with Equatable` + `props` para value-equality
- Rodar `dart run build_runner build --delete-conflicting-outputs` em `bff/shared/`
- Exportar em `bff/shared/lib/shared.dart` (seção "Contract DTOs — Responses")

### 3. Gotchas
- **`LookupsBatchResponse`** (`Map<String, List<X>>`): usar `@JsonSerializable(explicitToJson: true)` para serializar nested items. Se json_serializable reclamar da estrutura `Map<String, List>`, escrever `toJson`/`fromJson` manuais que iteram.
- **`TeamMemberDetailResponse`**: reutiliza `PersonRoleResponse` de `../people/person_role_response.dart`. Precisa `explicitToJson: true`.
- **`LookupRequestResponse.status`**: String livre (sem enum).

### 4. Checklist Wave 1
- [ ] 6 DTO files criados
- [ ] `dart run build_runner build --delete-conflicting-outputs` OK
- [ ] 6 exports em `bff/shared/lib/shared.dart`
- [ ] `dart test bff/shared/test/contract/dto/responses/{governance,auth,team}/` verde
- [ ] `dart analyze bff/shared/lib` zero errors

### 5. Não alterar
- Nenhum DTO existente
- Nenhum teste Phase 1 (`assessment_responses_test.dart`, `registry_responses_test.dart`, etc.)

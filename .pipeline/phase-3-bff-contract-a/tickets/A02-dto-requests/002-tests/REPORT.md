# A02 Wave 0 REPORT — Test Writer

## Status: COMPLETED (tests RED)

All 5 test files are in place and `dart test` confirms each one fails at load-time because the expected DTO classes do not yet exist. This is the intended TDD red state handed to Wave 1 (implementer).

## Arquivos de teste criados

1. `bff/shared/test/contract/dto/requests/registry/admit_patient_request_test.dart`
2. `bff/shared/test/contract/dto/requests/governance/create_lookup_item_request_test.dart`
3. `bff/shared/test/contract/dto/requests/governance/update_lookup_item_request_test.dart`
4. `bff/shared/test/contract/dto/requests/governance/toggle_lookup_item_request_test.dart`
5. `bff/shared/test/contract/dto/requests/governance/create_lookup_request_request_test.dart`

## Shape dos DTOs esperados (inferido dos testes)

### 1. `AdmitPatientRequest` (registry/) — Contract A #9
- `reason: String` (required)
- `admittedAt: String` (required, ISO-8601 com sufixo Z)
- `notes: String?` (optional — espelha discharge/withdraw)

### 2. `CreateLookupItemRequest` (governance/) — Contract A #32
- `codigo: String` (required)
- `descricao: String` (required)

### 3. `UpdateLookupItemRequest` (governance/) — Contract A #33
- `codigo: String?` (optional — update parcial)
- `descricao: String?` (optional — update parcial)

### 4. `ToggleLookupItemRequest` (governance/) — Contract A #34
- `active: bool` (required)

### 5. `CreateLookupRequestRequest` (governance/) — Contract A #36
- `tableName: String` (required)
- `codigo: String` (required)
- `descricao: String` (required)
- `justificativa: String?` (optional)

## Resultado do `dart test` (RED confirmado)

```
$ dart test test/contract/dto/requests/registry/admit_patient_request_test.dart
Failed to load: Undefined name 'AdmitPatientRequest'.

$ dart test test/contract/dto/requests/governance/
Failed to load 4 files: Undefined names (CreateLookupItemRequest,
  UpdateLookupItemRequest, ToggleLookupItemRequest, CreateLookupRequestRequest).
```

## Notes for implementer (Wave 1) — **OBRIGATÓRIO LER**

### 1. Arquivos de DTO a criar
- `bff/shared/lib/src/contract/dto/requests/registry/admit_patient_request.dart`
- `bff/shared/lib/src/contract/dto/requests/governance/create_lookup_item_request.dart`
- `bff/shared/lib/src/contract/dto/requests/governance/update_lookup_item_request.dart`
- `bff/shared/lib/src/contract/dto/requests/governance/toggle_lookup_item_request.dart`
- `bff/shared/lib/src/contract/dto/requests/governance/create_lookup_request_request.dart`

Criar pasta nova `governance/` dentro de `requests/`.

### 2. Padrão (igual Phase 1 — **NÃO usar Equatable!**)
- `@JsonSerializable()` + `part '<file>.g.dart';`
- Construtor `const`
- Campos `final`
- `factory X.fromJson(Map<String, dynamic> json) => _$XFromJson(json);`
- `Map<String, dynamic> toJson() => _$XToJson(this);`
- **Sem Equatable** — Phase 1 não usa. Testes comparam `dto.toJson()` com o Map canônico, não `dto == outro`.

### 3. Template de referência
- `discharge_patient_request.dart` para `AdmitPatientRequest` (mesmo shape + `admittedAt`)
- `assign_primary_caregiver_request.dart` para os governance/

### 4. Barrel export obrigatório
Adicionar 5 linhas em `bff/shared/lib/shared.dart` na seção `// Contract DTOs — Requests`. Sem isso os testes continuam falhando (eles importam via `package:shared/shared.dart`).

### 5. Build runner
`cd bff/shared && dart run build_runner build --delete-conflicting-outputs`.

### 6. Validação final esperada
- `dart test bff/shared/test/contract/dto/requests/registry/admit_patient_request_test.dart` verde (4 testes)
- `dart test bff/shared/test/contract/dto/requests/governance/` verde (17 testes: 3+5+4+5)
- `dart analyze bff/shared/lib` zero erros

### 7. Não alterar
Nenhum DTO existente. Nenhum teste Phase 1 (`registry_requests_test.dart`, `assessment_requests_test.dart`, `care_protection_people_requests_test.dart`).

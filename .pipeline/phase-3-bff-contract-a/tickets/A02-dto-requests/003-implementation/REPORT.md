# A02 Wave 1 REPORT — Implementer

## Status: COMPLETED (tests GREEN)

5 request DTOs implementados seguindo padrão Phase 1: `@JsonSerializable()` + `part '*.g.dart'`, construtor const, campos final, **sem Equatable**. Build runner gerou os `.g.dart`, 20 round-trip tests passam, `dart analyze lib` zero issues.

## Arquivos criados (5 DTOs)

1. `bff/shared/lib/src/contract/dto/requests/registry/admit_patient_request.dart`
2. `bff/shared/lib/src/contract/dto/requests/governance/create_lookup_item_request.dart`
3. `bff/shared/lib/src/contract/dto/requests/governance/update_lookup_item_request.dart`
4. `bff/shared/lib/src/contract/dto/requests/governance/toggle_lookup_item_request.dart`
5. `bff/shared/lib/src/contract/dto/requests/governance/create_lookup_request_request.dart`

Pasta nova `governance/` criada em `contract/dto/requests/`.

## Arquivos gerados (build_runner)

5 `.g.dart` via `json_serializable`.

Build: `5 output, 21 same, 39 no-op`.

## Exports adicionados em `bff/shared/lib/shared.dart`

```dart
export 'src/contract/dto/requests/registry/admit_patient_request.dart';
export 'src/contract/dto/requests/governance/create_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/update_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/toggle_lookup_item_request.dart';
export 'src/contract/dto/requests/governance/create_lookup_request_request.dart';
```

## Resultado dos testes

`dart test test/contract/dto/requests/registry/admit_patient_request_test.dart test/contract/dto/requests/governance/`
→ **`00:00 +20: All tests passed!`**

| DTO | Testes |
|-----|-------:|
| AdmitPatientRequest | 4 |
| CreateLookupItemRequest | 3 |
| UpdateLookupItemRequest | 5 |
| ToggleLookupItemRequest | 4 |
| CreateLookupRequestRequest | 4 |
| **Total** | **20** |

## Resultado do `dart analyze`

`dart analyze lib` → **`No issues found!`** (zero errors, zero warnings).

Reconfirmado após A03 paralelo adicionar exports de response em `shared.dart` — sem conflito.

## Observações

- Campos opcionais (`notes`, `justificativa`, `codigo?`, `descricao?`) mantêm `null` no `toJson()` — comportamento default do `json_serializable`, necessário para round-trip bit-for-bit (`expect(dto.toJson(), equals(json))`).
- Nenhum DTO existente foi tocado.
- Nenhum teste Phase 1 alterado.
- `contract/dto/responses/` intocado (A03 trabalhou lá em paralelo sem conflito).

## Decisões técnicas
- Seguido rigorosamente o padrão Phase 1: @JsonSerializable sem Equatable.
- `ToggleLookupItemRequest` — body explicitamente `{"active": bool}` (contrariando a leitura inicial do SPEC de que seria `—`; ticket A02 explicitava body, segui o ticket).
- Nenhum `explicitToJson: true` foi necessário (todos os campos são primitivos).

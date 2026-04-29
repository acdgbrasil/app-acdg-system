# A13 Wave 0 REPORT — Test Writer (Lookup: 8 endpoints governance)

## Status: RED confirmed — 17 test files created

Maior ticket em volume de endpoints da Onda 3. Analyzer reporta `uri_does_not_exist` + cascade em 17 files. A07–A12 intocados (zero regression).

## Files created (17)

### `test/intents/` (8)
- `get_lookup_table_intent_test.dart` — path-only
- `create_lookup_item_intent_test.dart` — **P2**, 2 required
- `update_lookup_item_intent_test.dart` — **P2-tolerant**, 0 required (1ª no monorepo)
- `toggle_lookup_item_intent_test.dart` — **P2**, 1 required bool
- `get_lookup_requests_intent_test.dart` — empty intent
- `create_lookup_request_intent_test.dart` — **P2**, 3 required + PII justificativa
- `approve_lookup_request_intent_test.dart` — path-only
- `reject_lookup_request_intent_test.dart` — path-only

### `test/use_cases/` (8)
Todos seguem tríade canônica `.received / .completed / .failed`

### `test/handlers/` (1 rewrite)
- `lookup_handler_test.dart` — legacy A05 (`contractFactory` + `SocialCareContract`) substituído por canon A08/A11/A12

## Decisão por Intent

| Intent | Strategy | `_XxxParseError`? | 400 code |
|---|---|---|---|
| GetLookupTable | path-only | — | — |
| CreateLookupItem | **P2** (2 required) | dinâmico | `INVALID_CREATE_LOOKUP_ITEM_BODY` |
| UpdateLookupItem | **P2-tolerant** (0 required) | **NÃO** | ❌ nenhum (total function) |
| ToggleLookupItem | **P2** (1 required bool) | const | `INVALID_TOGGLE_LOOKUP_ITEM_BODY` |
| GetLookupRequests | empty intent | — | — |
| CreateLookupRequest | **P2** (3 required) | dinâmico | `INVALID_CREATE_LOOKUP_REQUEST_BODY` |
| ApproveLookupRequest | path-only | — | — |
| RejectLookupRequest | path-only | — | — |

## Event namespaces (pinados)

| UseCase | Namespace | Return | `.received` | `.completed` |
|---|---|---|---|---|
| GetLookupTable | `lookup.table.get.*` | `List<LookupItemResponse>` | `{tableName}` | `{count}` |
| CreateLookupItem | `lookup.item.create.*` | `StandardIdResponse` | `{tableName}` | `{itemId}` |
| UpdateLookupItem | `lookup.item.update.*` | `StandardResponse<void>` | `{tableName, itemId}` | — |
| ToggleLookupItem | `lookup.item.toggle.*` | `StandardResponse<void>` | `{tableName, itemId, active}` | — |
| GetLookupRequests | `lookup.request.list.*` | `List<LookupRequestResponse>` | — | `{count}` |
| CreateLookupRequest | `lookup.request.create.*` | `StandardIdResponse` | `{tableName}` **ONLY** | `{requestId}` |
| ApproveLookupRequest | `lookup.request.approve.*` | `StandardResponse<void>` | `{requestId}` | — |
| RejectLookupRequest | `lookup.request.reject.*` | `StandardResponse<void>` | `{requestId}` | — |

## 400 codes (4 — **ausência deliberada de UPDATE**)

- `INVALID_JSON` (shared em POST/PUT/PATCH)
- `INVALID_CREATE_LOOKUP_ITEM_BODY`
- `INVALID_TOGGLE_LOOKUP_ITEM_BODY`
- `INVALID_CREATE_LOOKUP_REQUEST_BODY`

**PUT `/lookups/<tableName>/<id>` não tem 400 code de body** porque UpdateLookupItem é P2-tolerant. Apenas `INVALID_JSON` quando body não é Map decodificável.

## PII invariants pinados

- `CreateLookupRequestIntent` parse Failure nunca ecoa `justificativa`/`codigo`/`descricao` (pinned com `'filha de 5 anos tem Williams'`)
- `CreateLookupRequestUseCase.received` carrega **APENAS** `{tableName}` — nunca conteúdo do request
- `GetLookupRequestsUseCase` breadcrumbs nunca ecoam `justificativa` de requests seeded
- Handler 400 body POST /lookup-requests com justificativa rica NUNCA surface rationale
- Handler 500 (via `_ExplodingLookup`) sanitiza — sem `'leak marker'`, `'Exception:'`, `'#0'`

## Aprendizados novos

### 1. P2-tolerant é variante natural de P2, não padrão novo

Quando DTO tem **0 required**, parser vira função **total** (`Result<T>` sempre `Success`). Sinais canônicos Wave 1:
- **NÃO** declarar `_XxxParseError` class
- **NÃO** ter `INVALID_*_BODY` code no handler
- `parseFromBody` signature idêntica P2 puro, mas corpo sem `return Failure`

### 2. PII test pattern escala com required count

- **1 required** (Toggle, const msg): `expect(error.toString(), equals('...'))` — equality estrita
- **2+ required** (Create*, dynamic msg): `expect(error.toString(), isNot(contains('PII_MARKER')))` — permite enumeração dinâmica sem breach

### 3. `.received` é o PII firewall

`CreateLookupRequestUseCase` é o exemplo mais tight: intent carrega 4 fields (3 required + opcional narrativa), mas `.received` expõe **somente** `tableName` (domain metadata). Wave 1 deve resistir à tentação de logar `codigo`/`descricao` "para debug" — eles vão para trilha de auditoria do BFF, não para observabilidade runtime.

## Públicas API para Wave 1 (assinaturas pinadas)

Ver tabelas acima. Handler:

```dart
final class LookupHandler {
  const LookupHandler({
    required GetLookupTableUseCase getLookupTable,
    required CreateLookupItemUseCase createLookupItem,
    required UpdateLookupItemUseCase updateLookupItem,
    required ToggleLookupItemUseCase toggleLookupItem,
    required GetLookupRequestsUseCase getLookupRequests,
    required CreateLookupRequestUseCase createLookupRequest,
    required ApproveLookupRequestUseCase approveLookupRequest,
    required RejectLookupRequestUseCase rejectLookupRequest,
  });
  Router get router;
}
```

Rotas:
```
GET    /lookups/<tableName>
POST   /lookups/<tableName>
PUT    /lookups/<tableName>/<id>
PATCH  /lookups/<tableName>/<id>/toggle
GET    /lookup-requests
POST   /lookup-requests
PUT    /lookup-requests/<id>/approve
PUT    /lookup-requests/<id>/reject
```

## Legacy cleanup para Wave 1

- DELETE `lib/src/handlers/lookup_handler.dart` (A05)
- REWRITE com nova assinatura
- Update `app_router.dart`: `buildLookupHandler` + Cascade append após protection
- Update `bin/server.dart`: inject `FakeLookupBff()`

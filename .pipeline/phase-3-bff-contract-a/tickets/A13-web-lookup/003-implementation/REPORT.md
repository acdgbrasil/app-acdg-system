# A13 Wave 1 REPORT — Implementer (Lookup: 8 endpoints governance)

## Status: COMPLETED — 147/147 A13 GREEN · 638/638 canon GREEN · zero regression

Maior ticket em volume da Onda 3. Package total: 816 tests. -2 legacy pré-existentes (`health_handler_test`, `social_care_api_client_test` — A14/A15 herdados).

## Files created (16)

### `lib/src/intents/` (8)
- `get_lookup_table_intent.dart` — path-only
- `create_lookup_item_intent.dart` — P2 (2 required), dynamic `_CreateLookupItemParseError`
- `update_lookup_item_intent.dart` — **P2-tolerant (0 required), SEM ParseError class**
- `toggle_lookup_item_intent.dart` — P2 (1 required bool), **const** `_ToggleLookupItemParseError`
- `get_lookup_requests_intent.dart` — empty intent (`props == const []`)
- `create_lookup_request_intent.dart` — P2 (3 required), dynamic `_CreateLookupRequestParseError`
- `approve_lookup_request_intent.dart` — path-only
- `reject_lookup_request_intent.dart` — path-only

### `lib/src/use_cases/` (8)
Tríade `.received / .completed / .failed` em todos.

| UseCase | `.received` | `.completed` |
|---|---|---|
| GetLookupTable | `{tableName}` | `{count}` |
| CreateLookupItem | `{tableName}` | `{itemId}` |
| UpdateLookupItem (rewrap) | `{tableName, itemId}` | (none) |
| ToggleLookupItem (rewrap) | `{tableName, itemId, active}` | (none) |
| GetLookupRequests | (none) | `{count}` |
| CreateLookupRequest | `{tableName}` **ONLY** | `{requestId}` |
| ApproveLookupRequest (rewrap) | `{requestId}` | (none) |
| RejectLookupRequest (rewrap) | `{requestId}` | (none) |

## Files modified (3)

- `handlers/lookup_handler.dart` — **REWRITE**. Legacy A05 (`LookupContractFactory` + `SocialCareContract`) deletado. Novo 8-route handler com helpers verbatim de A08/A12.
- `server/app_router.dart` — `required LookupContract lookupContract` + `_lookupContract` field + `buildLookupHandler(...)` factory + Cascade append (ordem: patient → family → assessment → care → protection → **lookup**)
- `bin/server.dart` — `FakeLookupBff()` injetado

## Decisões técnicas chave

### 1. P2-tolerant no handler: `throw StateError` documenta invariante in-place

Para `UpdateLookupItem` (parse total), handler mantém switch exaustivo com `throw StateError('UpdateLookupItemIntent.parseFromBody is total')` no branch `Failure()`. Trade-offs:
- ✅ Preserva forma canônica `Success / Failure`
- ✅ Documenta invariante no ponto de uso (não em comentário desconectado)
- ✅ Falha ruidosamente se alguém quebrar o parser (turning silent bug into loud one)
- ✅ Evita introduzir `INVALID_UPDATE_LOOKUP_ITEM_BODY` (absence deliberada)

Esse é o padrão recomendado para futuros Intents P2-tolerant.

### 2. `CreateLookupRequestIntent` — único "create sem patientId" da Onda 3

Rota flat `POST /lookup-requests`, sem path param obrigatório. `parseFromBody` recebe só `body: Map<String, dynamic>`. PII canon rigoroso: `.received` expõe **somente** `request.tableName`, nunca `codigo/descricao/justificativa`.

Confirma que rotas de **recursos de domínio** (lookup tables) divergem do molde patient-centric — precedente útil para A14 (team — pode ter `POST /team/members` sem patient).

### 3. Wiring pattern **reusável para A14 e A15**

```dart
// Pattern replicável:
// 1. Constructor field
required LookupContract lookupContract,
// 2. Private store
final LookupContract _lookupContract;
// 3. Factory at EOF
LookupHandler buildLookupHandler({required LookupContract lookup}) { ... }
// 4. Cascade append
.add(buildLookupHandler(lookup: _lookupContract).router.call)
```

Zero variação entre A12 (Protection) e A13 (Lookup). A14 (Team) seguirá igual.

### 4. Toggle ParseError `const`, CreateItem/Request `dynamic`

Canon consolidado:
- **1 required** → mensagem fixa → `const` ParseError (ex: Toggle `'...missing or invalid [active]'`)
- **2+ required** → mensagem com `missing.join(', ')` → non-const ParseError
- **0 required** (P2-tolerant) → **SEM** ParseError class

### 5. Helpers copiados verbatim (consolidação queued pós-A21)

4º handler usando `_jsonHeaders`, `_readJsonBody`, `_respondWithId`, `_wrapVoidResult`, `_errorResponse`, `_extractError`, `_badRequest`. Extração para `handler_helpers.dart` já era item do débito técnico — agora mais justificado com o 4º uso.

## Aprendizados novos

1. **P2-tolerant no handler** = switch exaustivo + `StateError` defensivo no branch impossível. Documenta invariante no ponto de uso.
2. **Rotas de domain resources** (`/lookup-requests` flat) divergem do molde patient-centric — confirma precedente para A14/A15.
3. **Wiring factory+field+Cascade** é padrão reusável de zero cost — A14/A15 aplicam direto.

## Regras invioláveis — 100% compliance

- [x] Zero `try/catch` sobre fromJson (nenhum P2b)
- [x] Zero `_UpdateLookupItemParseError` class (P2-tolerant dispensa)
- [x] Zero `INVALID_UPDATE_LOOKUP_ITEM_BODY` no handler
- [x] Equatable em Intents + ParseErrors aplicáveis
- [x] PII: `.received` nunca carrega `codigo/descricao/justificativa`
- [x] Lints Camada 2 clean
- [x] Dart 3+ (switch expressions, if-case)
- [x] A07–A12 intocados

## Legacy pré-existente (-2 failures herdados)

- `test/handlers/health_handler_test.dart` — legacy A05, A14 resolve
- `test/remote/social_care_api_client_test.dart` — legacy A05, A21 resolve

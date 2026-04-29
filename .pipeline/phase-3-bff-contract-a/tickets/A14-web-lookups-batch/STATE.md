# Ticket State: A14-web-lookups-batch

## Current Phase
phase: done
agent: implementer (Wave 1 GREEN)
status: completed — 26 new tests GREEN; 844 total passing

## Completed Phases
- [x] 000-request — endpoint composto `GET /lookups?tables=a,b,c`
- [x] 002-tests — Wave 0 RED (3 test files; 26 tests; query-only canon)
- [x] 003-implementation — Wave 1 GREEN (Intent + UseCase + Handler route + wiring)

## Resultado
- **1 Intent**: `GetLookupsBatchIntent` — first "query-only" intent in BFF Web canon
  - `parseFromQuery(Map<String, String>)` mirrors `parseFromBody` shape
  - Tolerant CSV: split → trim → filter (matches `people-context/env.ts:31-34`)
  - Hard cap 20 tables (~54% headroom over 13 in `AllowedLookupTables.swift`)
  - Private const `_GetLookupsBatchParseError` (PII-safe; no input echo)
- **1 UseCase**: `GetLookupsBatchUseCase` — canonical breadcrumb triad
  - `lookup.batch.get.received` → `{tableCount}`
  - `lookup.batch.get.completed` → `{totalItems}`
  - `lookup.batch.get.failed` → `{errorCode}`
- **1 route added**: `GET /lookups` (registered before `/lookups/<tableName>`
  to short-circuit any ambiguity in shelf_router)
- **1 dartdoc rewrite**: `LookupHandler` block now lists query-only as a
  documented parse strategy + the BFF Web error-code convention
  (`INVALID_*` for local 400s, BackendError passthrough for upstream)
- **1 wiring update**: `buildLookupHandler` in `app_router.dart`

## Invariantes arquiteturais novas
- **Query-only parse strategy** — variante natural de path-only para
  endpoints cujos parâmetros vivem em query string. Padrão:
  `parseFromQuery(Map<String, String> queryParameters)`.
- **Error-code convention pinada no dartdoc**: `INVALID_*` (BFF-local
  parse 400) e `<PREFIX>-<NNN>` (upstream backend) são namespaces
  separados que nunca colidem (parse failures short-circuitam antes
  do contract dispatch).
- **Tolerant CSV parsing** estabelecido como padrão project-wide
  (alinhado com `people-context/src/config/env.ts:31-34`).

## Aprendizados para A15 / próximos
1. Query-only é canon agora — pode ser reutilizado em outros endpoints
   compostos (ex: `GET /patients?ids=...` se aparecer).
2. Tabela de cap (20) deriva do AllowedLookupTables real do backend —
   sempre derivar limites de fontes existentes, não chutar.
3. BFF e backend têm catálogos de codes separados por design — quando
   surgir nova convenção, registrar o "porquê não unificar" no dartdoc.

## Débito técnico
- 2 legacy tests pré-existentes (`health_handler_test` +
  `social_care_api_client_test`) ainda falhando — A21 resolve junto
  com a deleção do código legado.
- `FakeLookupBff()` em `bin/server.dart` até adapter HTTP real (A21).

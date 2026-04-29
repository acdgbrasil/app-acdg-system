# A06c Wave 1 REPORT — Implementer (Equatable)

## Status: COMPLETED (tests GREEN)

## Resultados
- `dart test test/contract/dto/equality/` → **102 GREEN** (101 flipped + 1 preserved)
- `dart test` (full bff/shared) → **479 GREEN** (378 pré + 101 novos flips), zero regressões
- `dart analyze lib` → **zero issues**

## Estatísticas
- **52 DTO files** modificados
- **71 classes** ganharam Equatable (arquivos co-localizam agregador + nested)
- 27 request files (43 classes), 21 response files (28 classes), 4 shared wrappers (7 classes)
- `LookupItemResponse` já tinha Equatable via A03 — intacto

## Decisões técnicas

### Nested-first via co-localização
Nested DTOs (`DiagnosisDraftDto`, `RgDocumentDraftDto`, `CnsDraftDto`) vivem no mesmo arquivo do agregador — edição single-pass garante transitividade sem round-trips.

### build_runner desnecessário
Mudança é aditiva (mixin + getter `props`), não afeta `*.g.dart`.

### Handwritten preservado
`LookupsBatchResponse` com `fromJson`/`toJson` manual não foi alterado — apenas mixin + props.

## Caveats documentados (inline via doc-comment)

1. **`StandardResponse<T>` / `PaginatedList<T>`** — transitividade só com `T` Equatable (ou primitivo). Reference type sem Equatable cai em reference equality.
2. **`BackendError.context` / `safeContext`** e **`AuditTrailEntryResponse.payload`** — `Map<String, dynamic>?`. Equatable compara estrutura mas não desce por `dynamic`. Incluídos em `props` mesmo assim.
3. **`BackendError.cause`** — recursivo (`BackendError? cause`). Equatable resolve via chamada recursiva de `==`.

## Arquivos modificados (52)

**Requests (27):**
- assessment/ (7), care/ (2), governance/ (4), people/ (3), protection/ (3), registry/ (8)

**Responses (21):**
- analytics/ (3), assessment/ (8), audit/ (1), auth/ (1), care/ (2), governance/ (2 — excluindo LookupItemResponse), people/ (2), protection/ (3), registry/ (10), team/ (2)

**Shared (4):** backend_error, paginated_list, pagination_meta, standard_response

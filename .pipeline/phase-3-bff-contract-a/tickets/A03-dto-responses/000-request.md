# A03 — DTOs Response (respostas Contract A)

## Onda: 2 | Profile: bff/shared | Depende de: A01 (paralelo com A02)

## Contexto real (descoberto em 2026-04-17)
`bff/shared/lib/src/contract/dto/responses/` **já existe** com 28 responses organizados por bounded context:
- `analytics/` (3) ✅
- `assessment/` (7 fichas + social_benefit) ✅
- `audit/` (audit_trail_entry) ✅
- `care/` (appointment, ingress_info) ✅
- `people/` (person, person_role) ✅
- `protection/` (placement_history, referral, violation_report) ✅
- `registry/` (9 responses incluindo patient, patient_summary, civil_docs, personal_data, etc.) ✅

**Path adotado:** `bff/shared/lib/src/contract/dto/responses/`.

## Escopo real
Responses faltantes identificados:

1. `governance/lookup_item_response.dart` (**nova pasta `governance/`**) — hoje `LookupItem` é modelo de domínio, mas falta o response DTO
2. `governance/lookups_batch_response.dart` — **NOVO composto** (`GET /api/lookups?tables=...`). Estrutura: `Map<String, List<LookupItemResponse>> tables`
3. `governance/lookup_request_response.dart` — para GET /api/lookup-requests
4. `auth/me_response.dart` (**nova pasta `auth/`**) — dados do usuário logado (nome, email, roles)
5. `team/team_member_response.dart` (**nova pasta `team/`**) — response enriched do profissional (person + roles + status)
6. `team/team_member_detail_response.dart` — response do detalhe (aggregate completo)

**Observações:**
- `LookupItem` já existe como **domain model** em `domain/models/lookup.dart`. Mantém. Criamos `LookupItemResponse` como DTO separado (com fromJson/toJson) — igual ao padrão dos outros responses.
- Shared envelopes (`StandardResponse`, `StandardIdResponse`, `PaginatedList`, `PaginationMeta`, `BackendError`) — **já existem** em `contract/dto/shared/`. Reutilizar.

## TDD — agentes diferentes por wave

### Wave 0 — test-writer
- Round-trip tests em `bff/shared/test/contract/dto/responses/` para cada novo response.
- 6 arquivos de teste.
- Testes devem falhar no início.

### Wave 1 — implementer
- Lê os 6 testes.
- Cria os 6 DTOs em `contract/dto/responses/`.
- `@JsonSerializable` + `part '*.g.dart'`.
- Roda `dart run build_runner build`.
- Faz testes passarem.
- `dart analyze bff/shared/lib` zero errors.

## Critérios de aceitação
- [ ] 6 arquivos novos de DTO em `contract/dto/responses/`
- [ ] 6 arquivos de teste de round-trip (todos passando)
- [ ] Pastas `governance/`, `auth/`, `team/` criadas dentro de `responses/`
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `dart test bff/shared/test/contract/dto/responses/` verde nos novos testes

## Não faça
- NÃO mova os 28 DTOs existentes.
- NÃO mexa em `dto/requests/` (isso é A02).
- NÃO consertes os 93 testes deprecados da phase-2.

## Status
ready to dispatch

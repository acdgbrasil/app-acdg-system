# A02 — DTOs Request (payloads Contract A)

## Onda: 2 | Profile: bff/shared | Depende de: A01

## Contexto real (descoberto em 2026-04-17)
`bff/shared/lib/src/contract/dto/requests/` **já existe** com 22 payloads organizados por bounded context:
- `assessment/` (7 fichas) ✅
- `care/` (register_appointment, register_intake_info) ✅
- `people/` (register_person, register_person_with_login, assign_role) ✅
- `protection/` (create_referral, report_rights_violation, update_placement_history) ✅
- `registry/` (add_family_member, assign_primary_caregiver, discharge_patient, readmit_patient, register_patient, update_social_identity, withdraw_patient) ✅

**Path adotado:** `bff/shared/lib/src/contract/dto/requests/` (já existente, bem estruturado — não mover).

## Escopo real
Apenas 5 payloads faltam:

1. `registry/admit_patient_request.dart` — atualmente só há discharge/readmit/withdraw; falta admit
2. `governance/create_lookup_item_request.dart` (**nova pasta `governance/`**)
3. `governance/update_lookup_item_request.dart`
4. `governance/toggle_lookup_item_request.dart`
5. `governance/create_lookup_request_request.dart` (renomear se ficar confuso — "request for lookup governance request")

**Observações:**
- Auth (login, callback, logout, refresh, me) — **sem body** nos endpoints, não precisa DTO request.
- Team (register_worker, assign_role) — **já cobertos** por `people/register_person_with_login_request.dart` + `people/assign_role_request.dart`. Reutilizar.
- Batch lookups (`GET /api/lookups?tables=...`) — **query parameter**, não body. Não precisa classe.

## TDD — agentes diferentes por wave

### Wave 0 — test-writer
- Cria round-trip tests (JSON → DTO → JSON == original) em `bff/shared/test/contract/dto/requests/` para cada novo payload.
- 1 arquivo de teste por arquivo de DTO (5 arquivos de teste).
- Testes **devem falhar** no início (classes ainda não existem).
- Produz `002-tests/REPORT.md` listando os arquivos de teste criados.

### Wave 1 — implementer
- Lê os testes de Wave 0.
- Cria os 5 DTOs em `contract/dto/requests/`.
- Usa `@JsonSerializable` com `part '*.g.dart'` (consistência com Phase 1).
- Roda `dart run build_runner build` para gerar `.g.dart`.
- Faz os testes passarem (GREEN).
- `dart analyze bff/shared/` zero errors em `lib/`.
- Produz `003-implementation/REPORT.md`.

## Critérios de aceitação
- [ ] 5 arquivos novos de DTO em `contract/dto/requests/`
- [ ] 5 arquivos de teste de round-trip (todos passando)
- [ ] Pasta `governance/` criada dentro de `requests/`
- [ ] `dart analyze bff/shared/lib` zero errors
- [ ] `dart test bff/shared/test/contract/dto/requests/governance/` verde

## Não faça
- NÃO mova os 22 DTOs existentes — estrutura atual está boa.
- NÃO mexa em `dto/responses/` (isso é A03).
- NÃO consertes os 93 testes deprecados da phase-2.

## Status
ready to dispatch

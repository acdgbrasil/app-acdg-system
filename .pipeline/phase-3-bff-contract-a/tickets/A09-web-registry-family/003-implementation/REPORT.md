# A09 Wave 1 REPORT — Implementer (Registry Family + Identity + Audit)

## Status: COMPLETED — 390/390 tests GREEN

| Scope | Count | Status |
|---|---|---|
| A09 (this ticket) — 11 new/rewritten test files | **114** | **GREEN** |
| A07+A08 canonical + handler_utils + middleware/observability/auth/config | 276 | GREEN (unchanged) |
| **Total in-scope tests** | **390** | **GREEN** |

A09 scope analyzer (`mcp__dart__analyze_files` over all 11 production files + 11 test files + `app_router.dart` + `bin/server.dart`) reports **zero errors**. Pre-existing severity-1 errors on A05-legacy handlers (`lookup_handler`, `assessment_handler`, `care_handler`, `protection_handler`, `health_handler`, `team_handler`, `remote/social_care_api_client.dart`) are **inherited from A08** and out of A09 scope — A10–A15 own them.

## Files created (11 production + 2 wiring)

### `lib/src/intents/`
- `add_family_member_intent.dart` — **REWRITE**: `{patientId, request, cpf?, fullName?}`; `parseFromBody` P2 if-case on `[relationship, birthDate, prRelationshipId]`; private `_AddFamilyMemberParseError`; PII-safe error message
- `remove_family_member_intent.dart` — `parseFromParams({patientId, memberId})`; non-empty invariant
- `assign_primary_caregiver_intent.dart` — P2 if-case on `memberPersonId`
- `update_social_identity_intent.dart` — P2 if-case on `typeId`; `description` collapses to `null` when empty
- `get_audit_trail_intent.dart` — **total** `parseFromQuery` factory (mirrors `ListPatientsIntent`); invalid ints → `null`

### `lib/src/use_cases/`
- `add_family_member_use_case.dart` — **REWRITE** (saga): sealed `_PersonResolution` (`_PersonResolved | _PersonSkipped | _PersonFailed`); emits `registry.family.add.{received, people_context.reference_start, social_care.family_add_start, completed, failed}`; `received` carries `{patientId, hasCpf, hasPersonId}` (never raw CPF/name); `completed` carries `{patientId, memberPersonId}`; short-circuits Registry call on People failure
- `remove_family_member_use_case.dart` — triad `registry.family.remove.*`; `received` data `{patientId, memberId}`
- `assign_primary_caregiver_use_case.dart` — triad `registry.family.assign_caregiver.*`; `received` data `{patientId}`
- `update_social_identity_use_case.dart` — triad `registry.social_identity.update.*`; `received` data `{patientId}`; description NEVER in breadcrumbs
- `get_audit_trail_use_case.dart` — triad `registry.audit_trail.get.*`; `received` data `{patientId, hasEventTypeFilter, hasPagination}`; `completed` data `{count}` only

### `lib/src/handlers/`
- `registry_family_handler.dart` — 5 routes (POST / DELETE / PUT / PUT / GET); duplicates helpers verbatim from `RegistryPatientHandler`. Pinned 400 codes: `INVALID_ADD_FAMILY_MEMBER_BODY`, `INVALID_REMOVE_FAMILY_MEMBER_PARAMS`, `INVALID_PRIMARY_CAREGIVER_BODY`, `INVALID_SOCIAL_IDENTITY_BODY`, `INVALID_JSON`. 500 `INTERNAL` path sanitizes non-`BackendError` failures

### Wiring
- `lib/src/server/app_router.dart` — new `buildRegistryFamilyHandler({registry, people, audit})`; `AppRouter` now requires `AuditContract auditContract`; protected pipeline = `Cascade` of both registry handlers
- `bin/server.dart` — instantiates `FakeAuditBff()` as `auditContract` (dev-only until A21)

## Files deleted (legacy cleanup)

**Production (`lib/`)**
- `handlers/registry_handler.dart` — A05-dead (used removed `SocialCareContract`), not wired after A08
- `intents/pre_registered_family_member_dto.dart` — subsumed by new `AddFamilyMemberIntent`

**Tests**
- `test/handlers/registry_handler_test.dart` — exercised the deleted legacy handler
- `test/server/app_router_test.dart` — pre-A07 wiring (FakeSocialCareBff); already broken, not in A09 scope to rewrite (future router-integration ticket)

**Preserved (inspected)**
- `test/handlers/test_helpers.dart` — still consumed by `handler_utils_test.dart` via `testSession` (8 tests GREEN)

## Technical decisions

### AuditContract injection
Promoted to first-class required `AppRouter` dependency — mirrors pattern of `Fake{Auth,Registry,People}Bff` placeholders that A21 will replace with real HTTP adapters.

### Two-handler protected pipeline via `Cascade`
`shelf_router.Router` returns 404 for unmatched routes regardless of method — merging via `addHandler` would let one handler's 404 block the other's routes. Canonical shelf idiom is `Cascade`: `RegistryPatientHandler.router → RegistryFamilyHandler.router`. Scales to A10–A15 naturally (each joins the cascade).

### Saga short-circuit invariant (AddFamilyMember)
Exhaustive switch on sealed `_PersonResolution` guarantees the short-circuit: `_PersonFailed` matches and returns `Failure(error)` before `_continueFromRegistry` is ever called. Pinned by spy test `_FailingRegistry.addFamilyMemberCallCount == 0`.

### PII canon enforcement
- `registry.family.add.received` carries `{patientId, hasCpf, hasPersonId}` booleans — never raw CPF/name (verified by test dumping every breadcrumb `data.toString()`)
- `registry.family.add.completed` carries `{patientId, memberPersonId}` — both UUIDs
- `registry.social_identity.update.received` carries `{patientId}` only
- `registry.audit_trail.get.completed` carries `{count}` — just length
- Parse-error messages name only missing field names, never values. `_XxxParseError` is `with Equatable implements Exception`

### Handler 500 sanitization
Non-`BackendError` failures collapse to `(500, 'INTERNAL', 'Internal server error')`. Inner Dart exception message NEVER included in JSON response. Verified by `_ExplodingRegistry` test.

## Blast radius

Beyond the 11 mission files:
1. `app_router.dart` — new required `AuditContract auditContract` param + new factory + `Cascade` composition
2. `bin/server.dart` — new `FakeAuditBff()` instantiation
3. Two test files deleted (both already broken pre-A09 via A05 `SocialCareContract` removal)

No changes to A07, A08, `register_worker_use_case`, `social_care_api_client`, or contracts sub-package.

## Canonical pattern refinements for A10–A15

1. **Handler factory signature** — `build<Bounded>Handler({required Contract1, required Contract2, ...})`. `AppRouter` doesn't know the wiring — the factory owns it
2. **Protected pipeline = `Cascade` of handlers** — adding each new handler is a one-liner `.add(newHandler.router.call)`
3. **Helpers copy-paste rather than extract** — `_readJsonBody` / `_errorResponse` / etc. duplicated verbatim. Motivation: each handler stays a self-contained unit of reasoning. Consolidation refactor is cheap once A10–A15 land
4. **P2 if-case on required fields, P1 switch on `Result<T>`, sealed classes for saga state** — identical to A07+A08 canon
5. **Total vs. Result factories for query intents** — `parseFromQuery` stays total (never Result). Invalid ints → `null`

## Key file paths
- `bff/social_care_web/lib/src/intents/{add_family_member,remove_family_member,assign_primary_caregiver,update_social_identity,get_audit_trail}_intent.dart`
- `bff/social_care_web/lib/src/use_cases/{add_family_member,remove_family_member,assign_primary_caregiver,update_social_identity,get_audit_trail}_use_case.dart`
- `bff/social_care_web/lib/src/handlers/registry_family_handler.dart`
- `bff/social_care_web/lib/src/server/app_router.dart`
- `bff/social_care_web/bin/server.dart`

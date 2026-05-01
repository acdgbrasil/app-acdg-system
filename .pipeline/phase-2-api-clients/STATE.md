# Pipeline State: phase-2-api-clients

## Current Phase
phase: execute
agent: maestro
status: in-progress — Desktop Contract Conformance (Wave 5)

## Decisions Log
- [2026-04-16] Scope: Phase 2 API Client Migrations — 4 issues (#51, #52, #53, #54)
- [2026-04-16] Profile: data-layer (implementing API clients and web handlers)
- [2026-04-16] wave 1: apply all changes concurrently in `SocialCareApiClient` and `SocialCareBffRemote` mappings.
- [2026-04-16] discuss: The user has approved the execution of the described scope.
- [2026-04-16] wave 1: Completed #51 (Lifecycle endpoints mapped to contract), #52 (added Governance to SocialCareContract, FakeSocialCareBff, SocialCareApiClient, and SocialCareBffRemote), #53 (forward pagination params), and #54 (updated HttpSocialCareClient BackendError response unpacking).
- [2026-04-16] wave 2: Added missing Registry and Lookup endpoint mappings in `RegistryHandler` and `LookupHandler`.
- [2026-04-16] wave 4 (Quality Gate): Attempting to run `dart analyze bff` yielded 244 errors because Phase 1 changed all DTOs in `SocialCareContract`, breaking the Flutter App's `social_care` module implementation and tests.
- [2026-04-16] wave 5 DECISION: Instead of a generic "Phase 3", attack the Desktop offline-first layer specifically — `local_social_care_repository.dart`, `offline_first_repository.dart`, and `sync_engine.dart` are the primary sources of the errors.
- [2026-04-16] wave 5: Refactored `LocalSocialCareRepository` — all method signatures now use DTOs (`RegisterPatientRequest`, `PatientResponse`, etc.) instead of domain objects (`Patient`, `PatientId`, `FamilyMember`).
- [2026-04-16] wave 5: Refactored `OfflineFirstRepository` — full `SocialCareContract` proxy implementation generated (analytics, people, governance, registry lifecycle, audit, lookup methods).
- [2026-04-16] wave 5: Refactored `SyncEngine._dispatchAction` — removed all `PatientTranslator` + domain object usage; now deserializes `RegisterPatientRequest`, `AddFamilyMemberRequest`, `AssignPrimaryCaregiverRequest`, etc. directly from the persisted JSON payload.
- [2026-04-16] wave 5: Fixed `updateCacheFromSummaries` to accept `List<PatientSummaryResponse>` (from `LocalCacheContract`).
- [2026-04-16] wave 5: Fixed `updateCacheFromRemote` to accept `PatientResponse` (from `LocalCacheContract`), using `dto.patientId`, `pd?.firstName`, `dto.version`.
- [2026-04-16] wave 5: Fixed `hasPendingActions` to accept `String` instead of `PatientId`.
- [2026-04-16] wave 5: Fixed `updateLookupCache` to accept `List<Map<String, dynamic>>` (matching `LocalCacheContract`).
- [2026-04-16] wave 5: Fixed `PatientSummaryResponse` instantiation — removed invalid fields (`birthDate`, `meta`, `createdAt`, `status`, `latestDiagnosis`), using `patientId`, `personId`, `firstName`, `lastName`, `fullName`, `primaryDiagnosis`.
- [2026-04-16] wave 5: Fixed `StandardResponse` instantiation — removed invalid `status` field, added required `meta: ResponseMeta(timestamp: ...)`.
- [2026-04-16] wave 5: Fixed `PaginatedList` instantiation — correct `PaginationMeta` with `totalCount`, `pageSize`, `hasMore` fields.
- [2026-04-16] wave 5: Added all missing abstract method implementations to both `LocalSocialCareRepository` and `OfflineFirstRepository` via scripted appends (analytics, people context, governance, lookup methods).
- [2026-04-16] wave 5: Fixed method signature overrides — `getIndicators(String axisId, {String? period})`, `fetchPeople({String? cpf, String? cursor, int? limit, String? name})`, `listPersonRoles(String personId, {bool? active})`, `queryRoles({bool active, String? role, required String system})`, `deactivateRole/reactivateRole({required String personId, required String roleId})`.

## Completed Phases
- [x] 000-request (scope classified)
- [x] 000-discuss (context clarified)
- [ ] Wave 0: Test Definitions / Contracts (N/A — corrective work)
- [x] Wave 1: Clients Updates (Parallel changes #51, #52, #53, #54)
- [x] Wave 2: Handlers Updates
- [ ] Wave 3: Run Tests
- [x] Wave 4: Quality Gate — partial (BFF side clean, Desktop side in progress)
- [/] Wave 5: Desktop Contract Conformance — **IN PROGRESS** (~15 errors remaining)

## Blockers
- **None hard-blocking.** Remaining errors are method signature mismatches in `LocalSocialCareRepository` (from double-appended stubs that still have the old pattern — being actively resolved).

## Context for Resume
Last action: Iteratively fixing `dart analyze bff/social_care_desktop/lib/src`. Progress: 244 → 35 → 26 → 17 → 15 errors.
Current error count: **15 issues** (6 errors, 9 infos).

The 6 remaining compile errors are all in `local_social_care_repository.dart`:
- `getIndicators({required String axisId})` — needs `(String axisId, {String? period})`
- `fetchPeople({String? name, String? cpf, String? status, int? limit, int? offset})` — needs `({String? cpf, String? cursor, int? limit, String? name})`
- `listPersonRoles(String personId)` — needs `(String personId, {bool? active})`
- `queryRoles({String? status})` — needs `({bool active = true, String? role, required String system})`
- `deactivateRole({required String personId, required String role})` — needs `roleId` not `role`
- `reactivateRole({required String personId, required String role})` — needs `roleId` not `role`

Root cause: the scripted `patch_sigs.py` applied the fix only to the FIRST occurrence in the file (the method passed as appended stubs), but there are earlier stubs still remaining from an older patch that were not caught by regex because they had double-spaces before `async`.

Next action: **Direct targeted edits** to `local_social_care_repository.dart` lines 808-859 to fix the exact signature strings reported by `dart analyze`.

Key files:
- `bff/social_care_desktop/lib/src/storage/local_social_care_repository.dart` ← 6 errors at lines 810, 834, 849, 852, 855, 858
- `bff/social_care_desktop/lib/src/storage/offline_first_repository.dart` ← clean (0 errors)
- `bff/social_care_desktop/lib/src/sync/sync_engine.dart` ← clean (0 errors)
- `bff/social_care_desktop/lib/src/remote/social_care_bff_remote.dart` ← 6 INFO-only lints (non-blocking)

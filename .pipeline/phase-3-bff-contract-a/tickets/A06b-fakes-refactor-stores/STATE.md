# Ticket State: A06b-fakes-refactor-stores

phase: implementation
agent: TDD (Wave 0 test-writer + Wave 1 implementer)
status: COMPLETED — Wave 0 (RED) + Wave 1 (GREEN)

## Wave 0 — test-writer (COMPLETED, RED)

Created 6 smoke test files in `bff/shared/test/testing/stores/`:
- `in_memory_patient_store_test.dart`
- `in_memory_people_store_test.dart`
- `in_memory_lookup_store_test.dart`
- `in_memory_team_store_test.dart`
- `in_memory_care_store_test.dart`
- `in_memory_protection_store_test.dart`

All 6 files FAIL to load with `Method not found: 'InMemory*Store'` — RED as
expected. Each file documents the expected Store shape (fields + methods) in
its doc comment so the Wave 1 implementer has a clear target.

## Wave 1 — implementer (COMPLETED, GREEN)

Created 6 `InMemory*Store` classes in `bff/shared/lib/src/testing/stores/`:
- `in_memory_patient_store.dart`
- `in_memory_people_store.dart`
- `in_memory_lookup_store.dart`
- `in_memory_team_store.dart`
- `in_memory_care_store.dart`
- `in_memory_protection_store.dart`

Refactored 7 stateful fakes to use the stores:
- `FakeRegistryBff` → `InMemoryPatientStore`
- `FakePeopleBff` → `InMemoryPeopleStore`
- `FakeLookupBff` → `InMemoryLookupStore`
- `FakeTeamBff` → `InMemoryTeamStore`
- `FakeCareBff` → `InMemoryCareStore` (shape adapted — `RegisterAppointmentRequest`
  is mapped to `AppointmentResponse` and grouped by `patientId`)
- `FakeProtectionBff` → `InMemoryProtectionStore`
- `FakeAuditBff` → simplified, `_trails` renamed to public `trails`

Cleaned stateless/config-only fakes:
- `FakeHealthBff` / `FakeAnalyticsBff` / `FakeAssessmentBff` — untouched (no `_field`)
- `FakeAuthBff` — `_me` renamed to public `currentMe` (name chosen to avoid
  clashing with the contract method `me()`); `setMe` still works

Exports added to `bff/shared/lib/shared.dart` under a new `Testing — Stores`
section (6 new entries).

Results:
- `dart analyze lib`: **0 issues**
- `dart analyze` (lib + tests): **0 issues**
- `dart test test/testing/stores/`: **41 tests GREEN**
- `dart test test/testing/fakes/`: **25 tests GREEN** (A06 non-regression)
- `dart test` (entire package): **377 tests GREEN**

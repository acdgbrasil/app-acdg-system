# Ticket State: A06-fakes-per-contract

phase: implementation
agent: TDD (Wave 0 test-writer + Wave 1 implementer)
status: COMPLETED (Wave 0 + Wave 1 green)

## Wave 0 artifacts
- 11 smoke tests in `bff/shared/test/testing/fakes/`
- All tests RED at start — "Method not found: Fake<X>Bff" (expected)

## Wave 1 artifacts
- 11 fakes in `bff/shared/lib/src/testing/` (one per sub-contract)
- Legacy `bff/shared/lib/src/testing/fake_social_care_bff.dart` deleted
- `bff/shared/lib/shared.dart` updated: 1 export removed, 11 added
- `dart analyze lib` → zero issues
- `dart test test/testing/fakes/` → 25 tests pass (all green)

## Outcome
Ticket A06 complete. Downstream tickets (A07-A18) can consume the per-context
fakes directly from `package:shared/shared.dart`.

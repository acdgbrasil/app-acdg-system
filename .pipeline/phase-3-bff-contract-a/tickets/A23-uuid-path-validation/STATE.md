# Ticket State: A23-uuid-path-validation

## Current Phase
phase: in-progress — W0 done + **W1 complete** (Patient: get + 4 lifecycle)
agent: implementer (paused for context-window management)
status: Templates A and C both validated end-to-end; mechanical replication
pending across W2–W4 (~21 endpoints). W2 ready-to-resume —
3 deviations from the verbatim templates documented inline (see
"What's pending → W2"): RemoveFamilyMember signature shape,
AssignPrimaryCaregiver path-param count correction,
GetAuditTrail intent shape (parseFromQuery factory, no parseFromPath
yet).

## What's done

### W0 — Helper canon (COMPLETE)
- `lib/src/intents/uuid_validation.dart` — public top-level
  `validateUuidPathParam(String raw, {required String fieldName}) → Result<String>`
  + public `UuidPathParamError` data class (Equatable, implements Exception).
- `test/intents/uuid_validation_test.dart` — 28 tests GREEN covering:
  - Success: valid v4, uppercase normalization, mixed case, whitespace
    trim, all 4 variant nibbles (8/9/a/b)
  - Failure: empty, whitespace-only, `'people'` (the bleed case), v1, v3,
    v5, NIL UUID, invalid variant nibbles, MS Guid braces, URN form,
    no-hyphens, too short, too long, non-hex, path traversal attempts
  - PII safety: error never echoes raw input; uses fieldName per call
  - Equatable + Exception interop
- `test/_test_uuids.dart` — canonical UUID v4 fixtures shared across the
  suite (`kPatientUuid`, `kPatientUuidAlt`, `kFamilyMemberUuid`,
  `kMemberUuid`, `kRoleUuid`, `kLookupItemUuid`, `kLookupRequestUuid`,
  `kAppointmentUuid`, `kReferralUuid`, `kViolationReportUuid`,
  `kAuditUuid`) + sentinels (`kNonUuid = 'people'`,
  `kPathTraversalAttempt`, `kUuidV1`).

### W1 — Patient surface complete (CANONICAL TEMPLATES)
Validated end-to-end: helper, GetPatient (Template A), and 4 lifecycle
P2 endpoints (Template C) — Intent + Test + Handler + Handler test all
GREEN. **Both templates now have a working canonical reference.**

Files modified in W1:
- **GetPatient (Template A — first wave)**
  - `lib/src/intents/get_patient_intent.dart` — added `parseFromPath`
  - `test/intents/get_patient_intent_test.dart` — added `parseFromPath`
    group (5 new tests; `kPatientUuid`, `kPatientUuidAlt`, `kNonUuid`,
    `kUuidV1`)
  - `lib/src/handlers/registry_patient_handler.dart` — `_handleGet` now
    uses `parseFromPath` + `_runGet` helper; emits
    `400 INVALID_GET_PATIENT_PARAMS` on UUID failure

- **Lifecycle quartet (Template C — second wave)**
  - `lib/src/intents/admit_patient_intent.dart`
  - `lib/src/intents/discharge_patient_intent.dart`
  - `lib/src/intents/readmit_patient_intent.dart`
  - `lib/src/intents/withdraw_patient_intent.dart`
    All 4 replaced the `if (patientId.isEmpty)` guard with a
    `validateUuidPathParam(rawPatientId, fieldName: 'patientId')` call
    at the top of `parseFromBody`. The `_<X>ParseError` helper class is
    kept for body-level errors only; UUID path failures surface
    `UuidPathParamError` directly. Readmit's now-redundant
    `_ReadmitParseError` was removed (UUID gate covers all path
    failures; body parsing for readmit cannot fail).
  - **Handler unchanged** — confirms Template C decision: a single
    `INVALID_<X>_BODY` per endpoint, with the message itself
    distinguishing path vs body via the `Invalid path parameter [...]`
    prefix from `UuidPathParamError.toString()`.

- **Test sweeps**
  - 4 lifecycle intent tests: `'pat-1'` → `kPatientUuid`,
    `'pat-2'` → `kPatientUuidAlt`; added `kNonUuid`-rejection +
    PII-safety tests (`error.toString()` does NOT contain `kNonUuid`).
    Readmit's "empty patientId" test was kept — empty still fails the
    UUID gate; only the wrapping error type changed.
  - `test/handlers/registry_patient_handler_test.dart`: 12 URI paths
    `/patients/pat-1/<verb>` → `/patients/$kPatientUuid/<verb>`;
    4 new tests `returns 400 INVALID_<X>_BODY when path id is not a
    UUID v4` (one per verb) with PII-safety assertion;
    `'unknown'` fixture in 404 test replaced by `kPatientUuidAlt`
    (fixture-only change — REGRA #2 application logged below).

GREEN counts at W1 close (intents/ + patient handler subset):
- helper `uuid_validation_test`: 28
- intents/ directory full sweep: 407
- handlers/registry_patient_handler_test: 26 (was 22 + 4 new)
- Combined run `dart test test/intents/ test/handlers/registry_patient_handler_test.dart`: **433 GREEN**

`dart analyze` on the 9 A23-touched files (4 intents + 4 intent tests +
1 handler test): **0 issues**. Pre-existing analyzer errors in
`health_handler.dart`, `social_care_api_client.dart` and their tests
are unrelated to A23 (they predate this ticket — confirmed via
`git status`: those files show no W0/W1 modifications).

## Canonical templates (replicate verbatim for the remaining ~25 endpoints)

### Template A — Path-only intent (1 path param)
Mirrors `GetPatientIntent`. Applies to: `GetPatient`, `GetAuditTrail`,
`ApproveLookupRequest`, `RejectLookupRequest`,
`RemoveFamilyMember` (2 path params — see Template C),
`GetTeamMember` (A15 resume), all worker/role lifecycle (A15 resume).

```dart
// lib/src/intents/<x>_intent.dart
import 'package:core_contracts/core_contracts.dart';
import 'uuid_validation.dart';

final class <X>Intent with Equatable {
  const <X>Intent({required this.<id>});

  final String <id>;

  @override
  List<Object?> get props => [<id>];

  static Result<<X>Intent> parseFromPath(String raw<Id>) {
    final validated = validateUuidPathParam(raw<Id>, fieldName: '<id>');
    return switch (validated) {
      Success(:final value) => Success(<X>Intent(<id>: value)),
      Failure(:final error) => Failure(error),
    };
  }
}
```

### Template B — Path-only intent (2 path params)
Applies to: `RemoveFamilyMember(patientId, familyMemberId)`,
`DeactivateRole(memberId, roleId)`, `ReactivateRole(memberId, roleId)`.

```dart
static Result<<X>Intent> parseFromPath(
  String raw<Id1>,
  String raw<Id2>,
) {
  final v1 = validateUuidPathParam(raw<Id1>, fieldName: '<id1>');
  if (v1 case Failure(:final error)) return Failure(error);
  final v2 = validateUuidPathParam(raw<Id2>, fieldName: '<id2>');
  if (v2 case Failure(:final error)) return Failure(error);
  return Success(
    <X>Intent(
      <id1>: (v1 as Success<String>).value,
      <id2>: (v2 as Success<String>).value,
    ),
  );
}
```

### Template C — P2 intent (1 path param + body)
Applies to: `AdmitPatient`, `DischargePatient`, `ReadmitPatient`,
`WithdrawPatient`, `AddFamilyMember`, `AssignPrimaryCaregiver`,
`UpdateSocialIdentity`, all 7 Assessment fichas, `RegisterAppointment`,
`UpdateIntakeInfo`, `CreateReferral`, `ReportRightsViolation`,
`UpdatePlacementHistory`, `UpdateLookupItem` (path: tableName +
itemId), `ToggleLookupItem` (path: tableName + itemId), `AssignRole`
(path: memberId).

**Strategy:** keep the existing `parseFromBody(rawId, body)` signature.
Add a UUID validation at the top of `parseFromBody`. The path-param
fieldName for the error must match the route name exactly (e.g.
`patientId`, `memberId`).

```dart
static Result<<X>Intent> parseFromBody(
  String raw<Id>,
  Map<String, dynamic> body,
) {
  final pathResult = validateUuidPathParam(raw<Id>, fieldName: '<id>');
  if (pathResult case Failure(:final error)) return Failure(error);
  final <id> = (pathResult as Success<String>).value;

  // ... existing body parsing logic, using `<id>` as the validated value.
  // The old `if (rawId.isEmpty)` guard can be removed — UUID validation
  // already covers it.
}
```

**Edge case — `UpdateLookupItem` and `ToggleLookupItem` have a path of
`{tableName}/{itemId}`.** `tableName` is NOT a UUID (it is a literal
like `dominio_parentesco`). Only `itemId` is validated as UUID. The
existing tableName validation (membership in a known set, if any)
stays as-is.

### Template D — Handler routing
For path-only endpoints:
```dart
Future<Response> _handle<X>(Request request, String id) async {
  final obs = ObservabilityContext.fromRequestOrNoop(request);
  final parsed = <X>Intent.parseFromPath(id);
  return switch (parsed) {
    Failure(:final error) => _badRequest(
      code: 'INVALID_<X>_PARAMS',
      message: error.toString(),
    ),
    Success(:final value) => await _run<X>(value, obs),
  };
}
```

For P2 endpoints, the existing `parseFromBody` flow already returns the
correct Failure/Success — only the handler error code needs updating
to discriminate body vs path failures. Decision: **single 400 code per
endpoint** (`INVALID_<X>_BODY` covers both). The error message itself
distinguishes ("Invalid path parameter [...]" vs "Invalid <x> body:
missing or empty [...]"). Simpler than dual codes.

### Template E — Handler test additions
For each retrofitted endpoint:
1. Replace synthetic IDs (`'pat-1'`, `'m-1'`, etc.) with the canonical
   constant from `_test_uuids.dart`.
2. Add a test asserting `400 INVALID_<X>_PARAMS` (or
   `INVALID_<X>_BODY` for P2) when the path id is `kNonUuid`.
3. Verify error.message does NOT contain the raw `kNonUuid` string
   (PII safety).
4. **REGRA #2 watch:** any pre-existing 404/500 test that used a
   non-UUID literal (e.g. `'unknown'`, `'missing'`) needs the fixture
   replaced by `kPatientUuidAlt` (or equivalent) — UUID format is
   valid but absent from store. Document the change as fixture-only.

## What's pending

### W2 — A09 Family + Audit (5 intents)
- [ ] AddFamilyMemberIntent (Template C, patientId) — straightforward;
      remove the existing `if (patientId.isEmpty)` guard once UUID
      validation lands at top of `parseFromBody`.
- [ ] RemoveFamilyMemberIntent (Template B, 2 path params) —
      **deviation from Template B verbatim:** the current method
      signature is `parseFromParams({required String patientId,
      required String memberId})` (named args, not positional). Two
      options: (a) keep named-args and adapt Template B inline
      (preferred — call site `_handleRemove` in
      `registry_family_handler.dart:89` already uses named args), or
      (b) change to positional to match the template literally and
      update the handler call. (a) is lower-risk.
- [ ] AssignPrimaryCaregiverIntent (Template C, **1 path param only**)
      — STATE.md Wave-list previously claimed "patientId +
      familyMemberId, 2 path params". That was wrong: route is
      `PUT /patients/<id>/primary-caregiver` (1 path param);
      `familyMemberId` is in the request body. Plain Template C with
      `patientId` only.
- [ ] UpdateSocialIdentityIntent (Template C, patientId) —
      straightforward; same pattern as the lifecycle quartet.
- [ ] GetAuditTrailIntent (Template A, patientId) — **template not
      verbatim.** Current intent has only `parseFromQuery` (factory,
      total — constructs even when `patientId.isEmpty`, by design,
      delegating rejection to handler). Two options:
      (a) **add a second static `parseFromPath(String rawPatientId)`**
      returning `Result<String>` (just the validated id), and have
      `_handleGetAuditTrail` call `parseFromPath` first, then
      `parseFromQuery` for the rest — minimal change to the existing
      total-function semantics. (b) make the handler call
      `validateUuidPathParam` directly before `parseFromQuery`. (a)
      keeps the validation inside the intent (Template A spirit) and
      is the recommended path.

### W3 — A10 Assessment 7 fichas (Template C × 7)
- [ ] UpdateHousingConditionIntent
- [ ] UpdateSocioEconomicSituationIntent
- [ ] UpdateWorkAndIncomeIntent
- [ ] UpdateEducationalStatusIntent
- [ ] UpdateHealthStatusIntent
- [ ] UpdateCommunitySupportNetworkIntent
- [ ] UpdateSocialHealthSummaryIntent

### W4 — A11 + A12 + A13 (9 intents)
- A11 Care: RegisterAppointment, UpdateIntakeInfo (Template C)
- A12 Protection: CreateReferral, ReportRightsViolation,
  UpdatePlacementHistory (Template C)
- A13 Lookup: UpdateLookupItem (Template C, itemId only — see edge case
  in Template C), ToggleLookupItem (same), ApproveLookupRequest
  (Template A, requestId), RejectLookupRequest (Template A, requestId)

### W5 — Replace remaining synthetic IDs in handler tests
- After W1-W4, sweep the remaining 28 handler/intent test files for
  any `'pat-X'`, `'m-X'`, `'r-X'` literals not yet touched. Replace
  with canonical fixtures.
- Watch for any 404 tests using non-UUID literals — apply REGRA #2:
  fixture is wrong, expectation is right.

### W6 — Quality gate + close
- [ ] dart analyze 0 new errors
- [ ] dart test ≥ ~1100 GREEN (was 946 at A15 pause; +~150 expected)
- [ ] Update CONTRACT_A_PUBLIC_API.md with the invariant
- [ ] Update phase STATE marking A23 done
- [ ] Mark A15 ready-to-resume

## REGRA #2 application log
Already happened in W1 partial: `registry_patient_handler_test.dart`
test `returns 404 when patient does not exist` used fixture
`'unknown'` (non-UUID). After A23 retrofit, that path returns 400
INVALID_GET_PATIENT_PARAMS — not 404. Applied the 4-point analysis:
intent valid (test 404 absence), failure cause (fixture not UUID),
verdict (fixture wrong), option (replace with `kPatientUuidAlt`).
Done. **Watch for similar fixture-driven failures throughout W1-W4.**

## Numbers at this checkpoint (W1 close)
- intents/ test directory: 407 GREEN (helper 28 + GetPatient 8 +
  4 lifecycle intents 22 + 12 other existing intent test files
  unchanged but counted by the directory run)
- handlers/registry_patient_handler_test: 26 GREEN (was 22 + 4 new
  UUID-rejection tests, one per lifecycle verb)
- Combined `dart test test/intents/ test/handlers/registry_patient_handler_test.dart`: **433 GREEN**
- 0 new analyzer issues introduced by A23 W0+W1
- Total BFF Web suite: 946 GREEN at A15 pause. A23 W0+W1 adds Patient
  surface UUID coverage; full project count update happens at W6 once
  W2–W4 are done and any cross-feature handler tests are swept.

## Why paused here
Both Template A (path-only) and Template C (path + body) are validated
end-to-end on the Patient surface. Remaining work is mechanical
replication across ~21 endpoints (W2–W4) plus the test sweep (W5) and
quality gate (W6). Better executed in a fresh session with focused
context window. The templates in this STATE.md are sufficient for any
subsequent session (or a different agent) to pick up without
re-deriving the design.

# Ticket State: A23-uuid-path-validation

## Current Phase
phase: in-progress — W0+W1+**W2 complete** (Patient surface +
A09 Family/Audit retrofit)
agent: implementer
status: Templates A, B (named-args variant), and C all validated
end-to-end. Mechanical replication pending across W3–W4 (~16 endpoints).

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
**Two body-parsing variants exist in the canon — both compatible with
this template.** Choose based on the existing intent's pre-A23 shape:

- **C-P2** (if-case body matcher) — Patient lifecycle (W1), A09
  Add/AssignCaregiver/UpdateSocialIdentity (W2). The existing
  `if (patientId.isEmpty)` guard is REMOVED; the UUID gate
  short-circuits empty / malformed inputs.
- **C-P2b** (try/catch over `fromJson`) — A10 Assessment (W3 target),
  most Care/Protection intents. **No `if (patientId.isEmpty)` to
  remove** — pre-A23 P2b intents have no such guard. UUID gate is
  ADDED above the try/catch, no body-parsing logic changes.

Applies to: `AdmitPatient`, `DischargePatient`, `ReadmitPatient`,
`WithdrawPatient`, `AddFamilyMember`, `AssignPrimaryCaregiver`,
`UpdateSocialIdentity` (all C-P2); all 7 Assessment fichas,
`RegisterAppointment`, `UpdateIntakeInfo`, `CreateReferral`,
`ReportRightsViolation`, `UpdatePlacementHistory` (all C-P2b);
`UpdateLookupItem` (path: tableName + itemId), `ToggleLookupItem`
(path: tableName + itemId), `AssignRole` (path: memberId).

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

### W2 — A09 Family + Audit (5 intents) ✅ COMPLETE
- [x] AddFamilyMemberIntent (Template C verbatim) — `parseFromBody`
      now validates `rawPatientId` via `validateUuidPathParam` at top.
      `_AddFamilyMemberParseError` retained for body-level errors.
      Handler error code unchanged (single `INVALID_ADD_FAMILY_MEMBER_BODY`).
- [x] RemoveFamilyMemberIntent (Template B, named-args adaptation) —
      kept named-args signature renamed `rawPatientId` / `rawMemberId`,
      validates both UUIDs in sequence (patientId first short-circuits).
      `_RemoveFamilyMemberParseError` deleted (UUID gate covers all
      paths; body-less endpoint). Handler call site updated; error code
      `INVALID_REMOVE_FAMILY_MEMBER_PARAMS` unchanged.
- [x] AssignPrimaryCaregiverIntent (Template C verbatim) — same pattern
      as Add; 1 path param confirmed (familyMemberId is body, not path).
      Handler error code unchanged (`INVALID_PRIMARY_CAREGIVER_BODY`).
- [x] UpdateSocialIdentityIntent (Template C verbatim) — same pattern.
      Handler error code unchanged (`INVALID_SOCIAL_IDENTITY_BODY`).
- [x] GetAuditTrailIntent (Template A spirit, two-factory shape) —
      kept the existing total-function `parseFromQuery` factory
      unchanged. Added `static Result<String> parseFromPath(String
      rawPatientId)` that returns the validated id. Handler now calls
      `parseFromPath` first, returns 400
      `INVALID_GET_AUDIT_TRAIL_PARAMS` on UUID failure, else passes the
      normalized id to `parseFromQuery`.

W2 numbers (delta from W1):
- Intent tests run-time `dart test test/intents/`: 61 NEW for the 5
  retrofitted intents (helper + W1 already counted prior).
- Handler test `registry_family_handler_test.dart`: 19 + 6 new
  UUID-rejection tests = 25 GREEN.
- Combined `dart test test/intents/ test/handlers/registry_family_handler_test.dart
  test/handlers/registry_patient_handler_test.dart`: **469 GREEN**.
- Full BFF Web suite: 1006 GREEN / 2 FAIL (same 2 pre-existing A21
  failures: `health_handler_test.dart` and
  `social_care_api_client_test.dart` reference deleted
  `SocialCareContract` and `FakeSocialCareBff`; cleanup scheduled for
  A21).
- 0 new analyzer issues from W2 surface (2 pre-existing infos in
  `register_worker_intent_test.dart` are A15, outside W2 scope).

### W3 — A10 Assessment 7 fichas (Template C, **P2b variant**)
**Important shape difference from W1/W2:** the 7 Assessment intents use
the **P2b try/catch over `fromJson`** pattern (per A10's "padrão novo
try/catch sobre fromJson"), not P2 if-case. Concretely:
- Each `parseFromBody(String patientId, Map<String, dynamic> body,
  {ObservabilityContext? obs})` wraps `XRequest.fromJson(body)` in a
  try/catch, logs via `obs?.logError`, and returns `_<X>ParseError`.
- There is **no `if (patientId.isEmpty)` guard to remove** — the W1
  Template C advice ("the old guard can be removed") does not apply.
  W3 only ADDS the UUID gate above the try/catch.

**Per-intent retrofit recipe (all 7 identical):**
```dart
import 'uuid_validation.dart';

static Result<X> parseFromBody(
  String rawPatientId,                       // renamed
  Map<String, dynamic> body, {
  ObservabilityContext? obs,
}) {
  final pathResult = validateUuidPathParam(
    rawPatientId,
    fieldName: 'patientId',
  );
  if (pathResult case Failure(:final error)) return Failure(error);
  final patientId = (pathResult as Success<String>).value;

  try {
    final request = XRequest.fromJson(body);
    return Success(X(patientId: patientId, request: request));
  } catch (e, st) {
    obs?.logError('assessment.<x>.parse_failed', cause: e, stack: st);
    return Failure(const _XParseError('Invalid update-<x> body: ...'));
  }
}
```
(`_<X>ParseError` is RETAINED — body/fromJson failures still need it;
UUID gate adds a new failure mode without replacing the existing one.)

**Decisions to apply:**
- Keep `obs?.logError` only inside the catch block (UUID failures are
  cheap rejections at the boundary; W1/W2 did not log them and we
  follow precedent for consistency).
- Single 400 error code per endpoint (`INVALID_<X>_BODY`) — Template D
  default. The handler is unchanged; the message itself
  distinguishes path vs body via `Invalid path parameter [...]`
  prefix from `UuidPathParamError.toString()`.

**Targets (7 intents × 1 retrofit each):**
- [ ] UpdateHousingConditionIntent (`update_housing_condition_intent.dart`)
- [ ] UpdateSocioEconomicSituationIntent
- [ ] UpdateWorkAndIncomeIntent
- [ ] UpdateEducationalStatusIntent
- [ ] UpdateHealthStatusIntent
- [ ] UpdateCommunitySupportNetworkIntent
- [ ] UpdateSocialHealthSummaryIntent

**Per-intent test sweep (7 files, mechanical):**
1. Add: `import 'package:social_care_web/src/intents/uuid_validation.dart';`
2. Add: `import '../_test_uuids.dart';`
3. Replace `'pat-1'` → `kPatientUuid` (78 occurrences across the 7
   files; replace_all is safe — `pat-1` appears nowhere outside
   patientId positions).
4. Replace `'pat-2'` → `kPatientUuidAlt` (7 occurrences, one per file
   in the "instances with different payloads are not equal" test).
5. Add 1 new test per file: `returns Failure with UuidPathParamError
   when path id is not UUID v4` + PII-safety assertion.

**Handler + handler test sweep:**
- `assessment_handler.dart`: NO production change required. The
  intent's `parseFromBody` already short-circuits on UUID failure and
  the handler's existing `_badRequest(code: 'INVALID_<X>_BODY', ...)`
  branch carries the UUID error message verbatim.
- `assessment_handler_test.dart`: sweep `'/patients/pat-1/'` →
  `'/patients/$kPatientUuid/'` (29 occurrences across all 7 routes).
- Add 7 new tests (one per route): `returns 400 INVALID_<X>_BODY
  when path id is not UUID v4` with PII-safety assertion. Reuse the
  `_put` helper that already exists in the test file.

**REGRA #2 watch — clean for W3:**
Surveyed `assessment_handler_test.dart` for fixture-driven 404/500
literals (`'unknown'`, `'missing'`, etc.). **None present.** All
non-happy-path tests use either body-level validation (already
covered by `_<X>ParseError`) or `_FailingAssessment` /
`_ExplodingAssessment` style fakes that don't depend on the path id
literal. No fixture corrections needed — pure mechanical UUID sweep.

**Numbers expected at W3 close:**
- Baseline (now): 86 GREEN (8×7 intent + 29 handler + 1 cross =
  78 baseline retained, 29 handler retained — wait, full count
  is 8+8+8+8+9+8+8 + 29 = 87; the 86 in the standalone run is
  this set). Re-run: `dart test test/intents/update_*intent_test.dart
  test/handlers/assessment_handler_test.dart`.
- Expected after W3: +7 intent rejection tests + +7 handler
  rejection tests = **+14 GREEN** (~100 in the W3 surface alone).
- Full BFF Web suite expected: 1006 + 14 = **1020 GREEN / 2 FAIL**
  (same 2 pre-existing A21 failures).

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

## Numbers at this checkpoint (W2 close)
- intents/ test directory full run: 442 GREEN
  (helper 28 + GetPatient 8 + 4 Patient lifecycle intents 22 +
  AddFamilyMember 13 + RemoveFamilyMember 11 +
  AssignPrimaryCaregiver 8 + UpdateSocialIdentity 8 +
  GetAuditTrail 13 + 11 other existing intent files unchanged but
  counted by the directory run).
- handlers/registry_patient_handler_test: 26 GREEN (W1).
- handlers/registry_family_handler_test: 25 GREEN (W2 — was 19 + 6
  new UUID-rejection tests, one per endpoint variant).
- Combined `dart test test/intents/
  test/handlers/registry_family_handler_test.dart
  test/handlers/registry_patient_handler_test.dart`: **469 GREEN**.
- Full BFF Web suite: **1006 GREEN / 2 FAIL** (same 2 pre-existing
  A21 failures from deleted `SocialCareContract` /
  `FakeSocialCareBff`; A23 added +17 net tests since W1 close).
- 0 new analyzer issues from W2 surface. Pre-existing A15 infos in
  `register_worker_intent_test.dart` remain (outside W2 scope).

## Templates B coverage update
Template B verbatim (positional 2-id args) was never used in W2. The
adaptation in `RemoveFamilyMemberIntent.parseFromParams({required
String rawPatientId, required String rawMemberId})` is the canonical
named-args variant for path-only intents with multiple ids. W3+ may
need verbatim Template B for `DeactivateRole(memberId, roleId)` and
`ReactivateRole(memberId, roleId)` (A15 resume — Team).

## What's next (W3 entry checklist)
1. Apply Template C verbatim to the 7 Assessment fichas. Each follows
   the same shape as `AdmitPatientIntent.parseFromBody` (already
   retrofitted in W1) — single `rawPatientId` validated at top,
   existing body P2 if-case retained.
2. Reuse `kPatientUuid` / `kPatientUuidAlt` fixtures across the
   assessment intent tests; replace any synthetic `'pat-X'` string.
3. Each ficha handler needs the same `'pat-X'` → `$kPatientUuid` URL
   sweep + 1 new UUID-rejection test per endpoint (asserting
   `INVALID_<X>_BODY` 400 with PII safety).
4. `AssessmentHandler` is a single file with 7 routes — sweep all 7 in
   one PR; expect ~14 new tests (intent + handler).
5. Watch for REGRA #2 fixture-driven 404 tests in
   `assessment_handler_test.dart` (similar to the
   `'unknown'` → `kPatientUuidAlt` correction in W1).

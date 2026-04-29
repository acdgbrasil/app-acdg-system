# Ticket State: A23-uuid-path-validation

## Current Phase
phase: **DONE** — W0+W1+W2+W3+W4 complete + V2 templates retrofit
+ defesas em depth (Camadas 1-6).
agent: implementer
status: All 26 BFF Web files retrofitted to V2 templates
(map / flatMap / combineWith — no sealed-class downcast). Defesas
contra regressão consolidadas: handbook §P5, skill rules 24-25,
custom lint `acdg_lints/no_sealed_class_downcast`, CI grep script,
`combineWith` 2-ary + 3-ary in `core_contracts`. Final BFF Web suite:
**1026 GREEN / 2 FAIL** (the 2 are pre-existing A21 cleanup —
`health_handler_test` + `social_care_api_client_test`). Zero new
failures from W4. Flutter packages débito tracked in **A24**
(13 files: 1 ViewModel + 1 mapper + 11 UseCases — out of A23 scope
by design).

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

## Canonical templates V2 (W4 onwards — replaces V1 verbatim canon)

> **History:** V1 templates (A/B/C) replicated `(pathResult as Success<T>).value`
> across W1+W2+W3 — 17 BFF Web files. External code review on 2026-04-29
> flagged this as a sealed-class downcast anti-pattern (see
> `W4-bypass-investigation/BYPASS-REPORT.md` and `EXTERNAL-REVIEW-PROMPT.md`
> for the full investigation, including a third-party adversarial review).
>
> **V2 forms** below use `core_contracts` combinators (`map`, `flatMap`,
> `combineWith`) instead of cast. Defendido pelo lint
> `acdg_lints/no_sealed_class_downcast` e pelo §P5 da
> `PATTERN_MATCHING_POLICY.md`. All four templates yield code that is
> shorter, exhaustiveness-checked, and preserves `stackTrace` on failure.

### Template A — Path-only intent (1 path param)
Mirrors corrected `GetPatientIntent`. Applies to: `GetPatient`,
`GetAuditTrail`, `ApproveLookupRequest`, `RejectLookupRequest`,
`GetTeamMember` (A15 resume), all worker/role lifecycle (A15 resume).

Use `Result<T>.map` from `core_contracts` — the entire parser collapses
to a one-liner:

```dart
// lib/src/intents/<x>_intent.dart
import 'package:core_contracts/core_contracts.dart';
import 'uuid_validation.dart';

final class <X>Intent with Equatable {
  const <X>Intent({required this.<id>});

  final String <id>;

  @override
  List<Object?> get props => [<id>];

  static Result<<X>Intent> parseFromPath(String raw<Id>) =>
      validateUuidPathParam(raw<Id>, fieldName: '<id>')
          .map((id) => <X>Intent(<id>: id));
}
```

### Template B — Path-only intent (2 path params)
Applies to: `RemoveFamilyMember(patientId, familyMemberId)`,
`DeactivateRole(memberId, roleId)`, `ReactivateRole(memberId, roleId)`.

Use `(Result, Result).combineWith` from
`core_contracts/result_combinators.dart`. Short-circuits on the first
failure (left → right) and preserves its `error` + `stackTrace`:

```dart
static Result<<X>Intent> parseFromParams({
  required String raw<Id1>,
  required String raw<Id2>,
}) {
  final v1 = validateUuidPathParam(raw<Id1>, fieldName: '<id1>');
  final v2 = validateUuidPathParam(raw<Id2>, fieldName: '<id2>');
  return (v1, v2).combineWith(
    (id1, id2) => <X>Intent(<id1>: id1, <id2>: id2),
  );
}
```

For 3 path params, swap to the 3-ary extension —
`(v1, v2, v3).combineWith((a, b, c) => <X>Intent(...))`.

### Template C — P2/P2b intent (1 path param + body)
**Two body-parsing variants** exist (C-P2 manual if-case vs C-P2b
try/catch over `fromJson`). Both share the same V2 outer shape via
`Result<T>.flatMap`: the body parsing moves to a private helper, and
`flatMap` chains it after UUID validation succeeds.

- **C-P2** (if-case body matcher) — Patient lifecycle (W1), A09
  Add/AssignCaregiver/UpdateSocialIdentity (W2), A11 Care intents,
  A12 Referral/Violation, A13 Lookup `Toggle*`. The pre-A23
  `if (patientId.isEmpty)` guard, if present, is REMOVED — UUID gate
  short-circuits empty / malformed inputs.
- **C-P2b** (try/catch over `fromJson`) — A10 Assessment (W3),
  `UpdatePlacementHistory`. **No `if (patientId.isEmpty)` to remove**;
  V2 still uses `flatMap` plus the existing try/catch helper.

Applies to: `AdmitPatient`, `DischargePatient`, `ReadmitPatient`,
`WithdrawPatient`, `AddFamilyMember`, `AssignPrimaryCaregiver`,
`UpdateSocialIdentity` (all C-P2); 7 Assessment fichas,
`UpdatePlacementHistory` (C-P2b); `RegisterAppointment`,
`UpdateIntakeInfo`, `CreateReferral`, `ReportRightsViolation`,
`UpdateLookupItem`, `ToggleLookupItem`, `AssignRole` (all C-P2).

```dart
static Result<<X>Intent> parseFromBody(
  String raw<Id>,
  Map<String, dynamic> body, {
  ObservabilityContext? obs, // P2b only — omit for pure P2
}) =>
    validateUuidPathParam(raw<Id>, fieldName: '<id>')
        .flatMap((<id>) => _parseBody(<id>, body, obs));

// Private helper — body parsing isolated from path validation.
// For C-P2: keep the existing if-case logic verbatim.
// For C-P2b: keep the existing try/catch over fromJson verbatim.
static Result<<X>Intent> _parseBody(
  String <id>,
  Map<String, dynamic> body,
  ObservabilityContext? obs, // C-P2b only
) {
  // ... P2 if-case body matching, OR P2b try/catch over fromJson ...
}
```

**Edge case — `UpdateLookupItem` and `ToggleLookupItem` have a path of
`{tableName}/{itemId}`.** `tableName` is NOT a UUID (it is a literal
like `dominio_parentesco`). Only `itemId` is validated as UUID. Use
Template B-style `combineWith` if a future `tableName` is also
validated to a `Result`; otherwise pass `tableName` through as a plain
`String` argument and apply `flatMap` only on the UUID validation.

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

### W3 — A10 Assessment 7 fichas (Template C, **P2b variant**) ✅ COMPLETE
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
- [x] UpdateHousingConditionIntent (`update_housing_condition_intent.dart`)
- [x] UpdateSocioEconomicSituationIntent
- [x] UpdateWorkAndIncomeIntent
- [x] UpdateEducationalStatusIntent
- [x] UpdateHealthStatusIntent
- [x] UpdateCommunitySupportNetworkIntent
- [x] UpdateSocialHealthSummaryIntent

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

**Numbers at W3 close (measured):**
- 7 intent tests (combined run `dart test
  test/intents/update_{housing,socio,work,educational,health,
  community_support,social_health_summary}_intent_test.dart`):
  **64 GREEN** (57 baseline + 7 new UUID-rejection tests, one per
  ficha).
- handler test (`dart test test/handlers/assessment_handler_test.dart`):
  **36 GREEN** (29 baseline + 7 new in the new
  `AssessmentHandler — UUID v4 path validation` group).
- Full BFF Web suite: **1020 GREEN / 2 FAIL** — exactly the predicted
  number (1006 W2 close + 14 W3 = 1020). The 2 failing test files
  are still the pre-existing A21 ones (`health_handler_test.dart` and
  `social_care_api_client_test.dart` — `[E] Failed to load`); A23
  adds zero new failures.
- 0 new analyzer issues across the 15 W3-touched files (7 intents +
  7 intent tests + 1 handler test).

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

## Numbers at this checkpoint (W3 close)
- 7 intent tests retrofitted (Assessment surface): standalone
  combined run = **64 GREEN** (57 baseline + 7 new
  UUID-rejection tests, one per ficha).
- handlers/assessment_handler_test: **36 GREEN** (29 baseline + 7
  new in `AssessmentHandler — UUID v4 path validation`).
- Full BFF Web suite: **1020 GREEN / 2 FAIL** — exactly the
  predicted 1006 (W2 close) + 14 (W3 net) total. The 2 failing
  test files are still the pre-existing A21 ones
  (`health_handler_test.dart` + `social_care_api_client_test.dart`,
  both `[E] Failed to load`); A23 W3 added zero new failures.
- 0 new analyzer issues across the 15 W3-touched files.

## Numbers at previous checkpoint (W2 close — preserved for reference)
- intents/ test directory full run: 442 GREEN.
- handlers/registry_patient_handler_test: 26 GREEN (W1).
- handlers/registry_family_handler_test: 25 GREEN (W2).
- Combined `dart test test/intents/
  test/handlers/registry_family_handler_test.dart
  test/handlers/registry_patient_handler_test.dart`: 469 GREEN.
- Full BFF Web suite: 1006 GREEN / 2 FAIL.

## Templates B coverage update
Template B verbatim (positional 2-id args) was never used in W2. The
adaptation in `RemoveFamilyMemberIntent.parseFromParams({required
String rawPatientId, required String rawMemberId})` is the canonical
named-args variant for path-only intents with multiple ids. W3+ may
need verbatim Template B for `DeactivateRole(memberId, roleId)` and
`ReactivateRole(memberId, roleId)` (A15 resume — Team).

## Files modified in W3

**7 intents (lib/src/intents/):**
- `update_housing_condition_intent.dart`
- `update_socio_economic_situation_intent.dart`
- `update_work_and_income_intent.dart`
- `update_educational_status_intent.dart`
- `update_health_status_intent.dart`
- `update_community_support_network_intent.dart`
- `update_social_health_summary_intent.dart`

Each one: `import 'uuid_validation.dart';` added, parameter renamed
`String patientId` → `String rawPatientId`, UUID gate
(`validateUuidPathParam(rawPatientId, fieldName: 'patientId')`)
inserted at the top of `parseFromBody`, dartdoc updated to mention
the A23 invariant. The `_<X>ParseError` private class and the
existing try/catch over `fromJson` are RETAINED — UUID gate adds a
new failure mode without replacing the existing one.

**Handler (lib/src/handlers/):**
- `assessment_handler.dart` — **NO CHANGES**. The intent's
  `parseFromBody` already short-circuits on UUID failure and the
  handler's existing `_badRequest(code: 'INVALID_<X>_BODY', ...)`
  branch carries the `UuidPathParamError.toString()` verbatim
  (Template D single-code-per-endpoint decision).

**7 intent tests (test/intents/) + 1 handler test (test/handlers/):**
Mechanical sweep `'pat-1'` → `kPatientUuid` (78 occurrences
across the 7 intent tests), `'pat-2'` → `kPatientUuidAlt` (7
occurrences), `/patients/pat-1/` → `/patients/$kPatientUuid/`
(29 occurrences in the handler test). Imports added:
`uuid_validation.dart` + `_test_uuids.dart`. New tests appended:
1 UUID-rejection test per intent + 1 UUID-rejection test per route
in a dedicated `AssessmentHandler — UUID v4 path validation` group.

**Decisions applied (verbatim from STATE.md W3 plan):**
- `obs?.logError` kept inside the existing catch only — UUID
  failures are cheap rejections at the boundary; precedent from
  W1/W2 is "don't log them".
- Single 400 code per endpoint (`INVALID_<X>_BODY`) — Template D
  default; the message itself distinguishes path vs body via the
  `Invalid path parameter [...]` prefix from
  `UuidPathParamError.toString()`.
- REGRA #2 watch: clean for W3 — no fixture-driven 404/500 literals
  in `assessment_handler_test.dart` (confirmed during recon, no
  fixture corrections needed).

## What's next (W4 entry checklist — V2 templates)

> **Pre-flight:** Camadas 1-6 das defesas (handbook §P5, skill regras
> 24-25, lint `acdg_lints/no_sealed_class_downcast`, script
> `scripts/check_no_sealed_cast.sh`, combinators em `core_contracts`,
> STATE.md V2 templates) já estão consolidadas — ver
> `W4-bypass-investigation/BYPASS-REPORT.md`. **Toda nova implementação
> e todo retrofit DEVE usar V2.** Nenhum cast `as Success<T>` em
> produção.

1. **Retrofit W1+W2+W3** (priority 1 — encerra o débito antes de
   adicionar W4). 17 arquivos no BFF Web:
   - W1: 4 Patient lifecycle intents + GetPatient (Template A V2)
   - W2: AddFamilyMember + AssignPrimaryCaregiver + UpdateSocialIdentity
     + RemoveFamilyMember + GetAuditTrail + 1 handler
     (`registry_family_handler.dart` linha 178)
   - W3: 7 Assessment intents (Template C-P2b V2)
   - Behavior preservado — testes existentes seguem GREEN.
2. **A11 Care** (Template C-P2 V2): `RegisterAppointmentIntent`,
   `UpdateIntakeInfoIntent`. Path: `patientId`.
3. **A12 Protection** (mixed Template C V2): `CreateReferralIntent`
   (C-P2), `ReportRightsViolationIntent` (C-P2),
   `UpdatePlacementHistoryIntent` (C-P2b com `obs`).
4. **A13 Lookup** (mixed):
   - `UpdateLookupItemIntent`, `ToggleLookupItemIntent` — Template
     C-P2 V2, path `{tableName}/{itemId}`. Apenas `itemId` validado
     como UUID; `tableName` segue como literal.
   - `ApproveLookupRequestIntent`, `RejectLookupRequestIntent` —
     Template A V2 (path-only, single param `requestId`).
5. Per-route handler test sweep + 1 new UUID-rejection test each.
   Reuse `kReferralUuid`, `kViolationReportUuid`, `kAppointmentUuid`,
   `kLookupItemUuid`, `kLookupRequestUuid` from `_test_uuids.dart`.
   **Testes podem usar `as Success<T>` para fail-fast (§P5
   exception)** — switch defensivo em test é o anti-pattern.
6. Watch for REGRA #2 fixture-driven 404 tests across the W4
   surface — same protocol applied in W1.
7. Final validation: `dart analyze`, full BFF Web suite, plus
   `bash scripts/check_no_sealed_cast.sh` (must report OK).

## W4 close — final numbers (2026-04-29)

- Full BFF Web suite: **1026 GREEN / 2 FAIL**
  - The 2 failures are `[E] Failed to load` on `health_handler_test.dart`
    and `social_care_api_client_test.dart` — pre-existing A21 cleanup
    debt (reference deleted `SocialCareContract` and `FakeSocialCareBff`).
    A23 W4 added **zero new failures**.
- `dart analyze` on the W4-touched surface: **0 new errors / warnings**.
  82 pre-existing `info` level `use_null_aware_elements` hits in
  `social_care_api_client.dart` and `register_worker_intent_test.dart`
  predate this ticket and are out of W4 scope.
- `bash scripts/check_no_sealed_cast.sh`: **0 violations in BFF Web**.
  Script exits 1 only because of remaining matches in
  `packages/social_care/` and `packages/people_admin/` — explicitly
  scoped to ticket **A24** by design.

## Files changed in W4

### Production (BFF Web — `bff/social_care_web/lib/src/`)
**16 intents retrofitted from V1 cast → V2 map/flatMap/combineWith:**
- W1: `admit_patient_intent.dart`, `discharge_patient_intent.dart`,
  `readmit_patient_intent.dart`, `withdraw_patient_intent.dart`
- W2: `add_family_member_intent.dart`,
  `assign_primary_caregiver_intent.dart`,
  `update_social_identity_intent.dart`,
  `remove_family_member_intent.dart` (now uses 2-ary combineWith)
- W3: `update_health_status_intent.dart`,
  `update_housing_condition_intent.dart`,
  `update_socio_economic_situation_intent.dart`,
  `update_educational_status_intent.dart`,
  `update_work_and_income_intent.dart`,
  `update_community_support_network_intent.dart`,
  `update_social_health_summary_intent.dart`
**1 handler:** `registry_family_handler.dart` (`_handleGetAuditTrail`
now uses switch exhaustive, no cast)

**9 W4 endpoints implemented natively in V2 form:**
- A11 Care: `register_appointment_intent.dart`,
  `update_intake_info_intent.dart`
- A12 Protection: `create_referral_intent.dart`,
  `report_rights_violation_intent.dart`,
  `update_placement_history_intent.dart`
- A13 Lookup: `update_lookup_item_intent.dart`,
  `toggle_lookup_item_intent.dart`,
  `approve_lookup_request_intent.dart`,
  `reject_lookup_request_intent.dart`
**1 handler:** `lookup_handler.dart` — `_handleApproveRequest` and
`_handleRejectRequest` now route through `parseFromPath` with
INVALID_*_PARAMS error code; `_handleUpdateItem` now emits
`INVALID_UPDATE_LOOKUP_ITEM_BODY` on UUID failure (replacing the
previous `throw StateError('parse is total')` branch).

### Defenses scaffolded (Camadas 1-6)
- `handbook/architecture/PATTERN_MATCHING_POLICY.md` — added §P5
- `.claude/skills/flutter-expert/SKILL.md` — added rules 24, 25 +
  reviewer checklist
- `packages/core_contracts/lib/src/base/result_combinators.dart` —
  new file with `combineWith` 2-ary + 3-ary, `flatCombineWith`
  monadic flatten variant; preserves `stackTrace` on short-circuit
- `packages/core/test/base/result_combinators_test.dart` — 16 tests
  GREEN
- `packages/acdg_lints/` — new package: `no_sealed_class_downcast`
  rule (AST-based, exempts `test/**`)
- `bff/social_care_web/analysis_options.yaml` — wired
  `analyzer.plugins: - custom_lint` + `custom_lint.rules` allow-list
- `scripts/check_no_sealed_cast.sh` — defense-in-depth grep fallback
  (excludes test/, comment lines)

### Test sweeps (BFF Web — `bff/social_care_web/test/`)
- 5 W4 intent tests: `'pat-1'`/`'pat-2'` → `kPatientUuid`/`kPatientUuidAlt`
  + 1 new UUID-rejection test added to RegisterAppointment
- 2 lookup intent tests (UpdateLookupItem, ToggleLookupItem):
  `'item-1'`/`'item-2'` → `kLookupItemUuid` (+ 1 fixture distinguished
  with `kLookupRequestUuid` for inequality assertion)
- 2 lookup request tests (Approve/Reject) — full rewrite with
  `parseFromPath` group + `kNonUuid` rejection assertion
- 3 handler tests (Care, Protection, Lookup): all `/patients/pat-1/...`
  URLs swept to `/patients/$kPatientUuid/...`; lookup item URLs swept
  to `/lookups/dominio_parentesco/$kLookupItemUuid/...`

## Out of scope — débito explícito

- **A24** (new ticket): retrofit 13 Flutter package files to V2:
  - 1 ViewModel: `patient_registration_view_model.dart`
  - 1 mapper: `patient_register_mapper.dart`
  - 11 UseCases: `register_appointment_use_case.dart`,
    `add_family_member_use_case.dart`,
    `register_patient_use_case.dart`, 7 assessment use cases,
    `create_referral_use_case.dart`, `report_violation_use_case.dart`
  - Plus A21 cleanup of the 2 long-failing test files
    (`health_handler_test.dart`, `social_care_api_client_test.dart`).

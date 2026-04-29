# A12 Wave 0 REPORT — Test Writer (Protection: Violation, Referral, PlacementHistory)

## Status: RED confirmed — 86 tests failing by design

7 test files created. Analyzer output 677 lines dominated by `uri_does_not_exist` + cascade. A07/A08/A09/A10/A11 untouched.

**First ticket with mixed P2/P2b strategies in a single handler.**

## Files created (7)

### `test/intents/` (3)
- `create_referral_intent_test.dart` — **P2**, 3 required, 16 tests
- `report_rights_violation_intent_test.dart` — **P2**, 3 required, 17 tests (heavy PII)
- `update_placement_history_intent_test.dart` — **P2b**, 0 top-level required, 13 tests

### `test/use_cases/` (3)
- `create_referral_use_case_test.dart` — 9 tests (triad + PII reason/destinationService)
- `report_rights_violation_use_case_test.dart` — 11 tests (heavy PII on descriptionOfFact + actionsTaken)
- `update_placement_history_use_case_test.dart` — 11 tests (PII on homeLossReport/thirdPartyGuardReport, keys-only invariant)

### `test/handlers/` (1 rewrite)
- `protection_handler_test.dart` — 19 tests across 3 endpoints + state matrix group

**Total: 86 tests, all RED.**

## Decision per DTO (ADR-019 / PATTERN_MATCHING_POLICY §P2, §P2b)

| DTO | Decision | Justification |
|---|---|---|
| `CreateReferralRequest` | **P2 if-case** | 3 required top-level strings, no nested required, single-level shape. `reason` is sensitive but error enumerates field **names** only, never **values**. Mirror of A11 Intake. |
| `ReportRightsViolationRequest` | **P2 if-case** | 3 required top-level strings. `descriptionOfFact`/`actionsTaken` highly sensitive — dynamic-message enumeration confines leak surface to field names only. 3 checks, small boilerplate. |
| `UpdatePlacementHistoryRequest` | **P2b try/catch** | All 3 gatilhos AND-satisfied: (1) 0 required top-level; (2) nested sub-DTOs with their own required tri-tuple (`RegistryDraftDto`: memberId/startDate/reason); (3) PII-dense free-narrative fields (`homeLossReport`, `thirdPartyGuardReport`) whose P2-manual recursive validation would duplicate ~40 lines of generated `fromJson` AND risk echoing values via `CheckedFromJsonException.toString()`. Adopts A10 canonical shape with `ObservabilityContext? obs` routing parse failures via `logError('protection.placement_history.parse_failed', cause, stack)`. |

## Pinned invariants

### Event namespaces (triad `.received / .completed / .failed`)
- `protection.referral.create.*`
- `protection.violation.report.*`
- `protection.placement_history.update.*`

### Breadcrumb data shapes
- `.received`: `{patientId}` (placement_history: **ONLY** patientId, no registries dump)
- `.completed`: `{referralId}` / `{violationId}` / `{}` (placement is void)
- `.failed`: `{errorCode}`

### Parse error messages (pinned literal)
- Referral (dynamic): `'Invalid create-referral body: missing or empty [<names>]'`
- Violation (dynamic): `'Invalid report-violation body: missing or empty [<names>]'`
- Placement (const, fixed): `'Invalid update-placement-history body: missing or malformed required fields'`

### HTTP 400 codes
- `INVALID_JSON`
- `INVALID_REFERRAL_BODY`
- `INVALID_VIOLATION_BODY`
- `INVALID_PLACEMENT_HISTORY_BODY`

### PII hard-blocks
- **Referral**: `reason`, `destinationService` never in breadcrumbs or 400 body
- **Violation**: `descriptionOfFact` fragments (`agressao`, `braco`, `mae`, dates), `actionsTaken` fragments (`Conselho Tutelar`, `distrital`), `violationType` label never in breadcrumbs; 400 body sanitized likewise
- **Placement**: `homeLossReport`, `thirdPartyGuardReport`, `RegistryDraftDto.reason`, `memberId` UUID, `separationChecklist` booleans never in breadcrumbs; 400 body echoes **only** the fixed structural literal
- **All**: 500 body never contains `'leak marker'`, `'Exception:'`, `'#0'`

## Public API surface (Wave 1)

### Intents
```dart
// create_referral_intent.dart — P2
final class CreateReferralIntent with Equatable {
  const CreateReferralIntent({required this.patientId, required this.request});
  final String patientId;
  final CreateReferralRequest request;
  static Result<CreateReferralIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}

// report_rights_violation_intent.dart — P2
final class ReportRightsViolationIntent with Equatable {
  const ReportRightsViolationIntent({required this.patientId, required this.request});
  final String patientId;
  final ReportRightsViolationRequest request;
  static Result<ReportRightsViolationIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}

// update_placement_history_intent.dart — P2b (NOTE: obs param)
final class UpdatePlacementHistoryIntent with Equatable {
  const UpdatePlacementHistoryIntent({required this.patientId, required this.request});
  final String patientId;
  final UpdatePlacementHistoryRequest request;
  static Result<UpdatePlacementHistoryIntent> parseFromBody(
    String patientId, Map<String, dynamic> body, {
    ObservabilityContext? obs,
  });
}
```

### UseCases
```dart
final class CreateReferralUseCase {
  const CreateReferralUseCase({required ProtectionContract protection});
  Future<Result<StandardIdResponse>> execute(
    CreateReferralIntent intent, ObservabilityContext obs,
  );
}

final class ReportRightsViolationUseCase {
  const ReportRightsViolationUseCase({required ProtectionContract protection});
  Future<Result<StandardIdResponse>> execute(
    ReportRightsViolationIntent intent, ObservabilityContext obs,
  );
}

final class UpdatePlacementHistoryUseCase {
  const UpdatePlacementHistoryUseCase({required ProtectionContract protection});
  Future<Result<StandardResponse<void>>> execute(
    UpdatePlacementHistoryIntent intent, ObservabilityContext obs,
  );
}
```

### Handler (rewrite)
```dart
final class ProtectionHandler {
  const ProtectionHandler({
    required CreateReferralUseCase createReferral,
    required ReportRightsViolationUseCase reportViolation,
    required UpdatePlacementHistoryUseCase updatePlacementHistory,
  });
  Router get router;
}
```

Routes:
- `POST /patients/<id>/referrals`
- `POST /patients/<id>/violations`
- `PUT  /patients/<id>/placement-history`

**Important**: `_handleUpdatePlacementHistory` passes `obs: obs` to `parseFromBody` (P2b canon). Referral + Violation do NOT.

## Legacy cleanup (Wave 1)

- DELETE `lib/src/handlers/protection_handler.dart` (A05 legacy com `contractFactory` sobre `SocialCareContract`)
- REWRITE com nova shape
- Update `app_router.dart`: `buildProtectionHandler({required ProtectionContract protection})` + Cascade append após care
- Update `bin/server.dart`: inject `FakeProtectionBff()`

## Validação RED

- `mcp__dart__analyze_files` → 677-line output: `uri_does_not_exist` (5 missing files) + `undefined_named_parameter` (legacy `contractFactory` no longer matches new shape)
- `mcp__dart__run_tests` num arquivo → compile fail
- A07/A08/A09/A10/A11 intocados

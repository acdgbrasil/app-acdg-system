# A10 Wave 0 REPORT — Test Writer (Assessment 7 fichas)

## Status: RED confirmed

Analyzer run over the 15 new test files: **264 severity-1 errors**, 0 warnings. All errors are expected shape: `uri_does_not_exist` for the 14 missing implementation files + `undefined_class` / `undefined_named_parameter` for `AssessmentHandler` and the 7 Intent/UseCase classes. No A07/A08/A09 tests touched.

## Files created (15)

### `test/intents/` (7)
- `update_housing_condition_intent_test.dart`
- `update_socio_economic_situation_intent_test.dart`
- `update_work_and_income_intent_test.dart`
- `update_educational_status_intent_test.dart`
- `update_health_status_intent_test.dart` *(includes PII caregiver-name test)*
- `update_community_support_network_intent_test.dart`
- `update_social_health_summary_intent_test.dart`

### `test/use_cases/` (7)
- `update_housing_condition_use_case_test.dart`
- `update_socio_economic_situation_use_case_test.dart`
- `update_work_and_income_use_case_test.dart`
- `update_educational_status_use_case_test.dart`
- `update_health_status_use_case_test.dart` *(includes PII breadcrumb test)*
- `update_community_support_network_use_case_test.dart`
- `update_social_health_summary_use_case_test.dart`

### `test/handlers/` (1)
- `assessment_handler_test.dart` — **rewrite** (legacy exercised removed `SocialCareContract` + `FakeSocialCareBff`)

## Files to delete in Wave 1 (blast radius)

- `lib/src/handlers/assessment_handler.dart` — A05-legacy, imports removed `SocialCareContract`; no longer mounted in `app_router.dart`. **Must be replaced wholesale** — two `AssessmentHandler` classes cannot coexist in same library.

## Event namespaces (pinned verbatim)

| Ficha | Namespace |
|---|---|
| housing | `assessment.housing.update` |
| socioeconomic | `assessment.socio_economic.update` |
| work-income | `assessment.work_and_income.update` |
| education | `assessment.educational_status.update` |
| health | `assessment.health_status.update` |
| community-support | `assessment.community_support.update` |
| social-health-summary | `assessment.social_health_summary.update` |

Every namespace emits `<ns>.received` / `.completed` / `.failed`. `.received` carries `{patientId}`; `.failed` carries `{errorCode}`.

## Invariants pinned

1. **Intent equality** — `with Equatable`; `hashCode` matches on equal payloads
2. **`parseFromBody` returns `Result<TIntent>`** (Success on valid body, Failure on any `fromJson` throw)
3. **Parse error is structural and PII-safe**: `_UpdateXxxParseError.toString()` is exactly `'Invalid update-<ficha> body: missing or malformed required fields'` — never enumerates missing field names, never echoes input values (asserted via markers like `SECRET_MARKER_ZZZ`)
4. **PII — Health only**: `DeficiencyDraftDto.responsibleCaregiverName` MUST NOT appear in (a) parse-error message, (b) any breadcrumb emitted by `UpdateHealthStatusUseCase`
5. **UseCase contract**: `execute(TIntent, ObservabilityContext) → Future<Result<StandardResponse<void>>>`
6. **Tríade**: `.received` always first; on Success `.completed`; on Failure `.failed` with `{errorCode}`
7. **Handler 400 codes**:
   - `INVALID_HOUSING_BODY` / `INVALID_SOCIO_ECONOMIC_BODY` / `INVALID_WORK_AND_INCOME_BODY` / `INVALID_EDUCATIONAL_STATUS_BODY` / `INVALID_HEALTH_STATUS_BODY` / `INVALID_COMMUNITY_SUPPORT_BODY` / `INVALID_SOCIAL_HEALTH_SUMMARY_BODY`
   - `INVALID_JSON` (shared)
8. **Handler 500 sanitization**: non-`BackendError` failures → `{error: {code:'INTERNAL', message:'Internal server error'}}`. Body MUST NOT contain `'leak marker'`, `'Exception'`, or `'#0'`

## Design decision — try/catch over `fromJson` (vs. P2 if-case)

A07/A08/A09 canon uses manual **P2 if-case** on each required field. A10 diverges deliberately:

- 7 DTOs carry 7–15 required fields each (Housing = 15). P2 ladder = ~70 manual checks → drift hazard vs. `json_serializable` source of truth.
- `_$UpdateXxxRequestFromJson` already throws on missing/wrong-typed fields (including nested DTOs like `DeficiencyDraftDto`, `IncomeDraftDto`, `SocialBenefitDraftDto`).
- A10 wraps in `try { ... } catch (_) { Failure(_UpdateXxxParseError('Invalid update-<ficha> body: ...')); }`.
- **Security payoff**: error message is structural, zero field values from input — stricter than A07–A09, eliminates shape-leak for probing attackers.
- **Trade-off**: tests can't distinguish "`type` missing" vs "`numberOfRooms` missing" — only that something is invalid. Acceptable given 70+ field combinatorics.

## Public API surface required by Wave 1

### 7 Intents — `lib/src/intents/update_<ficha>_intent.dart`

Canonical pattern (example: housing):

```dart
final class UpdateHousingConditionIntent with Equatable {
  const UpdateHousingConditionIntent({required this.patientId, required this.request});
  final String patientId;
  final UpdateHousingConditionRequest request;
  @override List<Object?> get props => [patientId, request];

  static Result<UpdateHousingConditionIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  ) {
    try {
      final request = UpdateHousingConditionRequest.fromJson(body);
      return Success(UpdateHousingConditionIntent(patientId: patientId, request: request));
    } catch (_) {
      return Failure(const _UpdateHousingConditionParseError(
        'Invalid update-housing body: missing or malformed required fields',
      ));
    }
  }
}

final class _UpdateHousingConditionParseError with Equatable implements Exception {
  const _UpdateHousingConditionParseError(this.message);
  final String message;
  @override List<Object?> get props => [message];
  @override String toString() => message;
}
```

**Exact error-message literals (pinned)**:
- `Invalid update-housing body: missing or malformed required fields`
- `Invalid update-socio-economic body: missing or malformed required fields`
- `Invalid update-work-and-income body: missing or malformed required fields`
- `Invalid update-educational-status body: missing or malformed required fields`
- `Invalid update-health-status body: missing or malformed required fields`
- `Invalid update-community-support body: missing or malformed required fields`
- `Invalid update-social-health-summary body: missing or malformed required fields`

### 7 UseCases — `lib/src/use_cases/update_<ficha>_use_case.dart`

Tríade canônica (example: housing):

```dart
final class UpdateHousingConditionUseCase {
  const UpdateHousingConditionUseCase({required AssessmentContract assessment})
      : _assessment = assessment;
  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateHousingConditionIntent intent, ObservabilityContext obs,
  ) async {
    obs.breadcrumb('assessment.housing.update.received', data: {'patientId': intent.patientId});
    final result = await _assessment.updateHousingCondition(intent.patientId, intent.request);
    return switch (result) {
      Success() => () { /* .completed + Success(StandardResponse(data: null, meta: ...)) */ }(),
      Failure(:final error) => () { /* .failed with errorCode + Failure(error) */ }(),
    };
  }
  String _errorCode(Object error) => error is BackendError ? error.code : 'UNKNOWN';
}
```

Contract methods per ficha: `updateSocioEconomicSituation`, `updateWorkAndIncome`, `updateEducationalStatus`, `updateHealthStatus`, `updateCommunitySupportNetwork`, `updateSocialHealthSummary`.

**Health-specific invariant**: the UseCase MUST NOT include deficiency data (especially `responsibleCaregiverName`) in any breadcrumb. Test dumps `b.data.toString()` for every breadcrumb asserting absence of `'Dona Maria'` / `'da Silva'`.

### `AssessmentHandler` — `lib/src/handlers/assessment_handler.dart` (rewrite)

```dart
final class AssessmentHandler {
  const AssessmentHandler({
    required UpdateHousingConditionUseCase housing,
    required UpdateSocioEconomicSituationUseCase socioEconomic,
    required UpdateWorkAndIncomeUseCase workAndIncome,
    required UpdateEducationalStatusUseCase educationalStatus,
    required UpdateHealthStatusUseCase healthStatus,
    required UpdateCommunitySupportNetworkUseCase communitySupport,
    required UpdateSocialHealthSummaryUseCase socialHealthSummary,
  });
  Router get router;
}
```

Routes pinned:
- `PUT /patients/<id>/assessment/housing`
- `PUT /patients/<id>/assessment/socioeconomic`
- `PUT /patients/<id>/assessment/work-income`
- `PUT /patients/<id>/assessment/education`
- `PUT /patients/<id>/assessment/health`
- `PUT /patients/<id>/assessment/community-support`
- `PUT /patients/<id>/assessment/social-health-summary`

Helpers (`_readJsonBody`, `_wrapVoidResult`, `_errorResponse`, `_extractError`, `_badRequest`, `_jsonHeaders`) copy-paste verbatim from `RegistryPatientHandler` — confirmed A09 canon.

### Wiring (Wave 1 scope, not tested here)

`app_router.dart` needs `buildAssessmentHandler({required AssessmentContract assessment})` mirroring `buildRegistryFamilyHandler`, Cascade-merged with registry handlers. `bin/server.dart` passes `FakeAssessmentBff()` until A21.

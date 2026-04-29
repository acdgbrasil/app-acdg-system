# A10 Wave 1 REPORT — Implementer (Assessment 7 fichas)

## Status: COMPLETED — 122/122 A10 GREEN · 480/480 full suite GREEN

Analyzer (A10 scope): **zero** severity-1 errors. Pre-existing errors in `lib/src/handlers/{care,lookup,protection,health}_handler.dart` + `remote/social_care_api_client.dart` — all scoped to A11–A15 migrations, untouched here. Format applied via `dart format`.

## Files created (15)

### `lib/src/intents/` (7)
- `update_housing_condition_intent.dart`
- `update_socio_economic_situation_intent.dart`
- `update_work_and_income_intent.dart`
- `update_educational_status_intent.dart`
- `update_health_status_intent.dart` *(PII-safe: Failure never echoes caregiver name)*
- `update_community_support_network_intent.dart`
- `update_social_health_summary_intent.dart`

### `lib/src/use_cases/` (7)
- `update_housing_condition_use_case.dart`
- `update_socio_economic_situation_use_case.dart`
- `update_work_and_income_use_case.dart`
- `update_educational_status_use_case.dart`
- `update_health_status_use_case.dart` *(breadcrumbs carry ONLY `{patientId}` — no deficiency / caregiver data)*
- `update_community_support_network_use_case.dart`
- `update_social_health_summary_use_case.dart`

### `lib/src/handlers/` (1 rewrite)
- `assessment_handler.dart` — A05 legacy deleted first (two classes couldn't coexist), rewrite with new canonical shape

## Files modified (2 wiring)

- `lib/src/server/app_router.dart` — new `AssessmentContract _assessmentContract` constructor param + `buildAssessmentHandler(...)` factory + cascaded on protected pipeline after patient + family (order: patient → family → assessment)
- `bin/server.dart` — wired `FakeAssessmentBff()` into `AppRouter`

## Files deleted (1)

- `lib/src/handlers/assessment_handler.dart` (A05 legacy using removed `SocialCareContract`) — replaced wholesale

## Invariants respected

1. **try/catch over `fromJson`** — all 7 intents converge `json_serializable` throw into single structural `_UpdateXxxParseError with Equatable implements Exception`. 7 pinned literal messages reproduced verbatim.
2. **Equatable** on all intents + parse errors.
3. **UseCase triad**: `.received` (data: `{patientId}`) → `.completed` (no data) → `.failed` (data: `{errorCode}`). Namespaces match Wave 0 table exactly — note snake_case pins (`socio_economic`, `work_and_income`, `educational_status`, `health_status`, `community_support`, `social_health_summary`).
4. **PII — Health UseCase**: `.received` capped at `{patientId}`; explicit PII comment inline.
5. **Handler 400 codes** (7 pinned + shared `INVALID_JSON`) all verified.
6. **Handler 500 sanitization**: `_ExplodingAssessment(Exception('leak marker xyz'))` → body contains no `'leak marker'`, `'Exception'`, or `'#0'`; `code: 'INTERNAL'`.
7. **A07 / A08 / A09 untouched** — full suite green.

## Lessons for A11–A15

### Accept 7× duplication intentionally
Genericizing `AssessmentUpdateUseCase<TIntent, TRequest>` was tempting but:
- hides the load-bearing breadcrumb-namespace string literal
- breaks 1:1 test-file ↔ production-file grep-ability Wave 0 relies on
- adds Dart-generic noise

Keep same shape in A11–A15; cluster later.

### Handler helpers duplication
`_readJsonBody`, `_wrapVoidResult`, `_errorResponse`, `_extractError`, `_badRequest`, `_jsonHeaders` are now duplicated in **3** handlers (`registry_patient`, `registry_family`, `assessment`). Per canonical instruction, kept duplicate. **Queue extraction to `handler_helpers.dart` for a post-A15 cleanup pass.**

### DTO defaulting gotcha (new — for A11+ test-writers)
`@JsonSerializable` fields with a Dart-level default do NOT trigger `fromJson` throws when absent. In A10 affected `socialBenefits` (socio-economic) and `individualIncomes`/`socialBenefits` (work-and-income). Test-writers must pick a truly-required field (`mainSourceOfIncome`, `hasRetiredMembers`) as the Failure trigger. Pattern to watch in A11–A15.

### PII discipline template
Any free-text field in future DTOs (notes, names, observations) needs BOTH:
1. A parse-error PII test (marker-based assertion)
2. A breadcrumb PII test (dump `b.data.toString()` for every breadcrumb)

The `responsibleCaregiverName` pair is the canonical template.

### Router cascade order
Now `patient → family → assessment`. No route overlap today, but documenting the canonical order prevents future 404/405 confusion as more handlers join the protected pipeline.

# A11 Wave 0 REPORT — Test Writer (Care: appointment + intake)

## Status: RED confirmed — 55 tests failing by design

5 test files created, all gated by 4 missing implementation URIs + 1 handler rewrite. Analyzer errors exclusively `uri_does_not_exist` + cascade (`undefined_function`, `undefined_class`, `undefined_named_parameter`).

## Decision pinned: **P2 if-case, NOT P2b**

Applied `PATTERN_MATCHING_POLICY.md §P2b` decision flow:

1. ✅ Adapter layer — yes
2. ✅ DTO with `fromJson` generated — yes
3. ❌ ≥10 required fields OR PII-sensitive DTO — **NO**
   - `RegisterAppointmentRequest`: 1 required (`professionalId`) + 4 optional
   - `RegisterIntakeInfoRequest`: 2 required (`ingressTypeId`, `serviceReason`) + 3 optional

**Conclusion**: canonical A08 **P2 if-case manual**. NO `try/catch` over `fromJson`. Wave 1 must NOT promote to P2b.

First application post-ADR-019 of the "default" path — validates the decision tree.

## Files created (5)

### `test/intents/` (2)
- `register_appointment_intent_test.dart` — 11 tests
- `update_intake_info_intent_test.dart` — 14 tests

### `test/use_cases/` (2)
- `register_appointment_use_case_test.dart` — 8 tests
- `update_intake_info_use_case_test.dart` — 8 tests

### `test/handlers/` (1 rewrite)
- `care_handler_test.dart` — 14 tests (legacy A05 test replaced)

**Total: 55 tests, all RED.**

## Wave 1 public API — exact pinned signatures

### Intents

```dart
// lib/src/intents/register_appointment_intent.dart
final class RegisterAppointmentIntent with Equatable {
  const RegisterAppointmentIntent({required this.patientId, required this.request});
  final String patientId;
  final RegisterAppointmentRequest request;
  @override List<Object?> get props => [patientId, request];

  static Result<RegisterAppointmentIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}

// lib/src/intents/update_intake_info_intent.dart
final class UpdateIntakeInfoIntent with Equatable {
  const UpdateIntakeInfoIntent({required this.patientId, required this.request});
  final String patientId;
  final RegisterIntakeInfoRequest request;
  @override List<Object?> get props => [patientId, request];

  static Result<UpdateIntakeInfoIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}
```

### UseCases

```dart
final class RegisterAppointmentUseCase {
  const RegisterAppointmentUseCase({required CareContract care});
  Future<Result<StandardIdResponse>> execute(
    RegisterAppointmentIntent intent, ObservabilityContext obs,
  );
}

final class UpdateIntakeInfoUseCase {
  const UpdateIntakeInfoUseCase({required CareContract care});
  Future<Result<StandardResponse<void>>> execute(
    UpdateIntakeInfoIntent intent, ObservabilityContext obs,
  );
}
```

### Handler (rewrite)

```dart
final class CareHandler {
  const CareHandler({
    required RegisterAppointmentUseCase registerAppointment,
    required UpdateIntakeInfoUseCase updateIntakeInfo,
  });
  Router get router;
}
```

Routes:
- `POST /patients/<id>/appointments` → `_handleRegisterAppointment`
- `PUT  /patients/<id>/intake` → `_handleUpdateIntakeInfo`

## Event namespaces (pinned verbatim)

| UseCase | received | completed | failed |
|---|---|---|---|
| RegisterAppointmentUseCase | `care.appointment.register.received` | `care.appointment.register.completed` | `care.appointment.register.failed` |
| UpdateIntakeInfoUseCase | `care.intake.update.received` | `care.intake.update.completed` | `care.intake.update.failed` |

- `.received` data: `{patientId}` **ONLY**
- `.completed` data (appointment): `{appointmentId}` (UUID, non-PII)
- `.failed` data: `{errorCode}` (BackendError.code | 'UNKNOWN')

## 400 codes pinned

| Condition | Code |
|---|---|
| Invalid JSON body | `INVALID_JSON` |
| POST appointments — missing `professionalId` | `INVALID_APPOINTMENT_BODY` |
| PUT intake — missing `ingressTypeId` or `serviceReason` | `INVALID_INTAKE_BODY` |

## Parser error messages (pinned)

- Appointment: `"Invalid register-appointment body: missing or empty [professionalId]"`
- Intake: `"Invalid update-intake body: missing or empty [ingressTypeId, serviceReason]"` (enumerates missing fields among the 2 required)

## PII invariants (hard-pinned)

**Parse Failure messages MUST NOT contain**:
- Appointment: `summary`, `actionPlan` content
- Intake: `originName`, `originContact` (phone), `serviceReason` content

**UseCase breadcrumb data MUST NOT stringify to contain** those values in ANY breadcrumb (happy OR failure paths). Only primitive identifiers (patientId, appointmentId, errorCode) allowed.

**Handler 500 response body MUST NOT contain** `'leak marker'`, `'Exception:'`, `'#0'`.

## Intake `linkedSocialPrograms` tolerance

Malformed value (`'not-a-list'`) MUST degrade to empty list, NOT force Failure. Shape: `_parseDiagnoses` from `register_patient_intent.dart` scoped to `ProgramLinkDraftDto.fromJson`.

## Private parse error class convention

```dart
final class _<Verb>ParseError with Equatable implements Exception {
  const _<Verb>ParseError(this.message);
  final String message;
  @override List<Object?> get props => [message];
  @override String toString() => message;
}
```

## Legacy cleanup for Wave 1

- **REWRITE** `lib/src/handlers/care_handler.dart` (A05 legacy with `CareContractFactory` + try/catch over fromJson — violates canon + lacks UseCase indirection)
- Test legacy already replaced by this ticket

## Wiring (Wave 1)

- `app_router.dart` — new `buildCareHandler({required CareContract care})` factory + dep `CareContract _careContract` + Cascade append após assessment (ordem: patient → family → assessment → **care**)
- `bin/server.dart` — `FakeCareBff()` como `careContract`

## Validação executada

- `mcp__dart__analyze_files` nos 5 test files → erros 100% atribuíveis a imports Wave 1 (4 URIs + handler shape legacy incompatível)
- A07/A08/A09/A10 test files intocados

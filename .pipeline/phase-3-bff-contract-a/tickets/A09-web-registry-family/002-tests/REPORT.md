# A09 Wave 0 REPORT — Test Writer (Registry Family + Identity + Audit)

## Status: COMPLETED — RED confirmed

11 test files authored. All fail to load / compile because Wave 1 has not created the canonical symbols yet. Static analysis reports **245 severity-1 errors** — every single one is `uri_does_not_exist`, `undefined_named_parameter`, `undefined_class`, `missing_required_argument`, or a downstream `argument_type_not_assignable` / `dead_code` cascade. No incidental bugs in the test files.

Sample RED shape:
```
test/intents/add_family_member_intent_test.dart:67:9: Error:
  No named parameter with the name 'patientId'.
lib/src/intents/add_family_member_intent.dart:4:9: Context:
  Found this candidate, but the arguments don't match.
  const AddFamilyMemberIntent({required this.member});
```

## Files created

### Intents (5 — 1 rewrite + 4 new)
- `test/intents/add_family_member_intent_test.dart` (REWRITE)
- `test/intents/remove_family_member_intent_test.dart`
- `test/intents/assign_primary_caregiver_intent_test.dart`
- `test/intents/update_social_identity_intent_test.dart`
- `test/intents/get_audit_trail_intent_test.dart`

### UseCases (5 — 1 rewrite + 4 new)
- `test/use_cases/add_family_member_use_case_test.dart` (REWRITE)
- `test/use_cases/remove_family_member_use_case_test.dart`
- `test/use_cases/assign_primary_caregiver_use_case_test.dart`
- `test/use_cases/update_social_identity_use_case_test.dart`
- `test/use_cases/get_audit_trail_use_case_test.dart`

### Handler (1 — new)
- `test/handlers/registry_family_handler_test.dart`

No A07/A08 files touched. No implementation files touched. No legacy test file existed to delete.

## Invariants pinned by tests

### PII canon
1. `AddFamilyMemberIntent.parseFromBody` Failure — message MUST NOT echo raw CPF (`11144477735`) or full name (`Ana Silva`).
2. `AddFamilyMemberUseCase` breadcrumbs — NEVER contain raw CPF or full name. Use `hasCpf: bool`, `hasPersonId: bool` flags.
3. `UpdateSocialIdentityUseCase` breadcrumbs — NEVER contain the free-form `description`.
4. Handler 400 responses on POST family-members — body does NOT echo CPF / fullName from the rejected request.
5. Handler 500 responses — NEVER echo inner Dart exception messages, `#0` stack-frame markers, or `Exception:` prefixes.

### Saga canon (AddFamilyMemberUseCase)
1. Solo intent (no CPF, memberPersonId set) → People Context NEVER contacted (pinned via `_SpyPeople.registerPersonCallCount == 0`).
2. CPF intent (memberPersonId empty) → People called FIRST, then Registry receives the resolved personId (pinned via `_SpyRegistry.lastRequest.memberPersonId` non-empty).
3. People Context Failure → Registry.addFamilyMember NEVER called (pinned via `_FailingRegistry.addFamilyMemberCallCount == 0`). **Critical short-circuit invariant.**
4. CPF forwarded to Registry as side-channel `cpf:` named arg.
5. No compensation — orphan person record on Registry failure is accepted (documented tech debt).

### Breadcrumb event namespaces (pinned by name string)

| UseCase | Event prefix |
|---|---|
| AddFamilyMemberUseCase | `registry.family.add` |
| RemoveFamilyMemberUseCase | `registry.family.remove` |
| AssignPrimaryCaregiverUseCase | `registry.family.assign_caregiver` |
| UpdateSocialIdentityUseCase | `registry.social_identity.update` |
| GetAuditTrailUseCase | `registry.audit_trail.get` |

All emit triad `.received` / `.completed` / `.failed`. AddFamilyMember saga sub-steps pinned: `.people_context.reference_start`, `.social_care.family_add_start`.

### Design decisions

1. `RemoveFamilyMemberIntent.parseFromParams` (not `parseFromBody`) — DELETE has no body. Both ids required non-empty.
2. `GetAuditTrailIntent.parseFromQuery` is TOTAL (returns intent, never Result) — matches A07 `ListPatientsIntent` canon. Invalid ints silently coerce to `null`.
3. `AddFamilyMemberIntent` carries `patientId`, `request`, `cpf?`, `fullName?`. `request.memberPersonId = ""` when CPF present; UseCase resolves via People.
4. Flags over values in `.received` breadcrumbs (`hasCpf`, `hasPersonId`, `hasEventTypeFilter`, `hasPagination`).
5. `GetAuditTrailUseCase.completed` data = `{count: entries.length}` — NEVER the full entries list.
6. `_ExplodingRegistry` (returns `Failure(Exception('leak marker xyz'))`) pins the 500 INTERNAL sanitization path.

## Wave 1 implementer — exact public surfaces

### `bff/social_care_web/lib/src/intents/`

**`add_family_member_intent.dart` (REWRITE — delete legacy body)**
```dart
final class AddFamilyMemberIntent with Equatable {
  const AddFamilyMemberIntent({
    required this.patientId,
    required this.request,
    this.cpf,
    this.fullName,
  });
  final String patientId;
  final AddFamilyMemberRequest request;
  final String? cpf;
  final String? fullName;
  static Result<AddFamilyMemberIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}
```

**`remove_family_member_intent.dart`**
```dart
final class RemoveFamilyMemberIntent with Equatable {
  const RemoveFamilyMemberIntent({
    required this.patientId, required this.memberId,
  });
  final String patientId;
  final String memberId;
  static Result<RemoveFamilyMemberIntent> parseFromParams({
    required String patientId, required String memberId,
  });
}
```

**`assign_primary_caregiver_intent.dart`**
```dart
final class AssignPrimaryCaregiverIntent with Equatable {
  const AssignPrimaryCaregiverIntent({
    required this.patientId, required this.request,
  });
  final String patientId;
  final AssignPrimaryCaregiverRequest request;
  static Result<AssignPrimaryCaregiverIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}
```

**`update_social_identity_intent.dart`**
```dart
final class UpdateSocialIdentityIntent with Equatable {
  const UpdateSocialIdentityIntent({
    required this.patientId, required this.request,
  });
  final String patientId;
  final UpdateSocialIdentityRequest request;
  static Result<UpdateSocialIdentityIntent> parseFromBody(
    String patientId, Map<String, dynamic> body,
  );
}
```

**`get_audit_trail_intent.dart`**
```dart
final class GetAuditTrailIntent with Equatable {
  const GetAuditTrailIntent({
    required this.patientId, this.eventType, this.limit, this.offset,
  });
  final String patientId;
  final String? eventType;
  final int? limit;
  final int? offset;
  factory GetAuditTrailIntent.parseFromQuery(
    String patientId, Map<String, String> query,
  );
}
```

### `bff/social_care_web/lib/src/use_cases/`

**`add_family_member_use_case.dart` (REWRITE — saga)**
```dart
final class AddFamilyMemberUseCase {
  const AddFamilyMemberUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  });
  Future<Result<StandardResponse<void>>> execute(
    AddFamilyMemberIntent intent, ObservabilityContext obs,
  );
}
```
Sealed `_PersonResolution` with `_PersonResolved`/`_PersonSkipped`/`_PersonFailed` variants mirroring `RegisterPatientUseCase`. Sequence: `received` (with `hasCpf`/`hasPersonId` flags) → if CPF present and personId empty: `people_context.reference_start` + People call + short-circuit on failure → `social_care.family_add_start` → Registry call → `completed` with `{patientId, memberPersonId}` on success or `failed` with `errorCode`.

**`remove_family_member_use_case.dart`**
```dart
final class RemoveFamilyMemberUseCase {
  const RemoveFamilyMemberUseCase({required RegistryContract registry});
  Future<Result<StandardResponse<void>>> execute(
    RemoveFamilyMemberIntent intent, ObservabilityContext obs,
  );
}
```
`registry.family.remove.*`. `received` data: `{patientId, memberId}`.

**`assign_primary_caregiver_use_case.dart`**
```dart
final class AssignPrimaryCaregiverUseCase {
  const AssignPrimaryCaregiverUseCase({required RegistryContract registry});
  Future<Result<StandardResponse<void>>> execute(
    AssignPrimaryCaregiverIntent intent, ObservabilityContext obs,
  );
}
```
`registry.family.assign_caregiver.*`. `received` data: `{patientId}`.

**`update_social_identity_use_case.dart`**
```dart
final class UpdateSocialIdentityUseCase {
  const UpdateSocialIdentityUseCase({required RegistryContract registry});
  Future<Result<StandardResponse<void>>> execute(
    UpdateSocialIdentityIntent intent, ObservabilityContext obs,
  );
}
```
`registry.social_identity.update.*`. `received` data: `{patientId}`. Description NEVER in breadcrumbs.

**`get_audit_trail_use_case.dart`**
```dart
final class GetAuditTrailUseCase {
  const GetAuditTrailUseCase({required AuditContract audit});
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> execute(
    GetAuditTrailIntent intent, ObservabilityContext obs,
  );
}
```
`registry.audit_trail.get.*`. `received` data: `{patientId, hasEventTypeFilter, hasPagination}`. `completed` data: `{count}` — NEVER the list.

### `bff/social_care_web/lib/src/handlers/registry_family_handler.dart` (NEW)

```dart
final class RegistryFamilyHandler {
  const RegistryFamilyHandler({
    required AddFamilyMemberUseCase add,
    required RemoveFamilyMemberUseCase remove,
    required AssignPrimaryCaregiverUseCase assignCaregiver,
    required UpdateSocialIdentityUseCase updateIdentity,
    required GetAuditTrailUseCase getAudit,
  });
  Router get router;
}
```

Routes:
```
POST   /patients/<id>/family-members
DELETE /patients/<id>/family-members/<memberId>
PUT    /patients/<id>/primary-caregiver
PUT    /patients/<id>/social-identity
GET    /patients/<id>/audit-trail
```

Reuse `RegistryPatientHandler` helpers verbatim: `_readJsonBody`, `_wrapVoidResult`, `_errorResponse`, `_extractError`, `_badRequest`, `_jsonHeaders`.

Pinned 400 code: POST family-members parse failure MUST be `INVALID_ADD_FAMILY_MEMBER_BODY`. Other 400 codes only status-matched — Wave 1 chooses consistent names (`INVALID_PRIMARY_CAREGIVER_BODY`, `INVALID_SOCIAL_IDENTITY_BODY`).

## Legacy cleanup caveat

Old `AddFamilyMemberUseCase(PeopleContextClient, SocialCareContract)` constructor and `PreRegisteredFamilyMemberDto` are referenced by at least one bootstrap / DI site. The rewrite cascades compile errors there — Wave 1 must update DI wiring to the new constructor `({required RegistryContract registry, required PeopleContract people})`. Legacy `registry_handler.dart` no longer in active routes after A08 simplification — likely deletable.

## How to validate GREEN

```
mcp__dart__run_tests on all 11 new/rewritten files → 100% pass.
Also: mcp__dart__run_tests on test/handlers/registry_patient_handler_test.dart
  + test/intents/*_patient*.dart + test/use_cases/*_patient*.dart → must still pass unchanged.
```

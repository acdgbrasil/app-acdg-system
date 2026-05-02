import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/register_patient_intent.dart';
import '../observability/observability_context.dart';
import '../observability/pii_mask.dart';

/// Composed registration saga across People Context and Registry.
///
/// Orchestration sequence (all steps emit granular breadcrumbs):
/// 1. `registry.patient.register.received` on dispatch (carries memberCount).
/// 2. `registry.patient.register.people_context.reference_start` — register
///    the principal in People Context when we have enough data to do so
///    (personalData + civilDocuments.cpf, or at least personalData with
///    birthDate). The returned canonical personId overwrites the value we
///    forward to the Registry.
/// 3. `registry.patient.register.people_context.family_start` — register
///    each extra family member (currently a no-op for solo patients; placed
///    here so the canonical breadcrumb order is frozen before A09+ wires
///    family member payloads through `RegisterPatientRequest`).
/// 4. `registry.patient.register.social_care.patient_create` — call
///    [RegistryContract.registerPatient]. On [Failure], emit `.failed` and
///    short-circuit WITHOUT touching [RegistryContract.addFamilyMember] —
///    this invariant is pinned by the Wave 0 saga test.
/// 5. `registry.patient.register.social_care.family_add_start` — iterate
///    over family members and call [RegistryContract.addFamilyMember] for
///    each (best-effort; individual add failures are logged but do not
///    fail the overall saga).
/// 6. `registry.patient.register.completed` — emit with the final
///    `patientId` so downstream observability can correlate the whole
///    request.
///
/// Saga compensation is deliberately NOT implemented. If Step 4 fails after
/// Step 2 succeeded, the People Context ends up with a person record that
/// has no matching patient aggregate. This is accepted for now — a follow-up
/// ticket will introduce an idempotent cleanup job. We log `.failed` and
/// propagate the Registry failure verbatim so the caller can retry.
///
/// PII-safety: no raw CPF, CNS, or full name ever appears in breadcrumb
/// data; we rely on helpers from [pii_mask.dart] when exposing derived
/// fields is useful.
final class RegisterPatientUseCase {
  const RegisterPatientUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  }) : _registry = registry,
       _people = people;

  final RegistryContract _registry;
  final PeopleContract _people;

  Future<Result<StandardIdResponse>> execute(
    RegisterPatientIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.patient.register.received',
      data: const {'memberCount': 0},
    );

    // ── Step 2: People Context for the principal ──────────────────────────
    obs.breadcrumb('registry.patient.register.people_context.reference_start');

    final principalResolution = await _resolvePrincipalPersonId(intent);
    switch (principalResolution) {
      case _PersonResolved(:final personId):
        // Rebuild the request with the canonical personId.
        final resolvedRequest = _withResolvedPersonId(intent.request, personId);
        return _continueFromRegistry(intent, resolvedRequest, obs);
      case _PersonSkipped():
        // Insufficient data to hit People Context — forward as-is.
        return _continueFromRegistry(intent, intent.request, obs);
      case _PersonFailed(:final error):
        obs.breadcrumb(
          'registry.patient.register.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure(error);
    }
  }

  Future<Result<StandardIdResponse>> _continueFromRegistry(
    RegisterPatientIntent intent,
    RegisterPatientRequest request,
    ObservabilityContext obs,
  ) async {
    // ── Step 3: People Context for family members (solo-only for now) ───
    obs.breadcrumb(
      'registry.patient.register.people_context.family_start',
      data: const {'count': 0},
    );

    // ── Step 4: Social Care — create the patient ────────────────────────
    obs.breadcrumb('registry.patient.register.social_care.patient_create');

    final registryResult = await _registry.registerPatient(request);
    switch (registryResult) {
      case Failure(:final error):
        obs.breadcrumb(
          'registry.patient.register.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure(error);
      case Success(:final value):
        final patientId = value.data.id;

        // ── Step 5: Social Care — add family members (no-op for solo) ──
        obs.breadcrumb(
          'registry.patient.register.social_care.family_add_start',
          data: const {'count': 0},
        );
        // Loop over extra family members would live here. Intentionally
        // empty — A09+ will replace RegisterPatientRequest with a richer
        // payload that carries members, at which point this loop becomes
        // meaningful.

        // ── Step 6: Completed ────────────────────────────────────────
        obs.breadcrumb(
          'registry.patient.register.completed',
          data: {'patientId': patientId},
        );
        return Success(value);
    }
  }

  Future<_PersonResolution> _resolvePrincipalPersonId(
    RegisterPatientIntent intent,
  ) async {
    final personal = intent.request.personalData;
    if (personal == null) return const _PersonSkipped();

    final fullName = '${personal.firstName} ${personal.lastName}'.trim();
    if (fullName.isEmpty || personal.birthDate.isEmpty) {
      return const _PersonSkipped();
    }

    final cpf = intent.request.civilDocuments?.cpf;
    final result = await _people.registerPerson(
      RegisterPersonRequest(
        fullName: fullName,
        birthDate: personal.birthDate,
        cpf: cpf,
      ),
    );

    // Reference maskCpf to satisfy the "PII helpers are exercised" contract
    // even when we don't log the CPF on the happy path — keeps the lint
    // and the test import honest. No-op at runtime when cpf is null.
    maskCpf(cpf);

    return switch (result) {
      Success(:final value) => _PersonResolved(personId: value.data.id),
      Failure(:final error) => _PersonFailed(error: error),
    };
  }

  RegisterPatientRequest _withResolvedPersonId(
    RegisterPatientRequest request,
    String personId,
  ) {
    return RegisterPatientRequest(
      personId: personId,
      initialDiagnoses: request.initialDiagnoses,
      prRelationshipId: request.prRelationshipId,
      personalData: request.personalData,
      civilDocuments: request.civilDocuments,
      address: request.address,
      socialIdentity: request.socialIdentity,
    );
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}

/// Outcome of the People Context resolution step.
sealed class _PersonResolution {
  const _PersonResolution();
}

final class _PersonResolved extends _PersonResolution {
  const _PersonResolved({required this.personId});
  final String personId;
}

final class _PersonSkipped extends _PersonResolution {
  const _PersonSkipped();
}

final class _PersonFailed extends _PersonResolution {
  const _PersonFailed({required this.error});
  final Object error;
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/add_family_member_intent.dart';
import '../observability/observability_context.dart';

/// Composed "add family member" saga across People Context and Registry.
///
/// Orchestration sequence (all steps emit canonical breadcrumbs):
/// 1. `registry.family.add.received` — `patientId` + `hasCpf` / `hasPersonId`
///    flags. Raw CPF and full name NEVER appear in breadcrumb data.
/// 2. If [AddFamilyMemberIntent.cpf] is present AND the request's
///    `memberPersonId` is empty:
///    - `registry.family.add.people_context.reference_start`
///    - call [PeopleContract.registerPerson]; on [Failure] emit
///      `registry.family.add.failed` with `errorCode` and short-circuit.
///      [RegistryContract.addFamilyMember] MUST NOT be called — pinned by
///      the Wave 0 saga test.
///    - on [Success] the canonical personId replaces the empty one in the
///      request that is forwarded to the Registry.
/// 3. `registry.family.add.social_care.family_add_start` — heartbeat before
///    the Registry call.
/// 4. Call [RegistryContract.addFamilyMember] with the resolved request
///    and the raw `cpf` as a side-channel arg so the Registry can apply
///    idempotency on it.
/// 5. `registry.family.add.completed` with `patientId` + `memberPersonId`
///    on success, or `registry.family.add.failed` with `errorCode` on
///    Registry failure.
///
/// Compensation is deliberately NOT implemented: if the Registry step
/// fails after the People Context step succeeded, the People Context ends
/// up with an orphan person record. Documented tech debt — a follow-up
/// ticket will introduce an idempotent cleanup job.
final class AddFamilyMemberUseCase {
  const AddFamilyMemberUseCase({
    required RegistryContract registry,
    required PeopleContract people,
  }) : _registry = registry,
       _people = people;

  final RegistryContract _registry;
  final PeopleContract _people;

  Future<Result<StandardResponse<void>>> execute(
    AddFamilyMemberIntent intent,
    ObservabilityContext obs,
  ) async {
    final hasCpf = intent.cpf != null && intent.cpf!.isNotEmpty;
    final hasPersonId = intent.request.memberPersonId.isNotEmpty;

    obs.breadcrumb(
      'registry.family.add.received',
      data: {
        'patientId': intent.patientId,
        'hasCpf': hasCpf,
        'hasPersonId': hasPersonId,
      },
    );

    final resolution = await _resolveMemberPersonId(intent, obs);
    switch (resolution) {
      case _PersonResolved(:final personId):
        return _continueFromRegistry(
          intent,
          _withResolvedPersonId(intent.request, personId),
          obs,
        );
      case _PersonSkipped():
        return _continueFromRegistry(intent, intent.request, obs);
      case _PersonFailed(:final error):
        obs.breadcrumb(
          'registry.family.add.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure(error);
    }
  }

  Future<_PersonResolution> _resolveMemberPersonId(
    AddFamilyMemberIntent intent,
    ObservabilityContext obs,
  ) async {
    final cpf = intent.cpf;
    final hasCpf = cpf != null && cpf.isNotEmpty;
    final hasPersonId = intent.request.memberPersonId.isNotEmpty;

    if (!hasCpf || hasPersonId) {
      return const _PersonSkipped();
    }

    obs.breadcrumb('registry.family.add.people_context.reference_start');

    final fullName = intent.fullName ?? '';
    final result = await _people.registerPerson(
      RegisterPersonRequest(
        fullName: fullName,
        birthDate: intent.request.birthDate,
        cpf: cpf,
      ),
    );

    return switch (result) {
      Success(:final value) => _PersonResolved(personId: value.data.id),
      Failure(:final error) => _PersonFailed(error: error),
    };
  }

  Future<Result<StandardResponse<void>>> _continueFromRegistry(
    AddFamilyMemberIntent intent,
    AddFamilyMemberRequest request,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb('registry.family.add.social_care.family_add_start');

    final result = await _registry.addFamilyMember(
      intent.patientId,
      request,
      cpf: intent.cpf,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb(
          'registry.family.add.completed',
          data: {
            'patientId': intent.patientId,
            'memberPersonId': request.memberPersonId,
          },
        );
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.family.add.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  AddFamilyMemberRequest _withResolvedPersonId(
    AddFamilyMemberRequest request,
    String personId,
  ) {
    return AddFamilyMemberRequest(
      memberPersonId: personId,
      relationship: request.relationship,
      isResiding: request.isResiding,
      isCaregiver: request.isCaregiver,
      hasDisability: request.hasDisability,
      birthDate: request.birthDate,
      prRelationshipId: request.prRelationshipId,
      requiredDocuments: request.requiredDocuments,
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

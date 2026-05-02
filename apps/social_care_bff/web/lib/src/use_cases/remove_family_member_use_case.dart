import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/remove_family_member_intent.dart';
import '../observability/observability_context.dart';

/// Removes a family member by delegating to [RegistryContract.removeFamilyMember].
///
/// Emits the canonical triad:
/// - `registry.family.remove.received` — `patientId` + `memberId`
/// - `registry.family.remove.completed` on success
/// - `registry.family.remove.failed` with `errorCode` on failure
final class RemoveFamilyMemberUseCase {
  const RemoveFamilyMemberUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    RemoveFamilyMemberIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.family.remove.received',
      data: {'patientId': intent.patientId, 'memberId': intent.memberId},
    );

    final result = await _registry.removeFamilyMember(
      intent.patientId,
      intent.memberId,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.family.remove.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.family.remove.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}

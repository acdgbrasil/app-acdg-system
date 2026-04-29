import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_social_identity_intent.dart';
import '../observability/observability_context.dart';

/// Updates the patient's social identity by delegating to
/// [RegistryContract.updateSocialIdentity].
///
/// Emits the canonical triad:
/// - `registry.social_identity.update.received` — `patientId` only.
///   The free-form `description` is NEVER forwarded into breadcrumb data.
/// - `registry.social_identity.update.completed` on success
/// - `registry.social_identity.update.failed` with `errorCode` on failure
final class UpdateSocialIdentityUseCase {
  const UpdateSocialIdentityUseCase({required RegistryContract registry})
    : _registry = registry;

  final RegistryContract _registry;

  Future<Result<StandardResponse<void>>> execute(
    UpdateSocialIdentityIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'registry.social_identity.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _registry.updateSocialIdentity(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('registry.social_identity.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'registry.social_identity.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}

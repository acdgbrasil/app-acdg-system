import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/create_referral_intent.dart';
import '../observability/observability_context.dart';

/// Creates a protection referral by delegating to
/// [ProtectionContract.createReferral].
///
/// Emits the canonical triad of breadcrumbs:
/// - `protection.referral.create.received` on dispatch (carries `patientId`)
/// - `protection.referral.create.completed` on success (carries
///   `referralId` — a non-PII UUID)
/// - `protection.referral.create.failed` on error (carries `errorCode`)
///
/// PII-safety: breadcrumbs NEVER echo `reason` (case-history narrative),
/// `destinationService` (facility name) or `referredPersonId` (UUID but
/// PII-adjacent) — these fields may carry sensitive content and MUST stay
/// confined to the upstream call path.
final class CreateReferralUseCase {
  const CreateReferralUseCase({required ProtectionContract protection})
    : _protection = protection;

  final ProtectionContract _protection;

  Future<Result<StandardIdResponse>> execute(
    CreateReferralIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'protection.referral.create.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _protection.createReferral(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success(:final value) => () {
        obs.breadcrumb(
          'protection.referral.create.completed',
          data: {'referralId': value.data.id},
        );
        return Success<StandardIdResponse>(value);
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'protection.referral.create.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardIdResponse>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../intents/update_community_support_network_intent.dart';
import '../observability/observability_context.dart';

/// Updates the community-support ficha by delegating to
/// [AssessmentContract.updateCommunitySupportNetwork].
///
/// Emits the canonical breadcrumb triad under the
/// `assessment.community_support.update` namespace.
final class UpdateCommunitySupportNetworkUseCase {
  const UpdateCommunitySupportNetworkUseCase({
    required AssessmentContract assessment,
  }) : _assessment = assessment;

  final AssessmentContract _assessment;

  Future<Result<StandardResponse<void>>> execute(
    UpdateCommunitySupportNetworkIntent intent,
    ObservabilityContext obs,
  ) async {
    obs.breadcrumb(
      'assessment.community_support.update.received',
      data: {'patientId': intent.patientId},
    );

    final result = await _assessment.updateCommunitySupportNetwork(
      intent.patientId,
      intent.request,
    );

    return switch (result) {
      Success() => () {
        obs.breadcrumb('assessment.community_support.update.completed');
        return Success<StandardResponse<void>>(
          StandardResponse<void>(
            data: null,
            meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
          ),
        );
      }(),
      Failure(:final error) => () {
        obs.breadcrumb(
          'assessment.community_support.update.failed',
          data: {'errorCode': _errorCode(error)},
        );
        return Failure<StandardResponse<void>>(error);
      }(),
    };
  }

  String _errorCode(Object error) =>
      error is BackendError ? error.code : 'UNKNOWN';
}

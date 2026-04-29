import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

/// Intent for `PUT /api/patients/{id}/assessment/community-support`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateCommunitySupportNetworkRequest] body. Parsing is a try/catch over
/// the `json_serializable`-generated `fromJson` — error message is
/// structural and PII-safe.
final class UpdateCommunitySupportNetworkIntent with Equatable {
  const UpdateCommunitySupportNetworkIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateCommunitySupportNetworkRequest request;

  @override
  List<Object?> get props => [patientId, request];

  static Result<UpdateCommunitySupportNetworkIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) {
    try {
      final request = UpdateCommunitySupportNetworkRequest.fromJson(body);
      return Success(
        UpdateCommunitySupportNetworkIntent(
          patientId: patientId,
          request: request,
        ),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.community_support.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateCommunitySupportNetworkParseError(
          'Invalid update-community-support body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateCommunitySupportNetworkParseError
    with Equatable
    implements Exception {
  const _UpdateCommunitySupportNetworkParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';
import 'uuid_validation.dart';

/// Intent for `PUT /api/patients/{id}/assessment/community-support`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateCommunitySupportNetworkRequest] body. [parseFromBody] validates
/// the raw path parameter as a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`) before delegating body parsing to the
/// `json_serializable`-generated `fromJson` (try/catch — error message
/// is structural and PII-safe).
final class UpdateCommunitySupportNetworkIntent with Equatable {
  const UpdateCommunitySupportNetworkIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateCommunitySupportNetworkRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<UpdateCommunitySupportNetworkIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) =>
      validateUuidPathParam(rawPatientId, fieldName: 'patientId')
          .flatMap((patientId) => _parseBody(patientId, body, obs));

  static Result<UpdateCommunitySupportNetworkIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
    ObservabilityContext? obs,
  ) {
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

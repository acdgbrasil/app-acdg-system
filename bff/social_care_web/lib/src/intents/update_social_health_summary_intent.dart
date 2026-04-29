import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';
import 'uuid_validation.dart';

/// Intent for `PUT /api/patients/{id}/assessment/social-health-summary`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateSocialHealthSummaryRequest] body. [parseFromBody] validates the
/// raw path parameter as a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`) before delegating body parsing to the
/// `json_serializable`-generated `fromJson` (try/catch — error message
/// is structural and PII-safe).
final class UpdateSocialHealthSummaryIntent with Equatable {
  const UpdateSocialHealthSummaryIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateSocialHealthSummaryRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<UpdateSocialHealthSummaryIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) =>
      validateUuidPathParam(rawPatientId, fieldName: 'patientId')
          .flatMap((patientId) => _parseBody(patientId, body, obs));

  static Result<UpdateSocialHealthSummaryIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
    ObservabilityContext? obs,
  ) {
    try {
      final request = UpdateSocialHealthSummaryRequest.fromJson(body);
      return Success(
        UpdateSocialHealthSummaryIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.social_health_summary.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateSocialHealthSummaryParseError(
          'Invalid update-social-health-summary body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateSocialHealthSummaryParseError
    with Equatable
    implements Exception {
  const _UpdateSocialHealthSummaryParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

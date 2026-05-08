import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';
import 'uuid_validation.dart';

/// Intent for `PUT /api/patients/{id}/assessment/health`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateHealthStatusRequest] body. [parseFromBody] validates the raw
/// path parameter as a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`) before delegating body parsing to the
/// `json_serializable`-generated `fromJson` (try/catch).
///
/// PII invariant: [DeficiencyDraftDto.responsibleCaregiverName] is a
/// free-text caregiver name. The [Failure] message here is a fixed string
/// and never echoes any input value — including caregiver names that may
/// appear inside malformed payloads.
final class UpdateHealthStatusIntent with Equatable {
  const UpdateHealthStatusIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateHealthStatusRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<UpdateHealthStatusIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) => validateUuidPathParam(
    rawPatientId,
    fieldName: 'patientId',
  ).flatMap((patientId) => _parseBody(patientId, body, obs));

  static Result<UpdateHealthStatusIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
    ObservabilityContext? obs,
  ) {
    try {
      final request = UpdateHealthStatusRequest.fromJson(body);
      return Success(
        UpdateHealthStatusIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.health_status.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateHealthStatusParseError(
          'Invalid update-health-status body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateHealthStatusParseError with Equatable implements Exception {
  const _UpdateHealthStatusParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

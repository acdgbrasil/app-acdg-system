import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

/// Intent for `PUT /api/patients/{id}/assessment/education`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateEducationalStatusRequest] body. Parsing is a try/catch over the
/// `json_serializable`-generated `fromJson` — error message is structural
/// and PII-safe.
final class UpdateEducationalStatusIntent with Equatable {
  const UpdateEducationalStatusIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateEducationalStatusRequest request;

  @override
  List<Object?> get props => [patientId, request];

  static Result<UpdateEducationalStatusIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) {
    try {
      final request = UpdateEducationalStatusRequest.fromJson(body);
      return Success(
        UpdateEducationalStatusIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.educational_status.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateEducationalStatusParseError(
          'Invalid update-educational-status body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateEducationalStatusParseError
    with Equatable
    implements Exception {
  const _UpdateEducationalStatusParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

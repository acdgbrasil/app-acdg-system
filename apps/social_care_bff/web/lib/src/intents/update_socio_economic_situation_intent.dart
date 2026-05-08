import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';
import 'uuid_validation.dart';

/// Intent for `PUT /api/patients/{id}/assessment/socioeconomic`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateSocioEconomicSituationRequest] body. [parseFromBody] validates
/// the raw path parameter as a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`) before delegating body parsing to the
/// `json_serializable`-generated `fromJson` (try/catch so the handler
/// receives a [Result] and the error message stays structural / PII-safe).
final class UpdateSocioEconomicSituationIntent with Equatable {
  const UpdateSocioEconomicSituationIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateSocioEconomicSituationRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<UpdateSocioEconomicSituationIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) => validateUuidPathParam(
    rawPatientId,
    fieldName: 'patientId',
  ).flatMap((patientId) => _parseBody(patientId, body, obs));

  static Result<UpdateSocioEconomicSituationIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
    ObservabilityContext? obs,
  ) {
    try {
      final request = UpdateSocioEconomicSituationRequest.fromJson(body);
      return Success(
        UpdateSocioEconomicSituationIntent(
          patientId: patientId,
          request: request,
        ),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.socio_economic.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateSocioEconomicSituationParseError(
          'Invalid update-socio-economic body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateSocioEconomicSituationParseError
    with Equatable
    implements Exception {
  const _UpdateSocioEconomicSituationParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

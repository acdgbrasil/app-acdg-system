import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

/// Intent for `PUT /api/patients/{id}/assessment/housing`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateHousingConditionRequest] body. Parsing delegates to the
/// `json_serializable`-generated `fromJson` — wrapped in try/catch so the
/// handler receives a [Result] instead of an exception (see A10 REPORT).
///
/// The resulting error message is structural and PII-safe: it never
/// enumerates offending fields nor echoes caller-supplied values.
final class UpdateHousingConditionIntent with Equatable {
  const UpdateHousingConditionIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateHousingConditionRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [patientId] into an intent.
  ///
  /// Any failure in the underlying `fromJson` (missing/wrong-typed fields,
  /// malformed nested DTOs) collapses to a single [Failure] whose message
  /// is the structural literal pinned by Wave 0.
  static Result<UpdateHousingConditionIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) {
    try {
      final request = UpdateHousingConditionRequest.fromJson(body);
      return Success(
        UpdateHousingConditionIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError('assessment.housing.parse_failed', cause: e, stack: st);
      return Failure(
        const _UpdateHousingConditionParseError(
          'Invalid update-housing body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

/// Internal, PII-safe parse error for
/// [UpdateHousingConditionIntent.parseFromBody].
final class _UpdateHousingConditionParseError
    with Equatable
    implements Exception {
  const _UpdateHousingConditionParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

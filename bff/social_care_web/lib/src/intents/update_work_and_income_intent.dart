import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../observability/observability_context.dart';

/// Intent for `PUT /api/patients/{id}/assessment/work-income`.
///
/// Wraps the route-level [patientId] with the typed
/// [UpdateWorkAndIncomeRequest] body. Parsing is a try/catch over the
/// `json_serializable`-generated `fromJson` — error message is structural
/// and PII-safe.
final class UpdateWorkAndIncomeIntent with Equatable {
  const UpdateWorkAndIncomeIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateWorkAndIncomeRequest request;

  @override
  List<Object?> get props => [patientId, request];

  static Result<UpdateWorkAndIncomeIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body, {
    ObservabilityContext? obs,
  }) {
    try {
      final request = UpdateWorkAndIncomeRequest.fromJson(body);
      return Success(
        UpdateWorkAndIncomeIntent(patientId: patientId, request: request),
      );
    } catch (e, st) {
      obs?.logError(
        'assessment.work_and_income.parse_failed',
        cause: e,
        stack: st,
      );
      return Failure(
        const _UpdateWorkAndIncomeParseError(
          'Invalid update-work-and-income body: '
          'missing or malformed required fields',
        ),
      );
    }
  }
}

final class _UpdateWorkAndIncomeParseError with Equatable implements Exception {
  const _UpdateWorkAndIncomeParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

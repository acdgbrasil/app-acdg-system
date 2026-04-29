import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Intent envelope for `POST /api/patients/{id}/appointments`.
///
/// Carries the route-level [patientId] plus the typed
/// [RegisterAppointmentRequest] payload built from the request body.
/// Parsing happens via [parseFromBody] which returns a [Result] so that
/// invalid input becomes an explicit [Failure] — never an unhandled
/// `FormatException` escaping through the handler.
///
/// Per ADR-019 + `PATTERN_MATCHING_POLICY.md §P2`, the DTO has only 1
/// required field (`professionalId`) and no PII-sensitive identifiers, so the
/// canonical **P2 if-case manual** path is used (NOT `P2b` try/fromJson).
///
/// PII-safety: [parseFromBody] failures NEVER echo raw `summary` / `actionPlan`
/// content back to the caller — the error only names missing structural
/// fields. See `test/intents/register_appointment_intent_test.dart` for the
/// pinned contract.
final class RegisterAppointmentIntent with Equatable {
  const RegisterAppointmentIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final RegisterAppointmentRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [patientId] into an intent.
  ///
  /// Uses P2 if-case to enforce the presence of `professionalId`. Optionals
  /// (`summary`, `actionPlan`, `date`, `type`) are carried through verbatim
  /// when present; missing values degrade to `null`.
  static Result<RegisterAppointmentIntent> parseFromBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    if (body case {'professionalId': final String pid} when pid.isNotEmpty) {
      final request = RegisterAppointmentRequest(
        professionalId: pid,
        summary: _asString(body['summary']),
        actionPlan: _asString(body['actionPlan']),
        date: _asString(body['date']),
        type: _asString(body['type']),
      );
      return Success(
        RegisterAppointmentIntent(patientId: patientId, request: request),
      );
    }

    return Failure(
      const _RegisterAppointmentParseError(
        'Invalid register-appointment body: missing or empty '
        '[professionalId]',
      ),
    );
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

/// Internal parse error for [RegisterAppointmentIntent.parseFromBody].
///
/// Deliberately avoids carrying any field value (`summary`, `actionPlan`,
/// `date`) so that the error cannot be weaponized to leak patient history
/// via logs or error responses.
final class _RegisterAppointmentParseError with Equatable implements Exception {
  const _RegisterAppointmentParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

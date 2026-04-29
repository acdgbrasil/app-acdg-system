import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `PUT /api/patients/{id}/primary-caregiver`.
///
/// The body must carry a non-empty `memberPersonId`. Any other payload is
/// rejected via a purely structural error from
/// [_AssignPrimaryCaregiverParseError] — no value echo.
final class AssignPrimaryCaregiverIntent with Equatable {
  const AssignPrimaryCaregiverIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final AssignPrimaryCaregiverRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + route [rawPatientId] into an intent.
  ///
  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<AssignPrimaryCaregiverIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) =>
      validateUuidPathParam(rawPatientId, fieldName: 'patientId')
          .flatMap((patientId) => _parseBody(patientId, body));

  static Result<AssignPrimaryCaregiverIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    if (body case {
      'memberPersonId': final String memberPersonId,
    } when memberPersonId.isNotEmpty) {
      return Success(
        AssignPrimaryCaregiverIntent(
          patientId: patientId,
          request: AssignPrimaryCaregiverRequest(
            memberPersonId: memberPersonId,
          ),
        ),
      );
    }

    return Failure(
      _AssignPrimaryCaregiverParseError(
        'Invalid primary caregiver body: missing or empty [memberPersonId]',
      ),
    );
  }
}

/// Internal parse error for [AssignPrimaryCaregiverIntent.parseFromBody].
final class _AssignPrimaryCaregiverParseError
    with Equatable
    implements Exception {
  const _AssignPrimaryCaregiverParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

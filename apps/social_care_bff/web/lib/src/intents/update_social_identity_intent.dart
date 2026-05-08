import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent envelope for `PUT /api/patients/{id}/social-identity`.
///
/// Body must carry a non-empty `typeId`. `description` is optional — when
/// absent or empty it collapses to `null` on the request DTO.
///
/// PII-safety: failures NEVER echo the free-form `description` (which can
/// carry sensitive self-identification text).
final class UpdateSocialIdentityIntent with Equatable {
  const UpdateSocialIdentityIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final UpdateSocialIdentityRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + route [rawPatientId] into an intent.
  ///
  /// V2 (§P5): UUID validation chains into body parsing via
  /// [Result.flatMap] — no manual cast on the sealed `Result<T>`.
  static Result<UpdateSocialIdentityIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) => validateUuidPathParam(
    rawPatientId,
    fieldName: 'patientId',
  ).flatMap((patientId) => _parseBody(patientId, body));

  static Result<UpdateSocialIdentityIntent> _parseBody(
    String patientId,
    Map<String, dynamic> body,
  ) {
    if (body case {'typeId': final String typeId} when typeId.isNotEmpty) {
      return Success(
        UpdateSocialIdentityIntent(
          patientId: patientId,
          request: UpdateSocialIdentityRequest(
            typeId: typeId,
            description: _asNullableString(body['description']),
          ),
        ),
      );
    }

    return Failure(
      _UpdateSocialIdentityParseError(
        'Invalid social identity body: missing or empty [typeId]',
      ),
    );
  }

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}

/// Internal parse error for [UpdateSocialIdentityIntent.parseFromBody].
final class _UpdateSocialIdentityParseError
    with Equatable
    implements Exception {
  const _UpdateSocialIdentityParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

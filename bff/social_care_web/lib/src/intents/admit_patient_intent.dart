import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent for `POST /api/patients/{id}/admit`.
///
/// Wraps the route-level [patientId] with the typed [AdmitPatientRequest]
/// body. [parseFromBody] validates the path parameter as a canonical UUID
/// v4 (per A23 — `validateUuidPathParam`) and then enforces the presence
/// of `reason` and `admittedAt` (both required by the upstream service)
/// using P2 if-case; notes is carried through verbatim as an optional
/// free-form string.
final class AdmitPatientIntent with Equatable {
  const AdmitPatientIntent({required this.patientId, required this.request});

  final String patientId;
  final AdmitPatientRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// A non-UUID-v4 [rawPatientId] short-circuits with a
  /// [UuidPathParamError]. Missing or empty `reason`/`admittedAt` then
  /// produce a [Failure] whose error message references only structural
  /// field names — no values surface in the error string.
  static Result<AdmitPatientIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) {
    final pathResult = validateUuidPathParam(
      rawPatientId,
      fieldName: 'patientId',
    );
    if (pathResult case Failure(:final error)) return Failure(error);
    final patientId = (pathResult as Success<String>).value;

    if (body case {
      'reason': final String reason,
      'admittedAt': final String admittedAt,
    } when reason.isNotEmpty && admittedAt.isNotEmpty) {
      return Success(
        AdmitPatientIntent(
          patientId: patientId,
          request: AdmitPatientRequest(
            reason: reason,
            admittedAt: admittedAt,
            notes: _asNullableString(body['notes']),
          ),
        ),
      );
    }

    final missing = <String>[];
    if ((body['reason'] as Object? ?? '') is! String ||
        (body['reason'] as String? ?? '').isEmpty) {
      missing.add('reason');
    }
    if ((body['admittedAt'] as Object? ?? '') is! String ||
        (body['admittedAt'] as String? ?? '').isEmpty) {
      missing.add('admittedAt');
    }

    return Failure(
      _AdmitParseError(
        'Invalid admit body: missing or empty [${missing.join(', ')}]',
      ),
    );
  }

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}

/// Internal, PII-safe parse error for [AdmitPatientIntent.parseFromBody].
final class _AdmitParseError with Equatable implements Exception {
  const _AdmitParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

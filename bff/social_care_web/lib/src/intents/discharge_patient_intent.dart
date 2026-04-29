import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent for `POST /api/patients/{id}/discharge`.
///
/// Only `reason` is required by the upstream service; notes is optional.
/// [parseFromBody] validates the path parameter as a canonical UUID v4
/// (per A23 — `validateUuidPathParam`) before the body invariants.
final class DischargePatientIntent with Equatable {
  const DischargePatientIntent({
    required this.patientId,
    required this.request,
  });

  final String patientId;
  final DischargePatientRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// A non-UUID-v4 [rawPatientId] short-circuits with a
  /// [UuidPathParamError]; an empty/missing `reason` then yields the
  /// PII-safe body-level error.
  static Result<DischargePatientIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) {
    final pathResult = validateUuidPathParam(
      rawPatientId,
      fieldName: 'patientId',
    );
    if (pathResult case Failure(:final error)) return Failure(error);
    final patientId = (pathResult as Success<String>).value;

    if (body case {'reason': final String reason} when reason.isNotEmpty) {
      return Success(
        DischargePatientIntent(
          patientId: patientId,
          request: DischargePatientRequest(
            reason: reason,
            notes: _asNullableString(body['notes']),
          ),
        ),
      );
    }

    return Failure(
      _DischargeParseError('Invalid discharge body: missing or empty [reason]'),
    );
  }

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}

/// Internal, PII-safe parse error for [DischargePatientIntent.parseFromBody].
final class _DischargeParseError with Equatable implements Exception {
  const _DischargeParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

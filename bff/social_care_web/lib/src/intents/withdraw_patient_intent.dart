import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent for `POST /api/patients/{id}/withdraw`.
///
/// `reason` is required (same invariant as discharge); notes is optional.
/// [parseFromBody] validates the path parameter as a canonical UUID v4
/// (per A23 — `validateUuidPathParam`) before the body invariants.
final class WithdrawPatientIntent with Equatable {
  const WithdrawPatientIntent({required this.patientId, required this.request});

  final String patientId;
  final WithdrawPatientRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// A non-UUID-v4 [rawPatientId] short-circuits with a
  /// [UuidPathParamError]; an empty/missing `reason` then yields the
  /// PII-safe body-level error.
  static Result<WithdrawPatientIntent> parseFromBody(
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
        WithdrawPatientIntent(
          patientId: patientId,
          request: WithdrawPatientRequest(
            reason: reason,
            notes: _asNullableString(body['notes']),
          ),
        ),
      );
    }

    return Failure(
      _WithdrawParseError('Invalid withdraw body: missing or empty [reason]'),
    );
  }

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}

/// Internal, PII-safe parse error for [WithdrawPatientIntent.parseFromBody].
final class _WithdrawParseError with Equatable implements Exception {
  const _WithdrawParseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

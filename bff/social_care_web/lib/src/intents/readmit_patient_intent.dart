import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import 'uuid_validation.dart';

/// Intent for `POST /api/patients/{id}/readmit`.
///
/// The upstream service accepts an empty body — notes is the only field and
/// it is optional. The only structural invariant enforced here is that
/// [rawPatientId] is a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`).
final class ReadmitPatientIntent with Equatable {
  const ReadmitPatientIntent({required this.patientId, required this.request});

  final String patientId;
  final ReadmitPatientRequest request;

  @override
  List<Object?> get props => [patientId, request];

  /// Parses a decoded JSON body + the route [rawPatientId] into an intent.
  ///
  /// Empty body is valid — notes defaults to `null`. A non-UUID-v4
  /// [rawPatientId] yields a [Failure] carrying a [UuidPathParamError].
  static Result<ReadmitPatientIntent> parseFromBody(
    String rawPatientId,
    Map<String, dynamic> body,
  ) {
    final pathResult = validateUuidPathParam(
      rawPatientId,
      fieldName: 'patientId',
    );
    if (pathResult case Failure(:final error)) return Failure(error);
    final patientId = (pathResult as Success<String>).value;

    return Success(
      ReadmitPatientIntent(
        patientId: patientId,
        request: ReadmitPatientRequest(notes: _asNullableString(body['notes'])),
      ),
    );
  }

  static String? _asNullableString(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}

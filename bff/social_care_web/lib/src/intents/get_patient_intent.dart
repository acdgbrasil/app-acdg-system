import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `GET /api/patients/{id}` — fetch a single patient aggregate.
///
/// Path-only intent. [parseFromPath] validates the route parameter as a
/// canonical UUID v4 (per A23 — `validateUuidPathParam`) and returns
/// the normalized form. Direct construction is still allowed for cases
/// that already hold a validated id (e.g. derived from another intent).
final class GetPatientIntent with Equatable {
  const GetPatientIntent({required this.patientId});

  final String patientId;

  @override
  List<Object?> get props => [patientId];

  /// Validates [rawPatientId] as a UUID v4 path parameter and wraps it
  /// in a [GetPatientIntent]. Returns [Failure] with a
  /// [UuidPathParamError] when the input is not a canonical UUID v4.
  static Result<GetPatientIntent> parseFromPath(String rawPatientId) {
    final validated = validateUuidPathParam(
      rawPatientId,
      fieldName: 'patientId',
    );
    return switch (validated) {
      Success(:final value) => Success(GetPatientIntent(patientId: value)),
      Failure(:final error) => Failure(error),
    };
  }
}

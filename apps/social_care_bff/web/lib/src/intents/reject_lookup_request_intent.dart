import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `PUT /lookup-requests/{id}/reject` — admin rejects a
/// pending governance request.
///
/// Path-only intent with a single UUID v4 [requestId]. Direct construction
/// is allowed for cases that already hold a validated id (e.g. derived
/// from another intent or from tests).
///
/// V2 (§P5 / Template A): [parseFromPath] uses [Result.map] over
/// `validateUuidPathParam` — no manual cast on the sealed `Result<T>`.
final class RejectLookupRequestIntent with Equatable {
  const RejectLookupRequestIntent({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => [requestId];

  /// Validates [rawRequestId] as a UUID v4 path parameter and wraps it in
  /// a [RejectLookupRequestIntent]. Returns [Failure] with a
  /// [UuidPathParamError] when the input is not a canonical UUID v4.
  static Result<RejectLookupRequestIntent> parseFromPath(String rawRequestId) =>
      validateUuidPathParam(
        rawRequestId,
        fieldName: 'requestId',
      ).map((requestId) => RejectLookupRequestIntent(requestId: requestId));
}

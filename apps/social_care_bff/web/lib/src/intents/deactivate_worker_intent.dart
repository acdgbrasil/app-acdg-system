import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `PUT /team/{memberId}/deactivate` — soft-deactivate a team
/// member (revokes login, preserves audit trail).
///
/// Path-only shape. [parseFromPath] validates the route parameter as a
/// canonical UUID v4 (per A23 — `validateUuidPathParam`) and returns
/// the normalized form. Failure mode is exclusively
/// [UuidPathParamError] (PII-safe).
final class DeactivateWorkerIntent with Equatable {
  const DeactivateWorkerIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];

  /// V2 (§P5): the entire parser collapses to a [Result.map] chain —
  /// no manual cast on the sealed `Result<T>`.
  static Result<DeactivateWorkerIntent> parseFromPath(String rawMemberId) =>
      validateUuidPathParam(
        rawMemberId,
        fieldName: 'memberId',
      ).map((id) => DeactivateWorkerIntent(memberId: id));
}

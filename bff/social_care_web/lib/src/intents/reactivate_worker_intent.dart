import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `PUT /team/{memberId}/reactivate` — reactivate a previously
/// deactivated team member.
///
/// Path-only shape. [parseFromPath] validates the route parameter as a
/// canonical UUID v4 (per A23 — `validateUuidPathParam`) and returns
/// the normalized form. Failure mode is exclusively
/// [UuidPathParamError] (PII-safe).
final class ReactivateWorkerIntent with Equatable {
  const ReactivateWorkerIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];

  /// V2 (§P5): the entire parser collapses to a [Result.map] chain —
  /// no manual cast on the sealed `Result<T>`.
  static Result<ReactivateWorkerIntent> parseFromPath(String rawMemberId) =>
      validateUuidPathParam(
        rawMemberId,
        fieldName: 'memberId',
      ).map((id) => ReactivateWorkerIntent(memberId: id));
}

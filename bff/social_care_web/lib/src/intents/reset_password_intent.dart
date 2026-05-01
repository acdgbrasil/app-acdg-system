import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `POST /team/{memberId}/reset-password` — trigger a password
/// reset flow for a team member.
///
/// Path-only shape. [parseFromPath] validates the route parameter as a
/// canonical UUID v4 (per A23 — `validateUuidPathParam`) and returns
/// the normalized form. The endpoint is fire-and-forget on the BFF side
/// — Zitadel handles the actual reset email out-of-band. Failure mode
/// is exclusively [UuidPathParamError] (PII-safe).
final class ResetPasswordIntent with Equatable {
  const ResetPasswordIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];

  /// V2 (§P5): the entire parser collapses to a [Result.map] chain —
  /// no manual cast on the sealed `Result<T>`.
  static Result<ResetPasswordIntent> parseFromPath(String rawMemberId) =>
      validateUuidPathParam(
        rawMemberId,
        fieldName: 'memberId',
      ).map((id) => ResetPasswordIntent(memberId: id));
}

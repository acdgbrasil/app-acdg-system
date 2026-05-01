import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `PUT /team/{memberId}/roles/{roleId}/reactivate` — reactivate
/// a previously deactivated role assignment.
///
/// Path-only shape with TWO route params. [parseFromParams] validates
/// both as canonical UUID v4 (per A23 — `validateUuidPathParam`).
/// Failures short-circuit left-to-right (memberId before roleId) via
/// the 2-ary `combineWith` from `core_contracts`. Failure mode is
/// exclusively [UuidPathParamError] (PII-safe).
final class ReactivateRoleIntent with Equatable {
  const ReactivateRoleIntent({required this.memberId, required this.roleId});

  final String memberId;
  final String roleId;

  @override
  List<Object?> get props => [memberId, roleId];

  /// V2 (§P5): combines two independent path-UUID validations via
  /// `(Result, Result).combineWith` — no manual cast on the sealed
  /// `Result<T>`. Short-circuits on the first failure left-to-right.
  static Result<ReactivateRoleIntent> parseFromParams({
    required String rawMemberId,
    required String rawRoleId,
  }) {
    final m = validateUuidPathParam(rawMemberId, fieldName: 'memberId');
    final r = validateUuidPathParam(rawRoleId, fieldName: 'roleId');
    return (m, r).combineWith(
      (memberId, roleId) =>
          ReactivateRoleIntent(memberId: memberId, roleId: roleId),
    );
  }
}

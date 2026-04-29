import 'package:core_contracts/core_contracts.dart';

/// Intent for `PUT /team/{memberId}/roles/{roleId}/deactivate` — soft-remove
/// a specific role assignment.
///
/// Path-only shape with TWO route params: the intent is built straight
/// from the route; no `parseFromBody` exists.
final class DeactivateRoleIntent with Equatable {
  const DeactivateRoleIntent({
    required this.memberId,
    required this.roleId,
  });

  final String memberId;
  final String roleId;

  @override
  List<Object?> get props => [memberId, roleId];
}

import 'package:core_contracts/core_contracts.dart';

/// Intent for `PUT /team/{memberId}/deactivate` — soft-deactivate a team
/// member (revokes login, preserves audit trail).
///
/// Path-only shape: the route param is injected straight from the shelf
/// router; no `parseFromBody` exists.
final class DeactivateWorkerIntent with Equatable {
  const DeactivateWorkerIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

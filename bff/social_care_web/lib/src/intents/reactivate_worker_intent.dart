import 'package:core_contracts/core_contracts.dart';

/// Intent for `PUT /team/{memberId}/reactivate` — reactivate a previously
/// deactivated team member.
///
/// Path-only shape: the route param is injected straight from the shelf
/// router; no `parseFromBody` exists.
final class ReactivateWorkerIntent with Equatable {
  const ReactivateWorkerIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

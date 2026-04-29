import 'package:core_contracts/core_contracts.dart';

/// Intent for `GET /team/{memberId}` — fetch the full aggregate
/// (person + roles + status) of a single team member.
///
/// Path-only shape (mirrors A08 [GetPatientIntent]): the route param is
/// injected straight from the shelf router; no `parseFromBody` exists.
final class GetTeamMemberIntent with Equatable {
  const GetTeamMemberIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

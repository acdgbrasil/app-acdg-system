import 'package:core_contracts/core_contracts.dart';

/// Intent for `POST /team/{memberId}/reset-password` — trigger a password
/// reset flow for a team member.
///
/// Path-only shape: the route param is injected straight from the shelf
/// router; no `parseFromBody` exists. The endpoint is fire-and-forget on
/// the BFF side — Zitadel handles the actual reset email out-of-band.
final class ResetPasswordIntent with Equatable {
  const ResetPasswordIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];
}

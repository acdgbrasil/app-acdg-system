import 'package:core_contracts/core_contracts.dart';

import 'uuid_validation.dart';

/// Intent for `GET /team/{memberId}` — fetch the full aggregate
/// (person + roles + status) of a single team member.
///
/// Path-only shape (mirrors A08 [GetPatientIntent]). [parseFromPath]
/// validates the route parameter as a canonical UUID v4 (per A23 —
/// `validateUuidPathParam`) and returns the normalized form. Direct
/// construction is still allowed for cases that already hold a
/// validated id (e.g. derived from another intent in tests).
final class GetTeamMemberIntent with Equatable {
  const GetTeamMemberIntent({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => [memberId];

  /// Validates [rawMemberId] as a UUID v4 path parameter and wraps it
  /// in a [GetTeamMemberIntent]. Returns [Failure] with a
  /// [UuidPathParamError] when the input is not a canonical UUID v4.
  ///
  /// V2 (§P5): the entire parser collapses to a [Result.map] chain —
  /// no manual cast on the sealed `Result<T>`.
  static Result<GetTeamMemberIntent> parseFromPath(String rawMemberId) =>
      validateUuidPathParam(
        rawMemberId,
        fieldName: 'memberId',
      ).map((id) => GetTeamMemberIntent(memberId: id));
}

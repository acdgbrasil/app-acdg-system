import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/people/assign_role_request.dart';
import '../dto/requests/people/register_person_with_login_request.dart';
import '../dto/responses/team/team_member_detail_response.dart';
import '../dto/responses/team/team_member_response.dart';
import '../dto/shared/standard_response.dart';

/// Team contract — professionals (social workers, admins) and their roles.
///
/// The BFF hides the fact that "team members" are stored in two places
/// (PeopleContext for identity, local roles for authorization). The APP
/// only sees `/api/team/*` endpoints — no `/people/*` leakage.
abstract interface class TeamContract {
  // ── Team members ──────────────────────────────────────────────────────

  /// Lists team professionals with optional filters.
  ///
  /// Composite: internally fetches from TeamService + PeopleContext to
  /// enrich each member with name/email/phone.
  Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({
    String? role,
    bool? active,
    String? search,
  });

  /// Registers a new team professional.
  ///
  /// Composite: registers person in PeopleContext, creates worker record,
  /// and assigns initial role — all in one BFF-orchestrated transaction.
  Future<Result<StandardIdResponse>> registerWorker(
    RegisterPersonWithLoginRequest request,
  );

  /// Retrieves the full aggregate for a team member (person + roles + status).
  Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(
    String memberId,
  );

  /// Deactivates a team member (revokes login, preserves audit trail).
  Future<Result<StandardResponse<void>>> deactivateWorker(String memberId);

  /// Reactivates a previously deactivated team member.
  Future<Result<StandardResponse<void>>> reactivateWorker(String memberId);

  /// Triggers a password reset flow for a team member.
  Future<Result<StandardResponse<void>>> resetPassword(String memberId);

  // ── Roles ─────────────────────────────────────────────────────────────

  /// Assigns a role to a team member.
  Future<Result<StandardIdResponse>> assignRole(
    String memberId,
    AssignRoleRequest request,
  );

  /// Deactivates a specific role assignment (soft remove).
  Future<Result<StandardResponse<void>>> deactivateRole(
    String memberId,
    String roleId,
  );

  /// Reactivates a previously deactivated role.
  Future<Result<StandardResponse<void>>> reactivateRole(
    String memberId,
    String roleId,
  );
}

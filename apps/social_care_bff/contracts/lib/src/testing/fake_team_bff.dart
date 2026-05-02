import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/people/assign_role_request.dart';
import '../contract/dto/requests/people/register_person_with_login_request.dart';
import '../contract/dto/responses/people/person_role_response.dart';
import '../contract/dto/responses/team/team_member_detail_response.dart';
import '../contract/dto/responses/team/team_member_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/team_contract.dart';
import 'stores/in_memory_team_store.dart';

/// In-memory fake for [TeamContract].
///
/// State is held in an [InMemoryTeamStore] — a public collaborator the
/// tests can inspect or pre-seed via `fake.store.members[...]`.
class FakeTeamBff implements TeamContract {
  FakeTeamBff({InMemoryTeamStore? store})
      : store = store ?? InMemoryTeamStore();

  final InMemoryTeamStore store;

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  // ── Team members ────────────────────────────────────────────────────────

  @override
  Future<Result<StandardResponse<List<TeamMemberResponse>>>> listTeam({
    String? role,
    bool? active,
    String? search,
  }) async {
    return Success(
      _wrap(store.list(role: role, active: active, search: search)),
    );
  }

  @override
  Future<Result<StandardIdResponse>> registerWorker(
    RegisterPersonWithLoginRequest request,
  ) async {
    final id = _nextId();
    store.register(
      TeamMemberResponse(
        id: id,
        personId: id,
        fullName: request.fullName,
        email: request.email,
        phone: null,
        active: true,
        primaryRole: null,
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<StandardResponse<TeamMemberDetailResponse>>> getTeamMember(
    String memberId,
  ) async {
    final member = store.get(memberId);
    if (member == null) {
      return Failure('Team member not found: $memberId');
    }
    final roles = List<PersonRoleResponse>.from(
      store.rolesByMemberId[memberId] ?? const <PersonRoleResponse>[],
    );
    return Success(
      _wrap(
        TeamMemberDetailResponse(
          id: member.id,
          personId: member.personId,
          fullName: member.fullName,
          email: member.email,
          phone: member.phone,
          active: member.active,
          roles: roles,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ),
    );
  }

  @override
  Future<Result<StandardResponse<void>>> deactivateWorker(
    String memberId,
  ) async {
    store.deactivate(memberId);
    return Success(_wrap(null));
  }

  @override
  Future<Result<StandardResponse<void>>> reactivateWorker(
    String memberId,
  ) async {
    store.reactivate(memberId);
    return Success(_wrap(null));
  }

  @override
  Future<Result<StandardResponse<void>>> resetPassword(String memberId) async =>
      Success(_wrap(null));

  // ── Roles ───────────────────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> assignRole(
    String memberId,
    AssignRoleRequest request,
  ) async {
    final roleId = _nextId();
    store.assignRole(
      memberId,
      PersonRoleResponse(
        id: roleId,
        personId: store.get(memberId)?.personId ?? memberId,
        system: request.system,
        role: request.role,
        active: true,
        assignedAt: DateTime.now().toIso8601String(),
      ),
    );
    return Success(_wrapId(roleId));
  }

  @override
  Future<Result<StandardResponse<void>>> deactivateRole(
    String memberId,
    String roleId,
  ) async {
    store.deactivateRole(memberId, roleId);
    return Success(_wrap(null));
  }

  @override
  Future<Result<StandardResponse<void>>> reactivateRole(
    String memberId,
    String roleId,
  ) async {
    store.reactivateRole(memberId, roleId);
    return Success(_wrap(null));
  }
}

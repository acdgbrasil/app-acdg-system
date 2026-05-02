import '../../contract/dto/responses/people/person_role_response.dart';
import '../../contract/dto/responses/team/team_member_response.dart';

/// In-memory collaborator that stores [TeamMemberResponse] records and the
/// list of roles per member.
///
/// `deactivate` / `reactivate` rebuild the member DTO (immutable) rather
/// than mutating it.
class InMemoryTeamStore {
  InMemoryTeamStore();

  /// Team members keyed by member id.
  final Map<String, TeamMemberResponse> members = {};

  /// Roles assigned to each member, keyed by member id.
  final Map<String, List<PersonRoleResponse>> rolesByMemberId = {};

  /// Registers (or replaces) a team member.
  void register(TeamMemberResponse member) {
    members[member.id] = member;
  }

  /// Returns the stored member by id, or `null`.
  TeamMemberResponse? get(String id) => members[id];

  /// Lists members with optional filters.
  ///
  /// - [role]: exact match against `primaryRole`
  /// - [active]: filters by the `active` flag
  /// - [search]: case-insensitive substring match on `fullName`
  List<TeamMemberResponse> list({
    String? role,
    bool? active,
    String? search,
  }) {
    Iterable<TeamMemberResponse> list = members.values;
    if (active != null) {
      list = list.where((m) => m.active == active);
    }
    if (role != null && role.isNotEmpty) {
      list = list.where((m) => m.primaryRole == role);
    }
    if (search != null && search.isNotEmpty) {
      final needle = search.toLowerCase();
      list = list.where((m) => m.fullName.toLowerCase().contains(needle));
    }
    return list.toList();
  }

  /// Rebuilds the member with `active: false`. No-op when not found.
  void deactivate(String id) {
    _flipMemberActive(id, active: false);
  }

  /// Rebuilds the member with `active: true`. No-op when not found.
  void reactivate(String id) {
    _flipMemberActive(id, active: true);
  }

  /// Appends a role for the given member.
  void assignRole(String memberId, PersonRoleResponse role) {
    rolesByMemberId
        .putIfAbsent(memberId, () => <PersonRoleResponse>[])
        .add(role);
  }

  /// Replaces the role matching `roleId` with an inactive copy.
  void deactivateRole(String memberId, String roleId) {
    _flipRoleActive(memberId, roleId, active: false);
  }

  /// Replaces the role matching `roleId` with an active copy.
  void reactivateRole(String memberId, String roleId) {
    _flipRoleActive(memberId, roleId, active: true);
  }

  /// Resets the store between tests.
  void clear() {
    members.clear();
    rolesByMemberId.clear();
  }

  void _flipMemberActive(String id, {required bool active}) {
    final current = members[id];
    if (current == null) return;
    members[id] = TeamMemberResponse(
      id: current.id,
      personId: current.personId,
      fullName: current.fullName,
      email: current.email,
      phone: current.phone,
      active: active,
      primaryRole: current.primaryRole,
    );
  }

  void _flipRoleActive(
    String memberId,
    String roleId, {
    required bool active,
  }) {
    final list = rolesByMemberId[memberId];
    if (list == null) return;
    final index = list.indexWhere((r) => r.id == roleId);
    if (index == -1) return;
    final current = list[index];
    list[index] = PersonRoleResponse(
      id: current.id,
      personId: current.personId,
      system: current.system,
      role: current.role,
      active: active,
      fullName: current.fullName,
      assignedAt: current.assignedAt,
    );
  }
}

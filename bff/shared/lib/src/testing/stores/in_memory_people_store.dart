import '../../contract/dto/responses/people/person_response.dart';
import '../../contract/dto/responses/people/person_role_response.dart';

/// In-memory collaborator that stores [PersonResponse] entities and the
/// list of roles per person.
///
/// Roles are immutable DTOs — `deactivateRole` rebuilds the entry in place
/// rather than mutating the original.
class InMemoryPeopleStore {
  InMemoryPeopleStore();

  /// People keyed by `personId`.
  final Map<String, PersonResponse> people = {};

  /// Roles assigned to each person, keyed by `personId`.
  final Map<String, List<PersonRoleResponse>> rolesByPersonId = {};

  /// Registers (or replaces) a person.
  void register(PersonResponse person) {
    people[person.id] = person;
  }

  /// Returns the stored person by id, or `null` if not found.
  ///
  /// Same reference as was registered.
  PersonResponse? get(String id) => people[id];

  /// Returns the first person whose `cpf` matches, or `null`.
  PersonResponse? findByCpf(String cpf) {
    for (final person in people.values) {
      if (person.cpf == cpf) return person;
    }
    return null;
  }

  /// Appends a role for the given person. Creates the list on first call.
  void assignRole(String personId, PersonRoleResponse role) {
    rolesByPersonId
        .putIfAbsent(personId, () => <PersonRoleResponse>[])
        .add(role);
  }

  /// Snapshot of roles for a person. Empty list if unknown.
  List<PersonRoleResponse> listRoles(String personId) =>
      List<PersonRoleResponse>.from(
        rolesByPersonId[personId] ?? const <PersonRoleResponse>[],
      );

  /// Replaces the role matching `roleId` with an inactive copy.
  ///
  /// DTOs are immutable, so this rebuilds the entry at the same index.
  /// No-op when the role is not found.
  void deactivateRole(String personId, String roleId) {
    _flipRoleActive(personId, roleId, active: false);
  }

  /// Replaces the role matching `roleId` with an active copy.
  void reactivateRole(String personId, String roleId) {
    _flipRoleActive(personId, roleId, active: true);
  }

  /// Resets the store between tests.
  void clear() {
    people.clear();
    rolesByPersonId.clear();
  }

  void _flipRoleActive(
    String personId,
    String roleId, {
    required bool active,
  }) {
    final list = rolesByPersonId[personId];
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

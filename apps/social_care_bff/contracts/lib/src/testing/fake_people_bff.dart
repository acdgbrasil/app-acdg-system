import 'package:core_contracts/core_contracts.dart';

import '../contract/dto/requests/people/assign_role_request.dart';
import '../contract/dto/requests/people/register_person_request.dart';
import '../contract/dto/requests/people/register_person_with_login_request.dart';
import '../contract/dto/responses/people/person_response.dart';
import '../contract/dto/responses/people/person_role_response.dart';
import '../contract/dto/shared/standard_response.dart';
import '../contract/sub_contracts/people_contract.dart';
import 'stores/in_memory_people_store.dart';

/// In-memory fake for [PeopleContract].
///
/// State is held in an [InMemoryPeopleStore] — a public collaborator the
/// tests can inspect or pre-seed via `fake.store.people[...]`.
class FakePeopleBff implements PeopleContract {
  FakePeopleBff({InMemoryPeopleStore? store})
      : store = store ?? InMemoryPeopleStore();

  final InMemoryPeopleStore store;

  /// Persons marked as inactive via [deactivatePerson]. Not exposed in the
  /// PersonResponse DTO (no `active` field), so this is kept as a local set.
  final Set<String> inactivePeople = <String>{};

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  StandardResponse<T> _wrap<T>(T data) => StandardResponse(
    data: data,
    meta: ResponseMeta(timestamp: DateTime.now().toIso8601String()),
  );

  StandardIdResponse _wrapId(String id) => _wrap(IdData(id: id));

  // ── Person Registration ─────────────────────────────────────────────────

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) async {
    final id = _nextId();
    store.register(
      PersonResponse(
        id: id,
        fullName: request.fullName,
        birthDate: request.birthDate,
        cpf: request.cpf,
      ),
    );
    return Success(_wrapId(id));
  }

  @override
  Future<Result<StandardIdResponse>> registerPersonWithLogin(
    RegisterPersonWithLoginRequest request,
  ) async {
    final id = _nextId();
    store.register(
      PersonResponse(
        id: id,
        fullName: request.fullName,
        birthDate: request.birthDate,
        cpf: request.cpf,
      ),
    );
    return Success(_wrapId(id));
  }

  // ── Person Queries ──────────────────────────────────────────────────────

  @override
  Future<Result<PersonResponse>> getPerson(String personId) async {
    final person = store.get(personId);
    if (person == null) {
      return Failure('Person not found: $personId');
    }
    return Success(person);
  }

  @override
  Future<Result<PersonResponse>> findPersonByCpf(String cpf) async {
    final person = store.findByCpf(cpf);
    if (person == null) {
      return Failure('Person not found for cpf: $cpf');
    }
    return Success(person);
  }

  @override
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  }) async {
    Iterable<PersonResponse> filtered = store.people.values;
    if (name != null && name.isNotEmpty) {
      final needle = name.toLowerCase();
      filtered = filtered.where(
        (p) => p.fullName.toLowerCase().contains(needle),
      );
    }
    if (cpf != null && cpf.isNotEmpty) {
      filtered = filtered.where((p) => p.cpf == cpf);
    }
    final list = filtered.toList();
    return Success(_wrap(list));
  }

  // ── Person Lifecycle ────────────────────────────────────────────────────

  @override
  Future<Result<void>> deactivatePerson(String personId) async {
    inactivePeople.add(personId);
    return const Success(null);
  }

  @override
  Future<Result<void>> reactivatePerson(String personId) async {
    inactivePeople.remove(personId);
    return const Success(null);
  }

  @override
  Future<Result<void>> requestPasswordReset(String personId) async =>
      const Success(null);

  // ── Roles ───────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> assignRole(
    String personId,
    AssignRoleRequest request,
  ) async {
    final roleId = _nextId();
    store.assignRole(
      personId,
      PersonRoleResponse(
        id: roleId,
        personId: personId,
        system: request.system,
        role: request.role,
        active: true,
        assignedAt: DateTime.now().toIso8601String(),
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(
    String personId, {
    bool? active,
  }) async {
    var roles = store.listRoles(personId);
    if (active != null) {
      roles = roles.where((r) => r.active == active).toList();
    }
    return Success(roles);
  }

  @override
  Future<Result<List<PersonRoleResponse>>> queryRoles({
    required String system,
    String? role,
    bool active = true,
  }) async {
    final result = <PersonRoleResponse>[];
    for (final list in store.rolesByPersonId.values) {
      for (final item in list) {
        if (item.system != system) continue;
        if (role != null && item.role != role) continue;
        if (item.active != active) continue;
        result.add(item);
      }
    }
    return Success(result);
  }

  @override
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) async {
    store.deactivateRole(personId, roleId);
    return const Success(null);
  }

  @override
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) async {
    store.reactivateRole(personId, roleId);
    return const Success(null);
  }
}

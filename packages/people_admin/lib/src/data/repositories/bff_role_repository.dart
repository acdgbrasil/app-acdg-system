import 'package:core/core.dart';

import '../../domain/models/system_role.dart';
import '../services/people_admin_client.dart';
import 'role_repository.dart';

class BffRoleRepository implements RoleRepository {
  BffRoleRepository({required PeopleAdminClient client}) : _client = client;

  final PeopleAdminClient _client;

  @override
  Future<Result<void>> assignRole({
    required String personId,
    required String system,
    required String role,
  }) => _client.assignRole(personId: personId, system: system, role: role);

  @override
  Future<Result<List<SystemRole>>> fetchRolesForPerson(
    String personId, {
    bool? active,
  }) => _client.fetchRolesForPerson(personId, active: active);

  @override
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  }) => _client.deactivateRole(personId: personId, roleId: roleId);

  @override
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  }) => _client.reactivateRole(personId: personId, roleId: roleId);

  @override
  Future<Result<List<SystemRole>>> queryRolesBySystem({
    required String system,
    String? role,
    bool? active,
  }) => _client.queryRolesBySystem(system: system, role: role, active: active);
}

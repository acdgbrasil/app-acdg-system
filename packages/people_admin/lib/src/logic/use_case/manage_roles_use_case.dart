import 'package:core/core.dart';
import '../../data/repositories/role_repository.dart';
import '../../domain/models/system_role.dart';

class ManageRolesUseCase {
  ManageRolesUseCase({required RoleRepository roleRepository})
      : _roleRepository = roleRepository;

  final RoleRepository _roleRepository;

  Future<Result<List<SystemRole>>> loadRoles(String personId, {bool? active}) {
    return _roleRepository.fetchRolesForPerson(personId, active: active);
  }

  Future<Result<void>> assignRole({
    required String personId,
    required String system,
    required String role,
  }) {
    return _roleRepository.assignRole(
      personId: personId,
      system: system,
      role: role,
    );
  }

  Future<Result<void>> toggleRole({
    required String personId,
    required String roleId,
    required bool activate,
  }) {
    if (activate) {
      return _roleRepository.reactivateRole(personId: personId, roleId: roleId);
    }
    return _roleRepository.deactivateRole(personId: personId, roleId: roleId);
  }
}

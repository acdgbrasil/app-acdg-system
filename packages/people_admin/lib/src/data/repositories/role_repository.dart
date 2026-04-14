import 'package:core/core.dart';

import '../../domain/models/system_role.dart';

abstract class RoleRepository {
  /// Assigns a new role to a person in a specific system.
  Future<Result<void>> assignRole({
    required String personId,
    required String system,
    required String role,
  });

  /// Lists all roles for a person. Can filter by active status.
  Future<Result<List<SystemRole>>> fetchRolesForPerson(
    String personId, {
    bool? active,
  });

  /// Deactivates a specific role for a person.
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  });

  /// Reactivates a specific role for a person.
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  });

  /// Consults roles cross-person by system.
  Future<Result<List<SystemRole>>> queryRolesBySystem({
    required String system,
    String? role,
    bool? active,
  });
}

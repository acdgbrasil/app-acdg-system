import 'package:core_contracts/core_contracts.dart';

import '../dto/requests/people/assign_role_request.dart';
import '../dto/requests/people/register_person_request.dart';
import '../dto/requests/people/register_person_with_login_request.dart';
import '../dto/responses/people/person_response.dart';
import '../dto/responses/people/person_role_response.dart';
import '../dto/shared/standard_response.dart';

/// People contract — person CRUD, CPF lookup, and role management.
///
/// Represents the BFF's interaction with the People Context service.
/// The People Context is the canonical source of person identity across
/// all systems in the ACDG ecosystem.
abstract interface class PeopleContract {
  // ── Person Registration ───────────────────────────────────────────────

  /// Registers a person (idempotent on CPF).
  /// Returns [StandardIdResponse] with the canonical person ID.
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  );

  /// Registers a person and creates a Zitadel login.
  /// For team members (social workers, admins).
  /// Returns [StandardIdResponse] with the canonical person ID.
  Future<Result<StandardIdResponse>> registerPersonWithLogin(
    RegisterPersonWithLoginRequest request,
  );

  // ── Person Queries ────────────────────────────────────────────────────

  /// Retrieves a person by their unique [personId].
  Future<Result<PersonResponse>> getPerson(String personId);

  /// Finds a person by their CPF.
  Future<Result<PersonResponse>> findPersonByCpf(String cpf);

  /// Lists people with optional search filters and cursor pagination.
  Future<Result<StandardResponse<List<PersonResponse>>>> fetchPeople({
    int? limit,
    String? name,
    String? cpf,
    String? cursor,
  });

  // ── Person Lifecycle ──────────────────────────────────────────────────

  /// Deactivates a person and their Zitadel user.
  Future<Result<void>> deactivatePerson(String personId);

  /// Reactivates a previously deactivated person.
  Future<Result<void>> reactivatePerson(String personId);

  /// Requests a password reset for a person's Zitadel account.
  Future<Result<void>> requestPasswordReset(String personId);

  // ── Roles ─────────────────────────────────────────────────────────────

  /// Assigns a system role to a person.
  Future<Result<void>> assignRole(String personId, AssignRoleRequest request);

  /// Lists roles for a specific person.
  Future<Result<List<PersonRoleResponse>>> listPersonRoles(
    String personId, {
    bool? active,
  });

  /// Queries roles across all people, filtered by system and optionally role.
  Future<Result<List<PersonRoleResponse>>> queryRoles({
    required String system,
    String? role,
    bool active = true,
  });

  /// Deactivates a specific role.
  Future<Result<void>> deactivateRole({
    required String personId,
    required String roleId,
  });

  /// Reactivates a specific role.
  Future<Result<void>> reactivateRole({
    required String personId,
    required String roleId,
  });
}

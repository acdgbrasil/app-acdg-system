import 'package:core/core.dart';

import '../../domain/models/paginated_result.dart';
import '../../domain/models/person.dart';
import '../../domain/models/register_worker_intent.dart';

abstract class PeopleRepository {
  /// Fetches a paginated list of people. Can filter by name or cpf.
  Future<Result<PaginatedResult<Person>>> fetchPeople({
    String? cursor,
    int? limit,
    String? name,
    String? cpf,
  });

  /// Fetches a person by their UUID.
  Future<Result<Person>> getPersonById(String personId);

  /// Fetches a person by their CPF.
  Future<Result<Person>> getPersonByCpf(String cpf);

  /// Registers a new person.
  Future<Result<String>> registerPerson(RegisterWorkerIntent intent);

  /// Deactivates a person in the system.
  Future<Result<void>> deactivatePerson(String personId);

  /// Reactivates a person in the system.
  Future<Result<void>> reactivatePerson(String personId);

  /// Requests a password reset for a person with Zitadel login.
  Future<Result<void>> requestPasswordReset(String personId);
}

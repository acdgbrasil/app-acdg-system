import 'package:core/core.dart';

import '../../domain/models/paginated_result.dart';
import '../../domain/models/person.dart';
import '../../domain/models/register_worker_intent.dart';
import '../services/people_admin_client.dart';
import 'people_repository.dart';

class BffPeopleRepository implements PeopleRepository {
  BffPeopleRepository({required PeopleAdminClient client}) : _client = client;

  final PeopleAdminClient _client;

  @override
  Future<Result<PaginatedResult<Person>>> fetchPeople({
    String? cursor,
    int? limit,
    String? name,
    String? cpf,
  }) => _client.fetchPeople(cursor: cursor, limit: limit, name: name, cpf: cpf);

  @override
  Future<Result<Person>> getPersonById(String personId) =>
      _client.getPersonById(personId);

  @override
  Future<Result<Person>> getPersonByCpf(String cpf) =>
      _client.getPersonByCpf(cpf);

  @override
  Future<Result<String>> registerPerson(RegisterWorkerIntent intent) =>
      _client.registerPerson(intent);

  @override
  Future<Result<void>> deactivatePerson(String personId) =>
      _client.deactivatePerson(personId);

  @override
  Future<Result<void>> reactivatePerson(String personId) =>
      _client.reactivatePerson(personId);

  @override
  Future<Result<void>> requestPasswordReset(String personId) =>
      _client.requestPasswordReset(personId);
}

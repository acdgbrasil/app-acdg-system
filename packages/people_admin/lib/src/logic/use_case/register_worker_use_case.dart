import 'package:core/core.dart';
import '../../data/repositories/people_repository.dart';
import '../../domain/models/register_worker_intent.dart';

class RegisterWorkerUseCase extends BaseUseCase<RegisterWorkerIntent, String> {
  RegisterWorkerUseCase({required PeopleRepository peopleRepository})
      : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  @override
  Future<Result<String>> execute(RegisterWorkerIntent input) {
    return _peopleRepository.registerPerson(input);
  }
}

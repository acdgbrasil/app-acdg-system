import 'package:core/core.dart';

import '../../data/repositories/people_repository.dart';
import '../../domain/models/person.dart';

class GetPersonUseCase extends BaseUseCase<String, Person> {
  GetPersonUseCase({required PeopleRepository peopleRepository})
      : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  @override
  Future<Result<Person>> execute(String input) {
    return _peopleRepository.getPersonById(input);
  }
}

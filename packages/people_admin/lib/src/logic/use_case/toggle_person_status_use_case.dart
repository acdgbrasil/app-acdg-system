import 'package:core/core.dart';

import '../../data/repositories/people_repository.dart';

typedef TogglePersonStatusInput = ({String personId, bool currentlyActive});

class TogglePersonStatusUseCase
    extends BaseUseCase<TogglePersonStatusInput, void> {
  TogglePersonStatusUseCase({required PeopleRepository peopleRepository})
      : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  @override
  Future<Result<void>> execute(TogglePersonStatusInput input) {
    if (input.currentlyActive) {
      return _peopleRepository.deactivatePerson(input.personId);
    }
    return _peopleRepository.reactivatePerson(input.personId);
  }
}

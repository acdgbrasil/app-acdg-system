import 'package:core/core.dart';

import '../../data/repositories/people_repository.dart';

class ResetPasswordUseCase extends BaseUseCase<String, void> {
  ResetPasswordUseCase({required PeopleRepository peopleRepository})
      : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  @override
  Future<Result<void>> execute(String personId) {
    return _peopleRepository.requestPasswordReset(personId);
  }
}

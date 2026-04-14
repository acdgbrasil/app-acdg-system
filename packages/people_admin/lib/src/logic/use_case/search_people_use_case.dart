import 'package:core/core.dart';
import '../../data/repositories/people_repository.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/models/person.dart';

typedef SearchPeopleParams = ({
  int? limit,
  String? name,
  String? cpf,
  String? cursor,
});

class SearchPeopleUseCase
    extends BaseUseCase<SearchPeopleParams, PaginatedResult<Person>> {
  SearchPeopleUseCase({required PeopleRepository peopleRepository})
      : _peopleRepository = peopleRepository;

  final PeopleRepository _peopleRepository;

  @override
  Future<Result<PaginatedResult<Person>>> execute(SearchPeopleParams input) {
    return _peopleRepository.fetchPeople(
      limit: input.limit,
      name: input.name,
      cpf: input.cpf,
      cursor: input.cursor,
    );
  }
}

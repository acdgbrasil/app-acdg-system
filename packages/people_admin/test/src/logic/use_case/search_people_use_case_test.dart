import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/data/repositories/people_repository.dart';
import 'package:people_admin/src/domain/models/paginated_result.dart';
import 'package:people_admin/src/domain/models/person.dart';
import 'package:people_admin/src/logic/use_case/search_people_use_case.dart';

class MockPeopleRepository extends Mock implements PeopleRepository {}

void main() {
  late MockPeopleRepository mockRepo;
  late SearchPeopleUseCase useCase;

  setUp(() {
    mockRepo = MockPeopleRepository();
    useCase = SearchPeopleUseCase(peopleRepository: mockRepo);
  });

  group('SearchPeopleUseCase', () {
    test('should return PaginatedResult on Success', () async {
      // Arrange
      const fakeResult = PaginatedResult(
        items: [
          Person(id: '1', fullName: 'Alice', active: true),
        ],
        nextCursor: 'abc',
      );

      when(
        () => mockRepo.fetchPeople(
          limit: any(named: 'limit'),
          name: any(named: 'name'),
          cpf: any(named: 'cpf'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => const Success(fakeResult));

      // Act
      final result = await useCase.execute((
        limit: 10,
        name: 'Alice',
        cpf: null,
        cursor: null,
      ));

      // Assert
      expect(result, isA<Success<PaginatedResult<Person>>>());
      final value = (result as Success<PaginatedResult<Person>>).value;
      expect(value.items.length, 1);
      expect(value.items.first.fullName, 'Alice');
      expect(value.nextCursor, 'abc');
      
      verify(() => mockRepo.fetchPeople(limit: 10, name: 'Alice')).called(1);
    });

    test('should return Failure on Error', () async {
      // Arrange
      when(
        () => mockRepo.fetchPeople(
          limit: any(named: 'limit'),
          name: any(named: 'name'),
          cpf: any(named: 'cpf'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => Failure(Exception('Network Error')));

      // Act
      final result = await useCase.execute((
        limit: 20,
        name: null,
        cpf: '123',
        cursor: 'xyz',
      ));

      // Assert
      expect(result, isA<Failure>());
      verify(() => mockRepo.fetchPeople(limit: 20, cpf: '123', cursor: 'xyz')).called(1);
    });
  });
}

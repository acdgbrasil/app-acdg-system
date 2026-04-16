import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/domain/models/paginated_result.dart';
import 'package:people_admin/src/domain/models/person.dart';
import 'package:people_admin/src/logic/use_case/search_people_use_case.dart';
import 'package:people_admin/src/ui/team/view_models/people_list_view_model.dart';

class MockSearchPeopleUseCase extends Mock implements SearchPeopleUseCase {}

void main() {
  late MockSearchPeopleUseCase mockUseCase;
  late PeopleListViewModel viewModel;

  setUp(() {
    registerFallbackValue((limit: null, name: null, cpf: null, cursor: null) as SearchPeopleParams);
    mockUseCase = MockSearchPeopleUseCase();
    viewModel = PeopleListViewModel;
  });

  group('PeopleListViewModel', () {
    test('initial state should be empty', () {
      expect(viewModel.people, isEmpty);
      expect(viewModel.hasMore, isFalse);
    });

    test('searchCommand should load people and update state', () async {
      // Arrange
      const fakeResult = PaginatedResult(
        items: [Person(id: '1', fullName: 'Alice', active: true)],
        nextCursor: 'cursor_2',
      );

      when(() => mockUseCase.execute(any())).thenAnswer((_) async => const Success(fakeResult));

      // Act
      await viewModel.searchCommand.execute('Ali');

      // Assert
      expect(viewModel.people.length, 1);
      expect(viewModel.people.first.fullName, 'Alice');
      expect(viewModel.hasMore, isTrue);

      final captured = verify(() => mockUseCase.execute(captureAny())).captured;
      final params = captured.first as SearchPeopleParams;
      expect(params.name, 'Ali');
      expect(params.cursor, isNull);
    });

    test('loadMoreCommand should append to people list', () async {
      // Arrange - Setup initial state
      const firstResult = PaginatedResult(
        items: [Person(id: '1', fullName: 'Alice', active: true)],
        nextCursor: 'cursor_2',
      );
      when(() => mockUseCase.execute(any())).thenAnswer((_) async => const Success(firstResult));
      await viewModel.searchCommand.execute(''); // Load first page

      // Arrange - Mock second page
      const secondResult = PaginatedResult(
        items: [Person(id: '2', fullName: 'Bob', active: true)],
      );
      when(() => mockUseCase.execute(any())).thenAnswer((_) async => const Success(secondResult));

      // Act - Load second page
      await viewModel.loadMoreCommand.execute();

      // Assert
      expect(viewModel.people.length, 2);
      expect(viewModel.people[0].fullName, 'Alice');
      expect(viewModel.people[1].fullName, 'Bob');
      expect(viewModel.hasMore, isFalse);

      final captured = verify(() => mockUseCase.execute(captureAny())).captured;
      // First capture is search, second is loadMore
      final params = captured.last as SearchPeopleParams;
      expect(params.cursor, 'cursor_2');
    });

    test('searchCommand should clear list on error', () async {
      // Arrange
      when(() => mockUseCase.execute(any())).thenAnswer((_) async => Failure(Exception('Error')));

      // Act
      await viewModel.searchCommand.execute('Fail');

      // Assert
      expect(viewModel.people, isEmpty);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.searchCommand.error, isTrue);
    });
  });
}

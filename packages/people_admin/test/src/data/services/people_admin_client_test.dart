import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/data/services/people_admin_client.dart';
import 'package:people_admin/src/domain/errors/team_errors.dart';
import 'package:people_admin/src/domain/models/paginated_result.dart';
import 'package:people_admin/src/domain/models/person.dart';
import 'package:people_admin/src/domain/models/system_role.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PeopleAdminClient client;

  setUp(() {
    mockDio = MockDio();
    client = PeopleAdminClient(dio: mockDio, baseUrl: 'http://test.com/api/v1');
    registerFallbackValue(RequestOptions());
  });

  group('PeopleAdminClient - fetchPeople', () {
    test('should return PaginatedResult<Person> on 200 OK', () async {
      // Arrange
      final responseData = {
        'items': [
          {
            'id': '123',
            'fullName': 'John Doe',
            'active': true,
          }
        ],
        'nextCursor': 'cursor-123'
      };

      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/people'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await client.fetchPeople(limit: 10, name: 'John');

      // Assert
      expect(result, isA<Success<PaginatedResult<Person>>>());
      final value = (result as Success<PaginatedResult<Person>>).value;
      expect(value.items.length, 1);
      expect(value.items.first.fullName, 'John Doe');
      expect(value.nextCursor, 'cursor-123');
    });

    test('should return TeamServerError on 500', () async {
      // Arrange
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/people'),
          statusCode: 500,
          data: {'error': 'Internal error'},
        ),
      );

      // Act
      final result = await client.fetchPeople();

      // Assert
      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<TeamServerError>());
    });
  });

  group('PeopleAdminClient - Roles', () {
    test('should return roles list on fetchRolesForPerson', () async {
      // Arrange
      final responseData = [
        {
          'id': 'r1',
          'personId': 'p1',
          'system': 'social-care',
          'role': 'admin',
          'active': true
        }
      ];

      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/people/p1/roles'),
          statusCode: 200,
          data: responseData,
        ),
      );

      // Act
      final result = await client.fetchRolesForPerson('p1');

      // Assert
      expect(result, isA<Success<List<SystemRole>>>());
      final value = (result as Success<List<SystemRole>>).value;
      expect(value.length, 1);
      expect(value.first.system, 'social-care');
    });
  });
}

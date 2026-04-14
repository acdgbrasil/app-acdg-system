import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/data/repositories/role_repository.dart';
import 'package:people_admin/src/domain/models/system_role.dart';
import 'package:people_admin/src/logic/use_case/manage_roles_use_case.dart';

class MockRoleRepository extends Mock implements RoleRepository {}

void main() {
  late MockRoleRepository mockRepo;
  late ManageRolesUseCase useCase;

  setUp(() {
    mockRepo = MockRoleRepository();
    useCase = ManageRolesUseCase(roleRepository: mockRepo);
  });

  group('ManageRolesUseCase', () {
    test('should return list of SystemRole on loadRoles', () async {
      // Arrange
      final fakeRoles = [
        const SystemRole(
          id: 'r1',
          personId: 'p1',
          system: 'sys1',
          role: 'admin',
          active: true,
        ),
      ];

      when(() => mockRepo.fetchRolesForPerson('p1', active: any(named: 'active')))
          .thenAnswer((_) async => Success(fakeRoles));

      // Act
      final result = await useCase.loadRoles('p1');

      // Assert
      expect(result, isA<Success<List<SystemRole>>>());
      final value = (result as Success<List<SystemRole>>).value;
      expect(value.length, 1);
      expect(value.first.id, 'r1');
      verify(() => mockRepo.fetchRolesForPerson('p1')).called(1);
    });

    test('should assign a new role successfully', () async {
      // Arrange
      when(
        () => mockRepo.assignRole(
          personId: 'p1',
          system: 'sys1',
          role: 'admin',
        ),
      ).thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase.assignRole(
        personId: 'p1',
        system: 'sys1',
        role: 'admin',
      );

      // Assert
      expect(result, isA<Success<void>>());
      verify(
        () => mockRepo.assignRole(
          personId: 'p1',
          system: 'sys1',
          role: 'admin',
        ),
      ).called(1);
    });

    test('should deactivate a role successfully', () async {
      // Arrange
      when(
        () => mockRepo.deactivateRole(personId: 'p1', roleId: 'r1'),
      ).thenAnswer((_) async => const Success(null));

      // Act
      final result = await useCase.toggleRole(
        personId: 'p1',
        roleId: 'r1',
        activate: false,
      );

      // Assert
      expect(result, isA<Success<void>>());
      verify(() => mockRepo.deactivateRole(personId: 'p1', roleId: 'r1')).called(1);
    });
  });
}

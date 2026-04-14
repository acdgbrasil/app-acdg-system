import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:people_admin/src/domain/models/person.dart';
import 'package:people_admin/src/domain/models/system_role.dart';
import 'package:people_admin/src/logic/use_case/get_person_use_case.dart';
import 'package:people_admin/src/logic/use_case/manage_roles_use_case.dart';
import 'package:people_admin/src/logic/use_case/reset_password_use_case.dart';
import 'package:people_admin/src/logic/use_case/toggle_person_status_use_case.dart';
import 'package:people_admin/src/ui/team/view_models/person_detail_view_model.dart';

class MockGetPersonUseCase extends Mock implements GetPersonUseCase {}

class MockTogglePersonStatusUseCase extends Mock
    implements TogglePersonStatusUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

class MockManageRolesUseCase extends Mock implements ManageRolesUseCase {}

void main() {
  late MockGetPersonUseCase mockGetPerson;
  late MockTogglePersonStatusUseCase mockToggleStatus;
  late MockResetPasswordUseCase mockResetPassword;
  late MockManageRolesUseCase mockRolesUseCase;
  late PersonDetailViewModel viewModel;

  setUp(() {
    mockGetPerson = MockGetPersonUseCase();
    mockToggleStatus = MockTogglePersonStatusUseCase();
    mockResetPassword = MockResetPasswordUseCase();
    mockRolesUseCase = MockManageRolesUseCase();

    registerFallbackValue(
      (personId: '', currentlyActive: false),
    );

    viewModel = PersonDetailViewModel(
      getPersonUseCase: mockGetPerson,
      togglePersonStatusUseCase: mockToggleStatus,
      resetPasswordUseCase: mockResetPassword,
      manageRolesUseCase: mockRolesUseCase,
    );
  });

  group('PersonDetailViewModel', () {
    const fakePerson = Person(id: 'p1', fullName: 'Alice', active: true);
    final fakeRoles = [
      const SystemRole(
        id: 'r1',
        personId: 'p1',
        system: 'sys',
        role: 'admin',
        active: true,
      ),
    ];

    test('loadPersonCommand should fetch person and roles', () async {
      when(() => mockGetPerson.execute('p1'))
          .thenAnswer((_) async => const Success(fakePerson));
      when(() => mockRolesUseCase.loadRoles('p1'))
          .thenAnswer((_) async => Success(fakeRoles));

      await viewModel.loadPersonCommand.execute('p1');

      expect(viewModel.person, isNotNull);
      expect(viewModel.person!.id, 'p1');
      expect(viewModel.roles.length, 1);
      expect(viewModel.roles.first.id, 'r1');

      verify(() => mockGetPerson.execute('p1')).called(1);
      verify(() => mockRolesUseCase.loadRoles('p1')).called(1);
    });

    test(
      'toggleStatusPersonCommand should deactivate an active person and update state',
      () async {
        when(() => mockGetPerson.execute('p1'))
            .thenAnswer((_) async => const Success(fakePerson));
        when(() => mockRolesUseCase.loadRoles('p1'))
            .thenAnswer((_) async => const Success([]));
        await viewModel.loadPersonCommand.execute('p1');

        when(() => mockToggleStatus.execute(any()))
            .thenAnswer((_) async => const Success(null));

        await viewModel.toggleStatusPersonCommand.execute();

        expect(viewModel.person!.active, isFalse);
        verify(() => mockToggleStatus.execute(any())).called(1);
      },
    );

    test('assignRoleCommand should assign role and reload roles', () async {
      when(() => mockGetPerson.execute('p1'))
          .thenAnswer((_) async => const Success(fakePerson));
      when(() => mockRolesUseCase.loadRoles('p1'))
          .thenAnswer((_) async => const Success([]));
      await viewModel.loadPersonCommand.execute('p1');

      when(
        () => mockRolesUseCase.assignRole(
          personId: 'p1',
          system: 'sys2',
          role: 'viewer',
        ),
      ).thenAnswer((_) async => const Success(null));

      final newRoles = [
        const SystemRole(
          id: 'r2',
          personId: 'p1',
          system: 'sys2',
          role: 'viewer',
          active: true,
        ),
      ];
      when(() => mockRolesUseCase.loadRoles('p1'))
          .thenAnswer((_) async => Success(newRoles));

      await viewModel.assignRoleCommand.execute((
        system: 'sys2',
        role: 'viewer',
      ));

      expect(viewModel.roles.length, 1);
      expect(viewModel.roles.first.id, 'r2');
      verify(
        () => mockRolesUseCase.assignRole(
          personId: 'p1',
          system: 'sys2',
          role: 'viewer',
        ),
      ).called(1);
    });
  });
}

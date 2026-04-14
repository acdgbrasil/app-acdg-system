import 'package:core/core.dart';

import '../../../domain/models/person.dart';
import '../../../domain/models/system_role.dart';
import '../../../logic/use_case/get_person_use_case.dart';
import '../../../logic/use_case/manage_roles_use_case.dart';
import '../../../logic/use_case/reset_password_use_case.dart';
import '../../../logic/use_case/toggle_person_status_use_case.dart';

class PersonDetailViewModel extends BaseViewModel {
  PersonDetailViewModel({
    required GetPersonUseCase getPersonUseCase,
    required TogglePersonStatusUseCase togglePersonStatusUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ManageRolesUseCase manageRolesUseCase,
  })  : _getPersonUseCase = getPersonUseCase,
        _togglePersonStatusUseCase = togglePersonStatusUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        _manageRolesUseCase = manageRolesUseCase {
    loadPersonCommand = Command1<void, String>(_loadPerson);
    toggleStatusPersonCommand = Command0<void>(_toggleStatusPerson);
    requestPasswordResetCommand = Command0<void>(_requestPasswordReset);
    assignRoleCommand =
        Command1<void, ({String system, String role})>(_assignRole);
    toggleRoleCommand =
        Command1<void, ({String roleId, bool activate})>(_toggleRole);
  }

  final GetPersonUseCase _getPersonUseCase;
  final TogglePersonStatusUseCase _togglePersonStatusUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final ManageRolesUseCase _manageRolesUseCase;

  late final Command1<void, String> loadPersonCommand;
  late final Command0<void> toggleStatusPersonCommand;
  late final Command0<void> requestPasswordResetCommand;
  late final Command1<void, ({String system, String role})> assignRoleCommand;
  late final Command1<void, ({String roleId, bool activate})> toggleRoleCommand;

  Person? _person;
  List<SystemRole> _roles = [];

  Person? get person => _person;
  List<SystemRole> get roles => List.unmodifiable(_roles);

  Future<Result<void>> _loadPerson(String personId) async {
    final personResult = await _getPersonUseCase.execute(personId);
    final rolesResult = await _manageRolesUseCase.loadRoles(personId);

    switch (personResult) {
      case Success(:final value):
        _person = value;
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }

    switch (rolesResult) {
      case Success(:final value):
        _roles = value;
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }

    notifyListeners();
    return const Success(null);
  }

  Future<Result<void>> _toggleStatusPerson() async {
    final current = _person;
    if (current == null) {
      return Failure(Exception('No person loaded'));
    }

    final result = await _togglePersonStatusUseCase.execute((
      personId: current.id,
      currentlyActive: current.active,
    ));

    switch (result) {
      case Success():
        _person = Person(
          id: current.id,
          fullName: current.fullName,
          active: !current.active,
          cpf: current.cpf,
          birthDate: current.birthDate,
          email: current.email,
          zitadelUserId: current.zitadelUserId,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
        );
        notifyListeners();
        return const Success(null);
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }
  }

  Future<Result<void>> _requestPasswordReset() async {
    final current = _person;
    if (current == null) {
      return Failure(Exception('No person loaded'));
    }

    final result = await _resetPasswordUseCase.execute(current.id);
    notifyListeners();
    return result;
  }

  Future<Result<void>> _assignRole(
    ({String system, String role}) input,
  ) async {
    final current = _person;
    if (current == null) {
      return Failure(Exception('No person loaded'));
    }

    final result = await _manageRolesUseCase.assignRole(
      personId: current.id,
      system: input.system,
      role: input.role,
    );

    switch (result) {
      case Success():
        final rolesResult = await _manageRolesUseCase.loadRoles(current.id);
        if (rolesResult case Success(:final value)) {
          _roles = value;
        }
        notifyListeners();
        return const Success(null);
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }
  }

  Future<Result<void>> _toggleRole(
    ({String roleId, bool activate}) input,
  ) async {
    final current = _person;
    if (current == null) {
      return Failure(Exception('No person loaded'));
    }

    final result = await _manageRolesUseCase.toggleRole(
      personId: current.id,
      roleId: input.roleId,
      activate: input.activate,
    );

    switch (result) {
      case Success():
        final rolesResult = await _manageRolesUseCase.loadRoles(current.id);
        if (rolesResult case Success(:final value)) {
          _roles = value;
        }
        notifyListeners();
        return const Success(null);
      case Failure(:final error):
        notifyListeners();
        return Failure(error);
    }
  }

  @override
  void onDispose() {
    loadPersonCommand.dispose();
    toggleStatusPersonCommand.dispose();
    requestPasswordResetCommand.dispose();
    assignRoleCommand.dispose();
    toggleRoleCommand.dispose();
  }
}

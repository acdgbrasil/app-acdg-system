import 'package:auth/auth.dart';
import 'package:core/core.dart';

class LoginUseCase extends BaseUseCase<void, void> {
  LoginUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> execute(void input) => _repository.login();
}

class LogoutUseCase extends BaseUseCase<void, void> {
  LogoutUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> execute(void input) => _repository.logout();
}

class RestoreSessionUseCase extends BaseUseCase<void, void> {
  RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> execute(void input) => _repository.tryRestoreSession();
}

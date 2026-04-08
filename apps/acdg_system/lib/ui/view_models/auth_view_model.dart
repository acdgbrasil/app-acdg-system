import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import '../../logic/use_cases/auth_use_cases.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel({
    required this.authRepository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  }) : _status = authRepository.currentStatus,
       _user = authRepository.currentUser {
    login = Command0(() => loginUseCase.execute(null));
    logout = Command0(() => logoutUseCase.execute(null));
    restoreSession = Command0(() => restoreSessionUseCase.execute(null));

    _statusSubscription = authRepository.statusStream.listen(_onStatusChanged);
  }

  static final _log = AcdgLogger.get('AuthViewModel');
  final AuthRepository authRepository;
  StreamSubscription<AuthStatus>? _statusSubscription;

  AuthStatus _status;
  AuthUser? _user;

  AuthStatus get status => _status;
  AuthUser? get user => _user;

  late final Command0<void> login;
  late final Command0<void> logout;
  late final Command0<void> restoreSession;

  Future<void> init() async {
    _log.info('Initializing AuthViewModel...');
    await restoreSession.execute();
  }

  void _onStatusChanged(AuthStatus newStatus) {
    _log.info('Auth status changed: ${newStatus.runtimeType}');

    switch (newStatus) {
      case Authenticated(:final user):
        AcdgLogger.setUser(
          id: user.id,
          email: user.email,
          username: user.preferredUsername,
        );
        AcdgLogger.addBreadcrumb(
          message: 'User authenticated',
          category: 'auth',
        );
        _user = user;
      case AuthError(:final message):
        _log.severe('Authentication error: $message');
        AcdgLogger.clearUser();
        _user = null;
      case _:
        AcdgLogger.clearUser();
        _user = null;
    }

    _status = newStatus;
    notifyListeners();
  }

  @override
  void onDispose() {
    _log.info('Disposing AuthViewModel');
    _statusSubscription?.cancel();
    login.dispose();
    logout.dispose();
    restoreSession.dispose();
  }
}

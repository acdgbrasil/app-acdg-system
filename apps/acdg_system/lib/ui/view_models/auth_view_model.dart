import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import '../../logic/use_cases/auth_use_cases.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel({
    required this.authRepository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  })  : _status = authRepository.currentStatus,
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
    debugPrint('[AuthVM] init — current status: ${_status.runtimeType}');
    await restoreSession.execute();
    debugPrint('[AuthVM] init complete — status after restore: ${_status.runtimeType}');
  }

  void _onStatusChanged(AuthStatus newStatus) {
    debugPrint('[AuthVM] _onStatusChanged: ${newStatus.runtimeType}');

    if (newStatus is AuthError) {
      _log.severe('Authentication error: ${newStatus.message}');
    }

    _status = newStatus;
    _user = switch (newStatus) {
      Authenticated(:final user) => user,
      _ => null,
    };
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

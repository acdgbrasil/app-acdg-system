import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import '../../logic/use_cases/auth_use_cases.dart';

class AuthViewModel extends BaseViewModel {
  AuthViewModel({
    required this.authRepository,
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  }) {
    login = Command0(() => loginUseCase.execute(null));
    logout = Command0(() => logoutUseCase.execute(null));
    restoreSession = Command0(() => restoreSessionUseCase.execute(null));

    _statusSubscription = authRepository.statusStream.listen(_onStatusChanged);
  }

  final AuthRepository authRepository;
  StreamSubscription<AuthStatus>? _statusSubscription;

  final ValueNotifier<AuthStatus> status = ValueNotifier(const AuthLoading());
  final ValueNotifier<AuthUser?> user = ValueNotifier(null);

  late final Command0<void> login;
  late final Command0<void> logout;
  late final Command0<void> restoreSession;

  Future<void> init() async {
    await restoreSession.execute();
  }

  void _onStatusChanged(AuthStatus newStatus) {
    status.value = newStatus;
    user.value = switch (newStatus) {
      Authenticated(:final user) => user,
      _ => null,
    };
    notifyListeners();
  }

  @override
  void onDispose() {
    _statusSubscription?.cancel();
    login.dispose();
    logout.dispose();
    restoreSession.dispose();
    status.dispose();
    user.dispose();
  }
}

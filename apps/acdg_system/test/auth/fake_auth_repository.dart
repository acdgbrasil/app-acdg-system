import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

class FakeAuthRepository extends ChangeNotifier implements AuthRepository {
  final _controller = StreamController<AuthStatus>.broadcast();
  AuthStatus _status = const Unauthenticated();
  AuthUser? _user;

  bool loginShouldFail = false;
  bool hasExistingSession = false;

  @override
  Stream<AuthStatus> get statusStream => _controller.stream;

  @override
  AuthStatus get currentStatus => _status;

  @override
  AuthUser? get currentUser => _user;

  @override
  AuthToken? get currentToken => _user != null ? AuthToken(accessToken: 'fake-token', expiresAt: DateTime.now().add(const Duration(hours: 1))) : null;

  @override
  Future<Result<void>> login() async {
    if (loginShouldFail) {
      _emit(const AuthError('Login failed'));
      return const Failure('Login failed');
    }
    _user = const AuthUser(
      id: '1',
      name: 'Fake User',
      roles: {AuthRole.admin},
    );
    _emit(Authenticated(_user!));
    return const Success(null);
  }

  @override
  Future<Result<void>> logout() async {
    _user = null;
    _emit(const Unauthenticated());
    return const Success(null);
  }

  @override
  Future<Result<void>> tryRestoreSession() async {
    if (hasExistingSession) {
      _user = const AuthUser(
        id: '1',
        name: 'Fake User',
        roles: {AuthRole.admin},
      );
      _emit(Authenticated(_user!));
    } else {
      _emit(const Unauthenticated());
    }
    return const Success(null);
  }

  void _emit(AuthStatus status) {
    _status = status;
    _controller.add(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

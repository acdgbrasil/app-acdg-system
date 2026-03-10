import 'dart:async';

import 'package:core/core.dart';

/// Test double for [AuthService].
///
/// Allows controlling auth state imperatively in tests.
/// All methods complete synchronously by default.
class FakeAuthService implements AuthService {
  final _controller = StreamController<AuthStatus>.broadcast();

  AuthStatus _status = const Unauthenticated();
  AuthUser? _user;
  AuthToken? _token;

  /// Pre-configured user returned on [login].
  AuthUser loginUser = const AuthUser(
    id: 'test-user-123',
    name: 'Test User',
    email: 'test@acdg.com.br',
    roles: {AuthRole.socialWorker},
  );

  /// Pre-configured token returned on [login].
  AuthToken loginToken = AuthToken(
    accessToken: 'fake-access-token',
    refreshToken: 'fake-refresh-token',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
  );

  /// If true, [login] will emit [AuthError] instead of [Authenticated].
  bool loginShouldFail = false;

  /// If true, [tryRestoreSession] will emit [Authenticated].
  bool hasExistingSession = false;

  /// Error message used when [loginShouldFail] is true.
  String errorMessage = 'Login failed';

  @override
  Stream<AuthStatus> get statusStream => _controller.stream;

  @override
  AuthStatus get currentStatus => _status;

  @override
  AuthUser? get currentUser => _user;

  @override
  AuthToken? get currentToken => _token;

  @override
  Future<void> login() async {
    if (loginShouldFail) {
      _emit(AuthError(errorMessage));
      return;
    }
    _user = loginUser;
    _token = loginToken;
    _emit(Authenticated(loginUser));
  }

  @override
  Future<void> logout() async {
    _user = null;
    _token = null;
    _emit(const Unauthenticated());
  }

  @override
  Future<void> tryRestoreSession() async {
    if (hasExistingSession) {
      _user = loginUser;
      _token = loginToken;
      _emit(Authenticated(loginUser));
    } else {
      _emit(const Unauthenticated());
    }
  }

  @override
  Future<void> refreshToken() async {
    _token = loginToken;
  }

  void _emit(AuthStatus newStatus) {
    _status = newStatus;
    _controller.add(newStatus);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

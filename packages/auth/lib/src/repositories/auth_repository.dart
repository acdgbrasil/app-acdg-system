import 'dart:async';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for authentication data.
///
/// Encapsulates [AuthService] and handles data orchestration
/// (e.g., combining service state with local caches).
abstract class AuthRepository extends Listenable {
  /// Stream of authentication status changes.
  Stream<AuthStatus> get statusStream;

  /// Current authentication status.
  AuthStatus get currentStatus;

  /// Current authenticated user, or null.
  AuthUser? get currentUser;

  /// Current authentication token, or null.
  AuthToken? get currentToken;

  /// Initiates the login flow.
  Future<Result<void>> login();

  /// Logs out and clears the session.
  Future<Result<void>> logout();

  /// Attempts to restore a previous session.
  Future<Result<void>> tryRestoreSession();

  /// Initializes the underlying auth service.
  Future<void> init();

  /// Disposes of the repository.
  void dispose();
}

/// Production implementation of [AuthRepository].
class AuthRepositoryImpl extends ChangeNotifier implements AuthRepository {
  static final _log = AcdgLogger.get('AuthRepository');
  AuthRepositoryImpl({required AuthService authService})
    : _authService = authService {
    _statusSubscription = _authService.statusStream.listen(
      (_) => notifyListeners(),
    );
  }

  final AuthService _authService;
  late final StreamSubscription<AuthStatus> _statusSubscription;

  @override
  Future<void> init() => _authService.init();

  @override
  Stream<AuthStatus> get statusStream => _authService.statusStream;

  @override
  AuthStatus get currentStatus => _authService.currentStatus;

  @override
  AuthUser? get currentUser => _authService.currentUser;

  @override
  AuthToken? get currentToken => _authService.currentToken;

  @override
  Future<Result<void>> login() async {
    try {
      await _authService.login();
      return const Success(null);
    } catch (e, st) {
      _log.severe('Login failed', e, st);
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _authService.logout();
      return const Success(null);
    } catch (e, st) {
      _log.severe('Logout failed', e, st);
      return Failure(e);
    }
  }

  @override
  Future<Result<void>> tryRestoreSession() async {
    try {
      await _authService.tryRestoreSession();
      return const Success(null);
    } catch (e, st) {
      _log.severe('Session restore failed', e, st);
      return Failure(e);
    }
  }

  @override
  void dispose() {
    _statusSubscription.cancel();
    super.dispose();
  }
}

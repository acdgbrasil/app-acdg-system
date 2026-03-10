import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

/// ViewModel for authentication state in the Shell.
///
/// Consumes [AuthService] and exposes reactive state via
/// [ValueNotifier]s for atomic UI updates. Implements [Listenable]
/// so GoRouter can use it as `refreshListenable`.
///
/// Usage with Provider:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => AuthViewModel(authService: authService)..init(),
/// )
/// ```
class AuthViewModel extends BaseViewModel {
  AuthViewModel({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;
  StreamSubscription<AuthStatus>? _statusSubscription;

  /// Current authentication status (atomic).
  final ValueNotifier<AuthStatus> status =
      ValueNotifier(const AuthLoading());

  /// Current authenticated user, or `null`.
  final ValueNotifier<AuthUser?> user = ValueNotifier(null);

  /// Whether an auth operation is in progress.
  final ValueNotifier<bool> busy = ValueNotifier(false);

  /// Initializes the ViewModel by listening to auth status changes
  /// and attempting to restore a previous session.
  ///
  /// Must be called once after construction.
  Future<void> init() async {
    _statusSubscription = _authService.statusStream.listen(_onStatusChanged);
    await tryRestoreSession();
  }

  /// Initiates the OIDC login flow.
  Future<void> login() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _authService.login();
    } finally {
      busy.value = false;
    }
  }

  /// Logs out and clears the session.
  Future<void> logout() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _authService.logout();
    } finally {
      busy.value = false;
    }
  }

  /// Attempts to restore a previous session silently.
  ///
  /// Called during [init] and can be retried manually
  /// (e.g., after a network error on splash).
  Future<void> tryRestoreSession() async {
    busy.value = true;
    try {
      await _authService.tryRestoreSession();
    } finally {
      busy.value = false;
    }
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
    status.dispose();
    user.dispose();
    busy.dispose();
  }
}

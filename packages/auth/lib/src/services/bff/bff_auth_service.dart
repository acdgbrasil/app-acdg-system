import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../../models/auth_role.dart';
import '../../models/auth_status.dart';
import '../../models/auth_token.dart';
import '../../models/auth_user.dart';
import '../auth_service.dart';
import 'bff_auth_config.dart';

/// Web [AuthService] that delegates authentication to the BFF server.
///
/// Instead of performing OIDC flows in the browser, this service
/// communicates with the BFF's auth endpoints:
/// - login() -> redirects browser to BFF /auth/login
/// - logout() -> POST BFF /auth/logout
/// - tryRestoreSession() -> GET BFF /auth/me
/// - refreshToken() -> POST BFF /auth/refresh
///
/// Tokens are NEVER held in the browser. The BFF manages them
/// server-side with HttpOnly session cookies.
class BffAuthService implements AuthService {
  BffAuthService({required BffAuthConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client();

  final BffAuthConfig _config;
  final http.Client _httpClient;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // BFF auth doesn't need OIDC manager setup.
    // Just mark as initialized and let tryRestoreSession check
    // for an existing session.
    _updateStatus(const Unauthenticated());
  }

  @override
  Future<void> login() async {
    _updateStatus(const AuthLoading());
    // Navigate the browser to the BFF login endpoint.
    // The BFF redirects to Zitadel, which authenticates the user,
    // then redirects back to the BFF callback, which sets the session
    // cookie and redirects to /. The app reloads and tryRestoreSession()
    // picks up the authenticated session.
    web.window.location.href = loginUrl;
  }

  /// Returns the URL the browser should navigate to for login.
  String get loginUrl => '${_config.bffBaseUrl}/auth/login';

  @override
  Future<void> logout() async {
    try {
      await _httpClient.post(Uri.parse('${_config.bffBaseUrl}/auth/logout'));
    } catch (_) {
      // Best-effort logout
    }
    _clearSession();
  }

  @override
  Future<void> tryRestoreSession() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('${_config.bffBaseUrl}/auth/me'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final userId = json['userId'] as String;
        final rolesList = (json['roles'] as List<dynamic>).cast<String>();
        final roles = rolesList
            .map(AuthRole.fromString)
            .whereType<AuthRole>()
            .toSet();

        _currentUser = AuthUser(id: userId, roles: roles);
        _updateStatus(Authenticated(_currentUser!));
      } else {
        _clearSession();
      }
    } catch (_) {
      _clearSession();
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      final response = await _httpClient.post(
        Uri.parse('${_config.bffBaseUrl}/auth/refresh'),
      );
      if (response.statusCode != 200) {
        _clearSession();
      }
    } catch (_) {
      _clearSession();
    }
  }

  @override
  Stream<AuthStatus> get statusStream => _statusController.stream;

  @override
  AuthStatus get currentStatus => _currentStatus;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  AuthToken? get currentToken => null; // Tokens are managed server-side

  void _updateStatus(AuthStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _clearSession() {
    _currentUser = null;
    _updateStatus(const Unauthenticated());
  }

  @override
  void dispose() {
    _statusController.close();
  }
}

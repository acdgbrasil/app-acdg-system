import 'dart:async';

import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

import 'auth_role.dart';
import 'auth_service.dart';
import 'auth_status.dart';
import 'auth_token.dart';
import 'auth_user.dart';
import 'oidc_auth_config.dart';

/// Production [AuthService] backed by `package:oidc` (Bdaya-Dev).
///
/// Connects to Zitadel via OIDC Authorization Code + PKCE.
/// Manages the full auth lifecycle: login, logout, token refresh,
/// session restore, and auth state broadcasting.
class OidcAuthService implements AuthService {
  OidcAuthService({required OidcAuthConfig config}) : _config = config;

  final OidcAuthConfig _config;
  late final OidcUserManager _manager;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  StreamSubscription<OidcUser?>? _userSubscription;
  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  AuthToken? _currentToken;
  bool _initialized = false;

  /// Initializes the OIDC manager. Must be called before any other method.
  Future<void> init() async {
    if (_initialized) return;

    _manager = OidcUserManager.lazy(
      discoveryDocumentUri: _config.discoveryDocumentUri,
      clientCredentials:
          OidcClientAuthentication.none(clientId: _config.clientId),
      store: OidcDefaultStore(),
      settings: OidcUserManagerSettings(
        redirectUri: _config.redirectUri,
        postLogoutRedirectUri: _config.postLogoutRedirectUri,
        scope: _config.scopes,
        strictJwtVerification: false,
      ),
    );

    _userSubscription = _manager.userChanges().listen(_onUserChanged);

    await _manager.init();
    _initialized = true;
  }

  void _onUserChanged(OidcUser? oidcUser) {
    if (oidcUser == null) {
      _currentUser = null;
      _currentToken = null;
      _updateStatus(const Unauthenticated());
      return;
    }

    final claims = oidcUser.claims.toJson();
    final rolesMap = claims['urn:zitadel:iam:org:project:roles'];

    _currentUser = AuthUser(
      id: oidcUser.uid ?? claims['sub'] as String? ?? '',
      name: claims['name'] as String?,
      email: claims['email'] as String?,
      preferredUsername: claims['preferred_username'] as String?,
      roles: AuthRole.fromJwtClaim(
        rolesMap is Map<String, dynamic> ? rolesMap : null,
      ),
    );

    final token = oidcUser.token;
    _currentToken = AuthToken(
      accessToken: token.accessToken ?? '',
      refreshToken: token.refreshToken,
      idToken: token.idToken,
      expiresAt: token.calculateExpiresAt() ?? DateTime.now(),
    );

    _updateStatus(Authenticated(_currentUser!));
  }

  void _updateStatus(AuthStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // ---------- AuthService contract ----------

  @override
  Stream<AuthStatus> get statusStream => _statusController.stream;

  @override
  AuthStatus get currentStatus => _currentStatus;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  AuthToken? get currentToken => _currentToken;

  @override
  Future<void> login() async {
    _updateStatus(const AuthLoading());
    try {
      final user = await _manager.loginAuthorizationCodeFlow();
      if (user == null) {
        _updateStatus(const Unauthenticated());
      }
      // If user != null, _onUserChanged will handle the status update.
    } catch (e) {
      _updateStatus(AuthError('Falha ao fazer login: $e'));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _manager.logout();
    } catch (e) {
      // Even on error, clear local state.
      _currentUser = null;
      _currentToken = null;
      _updateStatus(const Unauthenticated());
    }
  }

  @override
  Future<void> tryRestoreSession() async {
    // The OidcUserManager.init() already restores the cached user.
    // If there's a current user after init, _onUserChanged was called.
    // If not, we're unauthenticated.
    if (_manager.currentUser == null) {
      _updateStatus(const Unauthenticated());
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      final user = await _manager.refreshToken();
      if (user == null) {
        _updateStatus(const Unauthenticated());
      }
    } catch (e) {
      _updateStatus(AuthError('Falha ao renovar token: $e'));
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _manager.dispose();
    _statusController.close();
  }
}

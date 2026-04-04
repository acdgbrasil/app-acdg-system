import 'dart:async';

import 'package:core/core.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';

import '../../models/auth_status.dart';
import '../../models/auth_token.dart';
import '../../models/auth_user.dart';
import '../auth_service.dart';
import 'oidc_auth_config.dart';
import 'oidc_claims_parser.dart';

/// Production [AuthService] backed by `package:oidc` (Bdaya-Dev).
///
/// Connects to Zitadel via OIDC Authorization Code + PKCE.
/// Manages the full auth lifecycle: login, logout, token refresh,
/// session restore, and auth state broadcasting.
class OidcAuthService implements AuthService {
  OidcAuthService({required OidcAuthConfig config}) : _config = config;

  static final _log = AcdgLogger.get('OidcAuthService');
  final OidcAuthConfig _config;
  late final OidcUserManager _manager;
  final StreamController<AuthStatus> _statusController =
      StreamController<AuthStatus>.broadcast();

  StreamSubscription<OidcUser?>? _userSubscription;
  AuthStatus _currentStatus = const AuthLoading();
  AuthUser? _currentUser;
  AuthToken? _currentToken;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    _log.info('Initializing OIDC Manager for issuer: ${_config.issuer}');

    _manager = OidcUserManager.lazy(
      discoveryDocumentUri: _config.discoveryDocumentUri,
      clientCredentials: OidcClientAuthentication.none(
        clientId: _config.clientId,
      ),
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
    _log.info('OIDC Manager initialized successfully');
    _initialized = true;
  }

  // ---------- JWT parsing ----------

  void _onUserChanged(OidcUser? oidcUser) {
    _log.info('User changed: ${oidcUser?.uid ?? "null"}');
    if (oidcUser == null || oidcUser.token.accessToken == null) {
      _clearSession();
      return;
    }

    try {
      final claims = oidcUser.claims.toJson();
      final user = OidcClaimsParser.userFromClaims(
        uid: oidcUser.uid,
        claims: claims,
      );
      final token = OidcClaimsParser.tokenFromRaw(
        accessToken: oidcUser.token.accessToken!,
        refreshToken: oidcUser.token.refreshToken,
        idToken: oidcUser.token.idToken,
        expiresAt: oidcUser.token.calculateExpiresAt(),
      );
      _setAuthenticatedSession(user, token);
    } catch (e) {
      _log.severe('Error parsing user claims: $e');
      _clearSession();
      _updateStatus(AuthError('Erro ao ler dados do usuário: $e'));
    }
  }

  // ---------- Predictable State Mutations ----------

  void _setAuthenticatedSession(AuthUser user, AuthToken token) {
    _log.info('Session authenticated for user: ${user.id}');
    _currentUser = user;
    _currentToken = token;
    _updateStatus(Authenticated(user));
  }

  void _clearSession() {
    _log.info('Session cleared');
    _currentUser = null;
    _currentToken = null;
    _updateStatus(const Unauthenticated());
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
    _log.info('Starting login flow...');
    _updateStatus(const AuthLoading());
    try {
      final user = await _manager.loginAuthorizationCodeFlow();
      if (user == null) {
        _log.warning('Login flow cancelled or returned null user');
        _clearSession();
      }
    } catch (e) {
      _log.severe('Login flow error: $e');
      _clearSession();
      _updateStatus(AuthError('Falha ao fazer login: $e'));
    }
  }

  @override
  Future<void> logout() async {
    _log.info('Starting logout flow...');
    try {
      await _manager.logout();
    } catch (e) {
      _log.warning('Logout flow error (ignoring): $e');
    } finally {
      _clearSession();
    }
  }

  @override
  Future<void> tryRestoreSession() async {
    _log.info('Attempting to restore session...');
    if (_manager.currentUser == null) {
      _log.info('No session found to restore');
      _clearSession();
    } else {
      _log.info('Session found for user: ${_manager.currentUser!.uid}');
    }
  }

  @override
  Future<void> refreshToken() async {
    _log.info('Refreshing token...');
    try {
      final user = await _manager.refreshToken();
      if (user == null) {
        _log.warning('Token refresh returned null user');
        _clearSession();
      }
    } catch (e) {
      _log.severe('Token refresh error: $e');
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

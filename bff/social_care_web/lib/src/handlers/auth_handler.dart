import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../auth/oidc_server_client.dart';
import '../auth/session_store.dart';
import '../middleware/session_middleware.dart';

/// Zitadel roles claim key in ID tokens.
const String _rolesClaim = 'urn:zitadel:iam:org:project:roles';

/// Temporary PKCE state stored between login redirect and callback.
class _PkceState {
  const _PkceState({required this.codeVerifier, required this.createdAt});

  final String codeVerifier;
  final DateTime createdAt;
}

/// Handles OIDC authentication flow endpoints.
///
/// Routes:
/// - `GET  /auth/login`    - Redirect to Zitadel authorization
/// - `GET  /auth/callback` - Handle Zitadel callback, create session
/// - `POST /auth/logout`   - Destroy session, revoke token
/// - `GET  /auth/me`       - Return current user info
/// - `POST /auth/refresh`  - Refresh tokens
class AuthHandler {
  AuthHandler({
    required OidcServerClient oidcClient,
    required SessionStore sessionStore,
    String? cookieDomain,
    String? postLoginRedirectUrl,
    bool secureCookies = true,
  }) : _oidcClient = oidcClient,
       _sessionStore = sessionStore,
       _cookieDomain = cookieDomain,
       _postLoginRedirectUrl = postLoginRedirectUrl ?? '/',
       _secureCookies = secureCookies;

  final OidcServerClient _oidcClient;
  final SessionStore _sessionStore;
  final String? _cookieDomain;
  final String _postLoginRedirectUrl;
  final bool _secureCookies;
  final Random _random = Random.secure();

  /// In-memory PKCE state store: state -> PkceState.
  /// Short-lived (cleaned up on access).
  final Map<String, _PkceState> _pkceStates = {};

  /// Maximum age for PKCE states before cleanup (5 minutes).
  static const Duration _pkceStateTtl = Duration(minutes: 5);

  Router get router {
    final r = Router();
    r.get('/auth/login', _login);
    r.get('/auth/callback', _callback);
    r.post('/auth/logout', _logout);
    r.get('/auth/me', _me);
    r.post('/auth/refresh', _refresh);
    return r;
  }

  /// GET /auth/login
  ///
  /// Generates PKCE verifier+challenge, stores them in a temp state,
  /// redirects user to Zitadel authorization URL.
  Future<Response> _login(Request request) async {
    _cleanupExpiredPkceStates();

    final state = _generateRandomString();
    final codeVerifier = _generateCodeVerifier();

    _pkceStates[state] = _PkceState(
      codeVerifier: codeVerifier,
      createdAt: DateTime.now().toUtc(),
    );

    final authUrl = _oidcClient.buildAuthorizationUrl(
      state: state,
      codeVerifier: codeVerifier,
    );

    return Response(302, headers: {'Location': authUrl.toString()});
  }

  /// GET /auth/callback
  ///
  /// Receives authorization code from Zitadel, exchanges for tokens,
  /// creates session, sets HttpOnly cookie.
  Future<Response> _callback(Request request) async {
    final code = request.requestedUri.queryParameters['code'];
    final state = request.requestedUri.queryParameters['state'];

    if (code == null || code.isEmpty) {
      return _jsonError(400, 'Missing authorization code');
    }

    if (state == null || state.isEmpty) {
      return _jsonError(400, 'Missing state parameter');
    }

    final pkceState = _pkceStates.remove(state);
    if (pkceState == null) {
      return _jsonError(400, 'Invalid or expired state parameter');
    }

    try {
      final tokenResponse = await _oidcClient.exchangeCode(
        code,
        codeVerifier: pkceState.codeVerifier,
      );

      final claims = _oidcClient.parseIdTokenClaims(tokenResponse.idToken);
      final userId = claims['sub'] as String;
      final roles = _extractRoles(claims);

      final sessionId = _sessionStore.create(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        userId: userId,
        roles: roles,
      );

      return Response(
        302,
        headers: {
          'Location': _postLoginRedirectUrl,
          'Set-Cookie': _buildSessionCookie(sessionId),
        },
      );
    } on OidcException catch (e) {
      return _jsonError(502, 'Token exchange failed: ${e.error}');
    }
  }

  /// POST /auth/logout
  ///
  /// Destroys session, clears cookie, revokes token.
  Future<Response> _logout(Request request) async {
    final session = request.context[sessionContextKey] as Session?;

    if (session != null) {
      // Revoke refresh token at Zitadel (best-effort)
      try {
        await _oidcClient.revokeToken(session.refreshToken);
      } catch (_) {
        // Revocation failure should not block logout
      }

      _sessionStore.destroy(session.id);
    }

    return Response.ok(
      jsonEncode({'message': 'Logged out'}),
      headers: {
        'Content-Type': 'application/json',
        'Set-Cookie': _buildClearSessionCookie(),
      },
    );
  }

  /// GET /auth/me
  ///
  /// Returns current user info from session.
  Future<Response> _me(Request request) async {
    final session = request.context[sessionContextKey] as Session?;

    if (session == null) {
      return _jsonError(401, 'Valid session required');
    }

    return Response.ok(
      jsonEncode({'userId': session.userId, 'roles': session.roles.toList()}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// POST /auth/refresh
  ///
  /// Refreshes tokens using session's refresh token.
  Future<Response> _refresh(Request request) async {
    final session = request.context[sessionContextKey] as Session?;

    if (session == null) {
      return _jsonError(401, 'Valid session required');
    }

    try {
      final tokenResponse = await _oidcClient.refreshToken(
        session.refreshToken,
      );

      final updated = _sessionStore.updateTokens(
        session.id,
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
      );

      if (!updated) {
        return _jsonError(409, 'Session expired or no longer valid');
      }

      return Response.ok(
        jsonEncode({'message': 'Tokens refreshed'}),
        headers: {'Content-Type': 'application/json'},
      );
    } on OidcException catch (e) {
      return _jsonError(502, 'Token refresh failed: ${e.error}');
    }
  }

  /// Extracts role names from Zitadel's roles claim.
  ///
  /// The claim format is: `{ "role_name": { "org_id": "org_name" } }`.
  /// We extract only the top-level keys as role names.
  Set<String> _extractRoles(Map<String, dynamic> claims) {
    final rolesMap = claims[_rolesClaim];
    if (rolesMap is Map) {
      return rolesMap.keys.cast<String>().toSet();
    }
    return {};
  }

  /// Builds the `Set-Cookie` header value for the session cookie.
  String _buildSessionCookie(String sessionId) {
    final parts = [
      '__session=$sessionId',
      'HttpOnly',
      'Path=/',
    ];
    if (_secureCookies) {
      parts.addAll(['Secure', 'SameSite=Strict']);
    } else {
      // Local dev: HTTP (no Secure), Lax (cross-port requests)
      parts.add('SameSite=Lax');
    }
    if (_cookieDomain != null) {
      parts.add('Domain=$_cookieDomain');
    }
    return parts.join('; ');
  }

  /// Builds the `Set-Cookie` header value to clear the session cookie.
  String _buildClearSessionCookie() {
    final parts = [
      '__session=',
      'HttpOnly',
      'Path=/',
      'Max-Age=0',
    ];
    if (_secureCookies) {
      parts.addAll(['Secure', 'SameSite=Strict']);
    } else {
      parts.add('SameSite=Lax');
    }
    if (_cookieDomain != null) {
      parts.add('Domain=$_cookieDomain');
    }
    return parts.join('; ');
  }

  /// Returns a JSON error response.
  Response _jsonError(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Generates a cryptographically secure random hex string for state.
  String _generateRandomString() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generates a PKCE code verifier.
  String _generateCodeVerifier() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Removes PKCE states older than [_pkceStateTtl].
  void _cleanupExpiredPkceStates() {
    final now = DateTime.now().toUtc();
    _pkceStates.removeWhere(
      (_, state) => now.difference(state.createdAt) > _pkceStateTtl,
    );
  }
}

import '../models/auth_status.dart';
import '../models/auth_token.dart';
import '../models/auth_user.dart';

/// Contract for authentication services.
///
/// Abstracts the OIDC provider (Zitadel) behind a protocol so the
/// shell and features never depend on a concrete implementation.
///
/// **Lifecycle:** call [init] before any other method, then
/// [tryRestoreSession] to check for a cached session.
///
/// Implementations:
/// - `OidcAuthService` — production (package:oidc + Zitadel)
/// - `FakeAuthService` — tests
abstract class AuthService {
  /// Initializes the service (e.g., creates OIDC manager, restores cache).
  ///
  /// Must be called once before [login], [logout], [tryRestoreSession],
  /// or [refreshToken]. Subsequent calls are no-ops.
  Future<void> init();

  /// Stream of authentication status changes.
  ///
  /// Emits whenever the user logs in, logs out, or the session
  /// is refreshed/expired. Used by GoRouter's refresh mechanism.
  Stream<AuthStatus> get statusStream;

  /// Current authentication status (synchronous snapshot).
  AuthStatus get currentStatus;

  /// Current authenticated user, or `null` if not logged in.
  AuthUser? get currentUser;

  /// Current token set, or `null` if not authenticated.
  ///
  /// On web, the refresh token may be `null` (managed via HttpOnly cookie).
  AuthToken? get currentToken;

  /// Initiates the OIDC Authorization Code + PKCE flow.
  ///
  /// Opens the Zitadel login page. On success, emits [Authenticated]
  /// to [statusStream]. On failure, emits [AuthError].
  Future<void> login();

  /// Ends the session and revokes tokens.
  ///
  /// Emits [Unauthenticated] to [statusStream].
  Future<void> logout();

  /// Attempts to restore a previous session silently.
  ///
  /// On desktop: reads tokens from secure storage.
  /// On web: triggers a refresh via the HttpOnly cookie.
  /// Called at app startup (splash screen).
  Future<void> tryRestoreSession();

  /// Forces a token refresh.
  ///
  /// Usually handled automatically by the OIDC manager, but
  /// exposed for edge cases (e.g., 401 interceptor).
  Future<void> refreshToken();

  /// Releases resources (stream controllers, listeners).
  void dispose();
}

import 'package:core/core.dart';

/// Token set returned by the Zitadel OIDC flow.
///
/// Immutable model holding the access token (short-lived, memory-only)
/// and optional refresh/ID tokens.
final class AuthToken with Equatable {
  const AuthToken({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  /// Bearer token for API requests.
  final String accessToken;

  /// Refresh token for silent renewal.
  ///
  /// On web: stored in HttpOnly cookie (Split-Token pattern), so this
  /// field may be `null` after page refresh — the cookie handles it.
  /// On desktop: persisted via flutter_secure_storage.
  final String? refreshToken;

  /// Raw ID token containing user claims.
  final String? idToken;

  /// Absolute expiration time of the access token.
  final DateTime expiresAt;

  @override
  List<Object?> get props => [accessToken, refreshToken, idToken, expiresAt];

  /// Whether the access token has expired.
  ///
  /// Accepts an optional [now] for deterministic testing.
  bool isExpired({DateTime? now}) => (now ?? DateTime.now()).isAfter(expiresAt);

  /// Whether the access token will expire within the given [threshold].
  ///
  /// Useful for proactive refresh (e.g., refresh 30s before expiry).
  /// Accepts an optional [now] for deterministic testing.
  bool expiresWithin(Duration threshold, {DateTime? now}) =>
      (now ?? DateTime.now()).isAfter(expiresAt.subtract(threshold));

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([refreshToken], [idToken]) use `ValueGetter`
  /// so they can be explicitly set to `null`:
  /// ```dart
  /// token.copyWith(refreshToken: () => null) // clears refreshToken
  /// token.copyWith(refreshToken: () => 'new') // sets new value
  /// ```
  AuthToken copyWith({
    String? accessToken,
    String? Function()? refreshToken,
    String? Function()? idToken,
    DateTime? expiresAt,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken != null ? refreshToken() : this.refreshToken,
      idToken: idToken != null ? idToken() : this.idToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Custom toString to avoid exposing token values in logs.
  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt, expired: ${isExpired()})';
}

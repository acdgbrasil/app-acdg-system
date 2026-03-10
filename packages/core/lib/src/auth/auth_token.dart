/// Token set returned by the Zitadel OIDC flow.
///
/// Immutable model holding the access token (short-lived, memory-only)
/// and optional refresh/ID tokens.
final class AuthToken {
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

  /// Whether the access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the access token will expire within the given [threshold].
  ///
  /// Useful for proactive refresh (e.g., refresh 30s before expiry).
  bool expiresWithin(Duration threshold) =>
      DateTime.now().isAfter(expiresAt.subtract(threshold));

  AuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiresAt,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthToken &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.idToken == idToken &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, idToken, expiresAt);

  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt, expired: $isExpired)';
}

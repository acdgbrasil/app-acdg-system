import '../../models/auth_role.dart';
import '../../models/auth_token.dart';
import '../../models/auth_user.dart';

/// Pure functions that convert raw OIDC/JWT data into domain models.
///
/// Extracted from [OidcAuthService] to allow unit testing without
/// initializing the OIDC manager or depending on `package:oidc` types.
class OidcClaimsParser {
  const OidcClaimsParser._();

  /// Builds an [AuthUser] from raw JWT claims.
  ///
  /// [uid] is the OIDC provider's user identifier (may be null).
  /// [claims] is the decoded ID token payload as a JSON map.
  static AuthUser userFromClaims({
    required String? uid,
    required Map<String, dynamic> claims,
  }) {
    final rolesMap = claims['urn:zitadel:iam:org:project:roles'];

    return AuthUser(
      id: uid ?? claims['sub'] as String? ?? '',
      name: claims['name'] as String?,
      email: claims['email'] as String?,
      preferredUsername: claims['preferred_username'] as String?,
      roles: AuthRole.fromJwtClaim(
        rolesMap is Map<String, dynamic> ? rolesMap : null,
      ),
    );
  }

  /// Builds an [AuthToken] from raw token data.
  ///
  /// [accessToken] must not be null (caller should guard before calling).
  /// [expiresAt] falls back to `DateTime.now()` if the provider
  /// does not supply an expiration.
  static AuthToken tokenFromRaw({
    required String accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? expiresAt,
  }) {
    return AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresAt: expiresAt ?? DateTime.now(),
    );
  }
}

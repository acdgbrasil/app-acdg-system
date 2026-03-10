/// Roles available in the ACDG Zitadel project.
///
/// Extracted from the JWT claim `urn:zitadel:iam:org:project:roles`.
/// Each role maps to a set of permissions in the social-care API.
enum AuthRole {
  /// Full CRUD access to all social-care modules.
  socialWorker('social_worker'),

  /// Read-only access to social-care data.
  owner('owner'),

  /// Read access to social-care + admin area.
  admin('admin');

  const AuthRole(this.value);

  /// The raw string value as it appears in the JWT claim.
  final String value;

  /// Resolves an [AuthRole] from its JWT string representation.
  ///
  /// Returns `null` if the value does not match any known role.
  static AuthRole? fromString(String value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }

  /// Extracts all known roles from the raw JWT roles map.
  ///
  /// The JWT claim format is `Map<String, Map<String, String>>` where
  /// outer keys are role names. Unknown roles are silently ignored.
  static Set<AuthRole> fromJwtClaim(Map<String, dynamic>? claim) {
    if (claim == null) return {};
    final roles = <AuthRole>{};
    for (final key in claim.keys) {
      final role = fromString(key);
      if (role != null) roles.add(role);
    }
    return roles;
  }
}

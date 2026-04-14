/// Roles available in the ACDG Zitadel project.
///
/// Extracted from the JWT claim `urn:zitadel:iam:org:project:roles`.
/// Since the RBAC migration, roles arrive as composite keys:
/// `{system}:{role}` (e.g. `social-care:worker`, `social-care:admin`).
/// The global `superadmin` role has no system prefix.
enum AuthRole {
  /// Global superadmin — bypasses all system-level checks.
  superAdmin('superadmin'),

  /// Worker with CRUD access within a system.
  worker('worker'),

  /// Read-only access within a system.
  owner('owner'),

  /// Admin access within a system (read + management).
  admin('admin');

  const AuthRole(this.value);

  /// The raw string value as it appears in the JWT claim (suffix only).
  final String value;

  /// Resolves an [AuthRole] from its JWT string representation.
  ///
  /// Supports composite keys: `"social-care:worker"` → extracts `"worker"`.
  /// Returns `null` if the value does not match any known role.
  static AuthRole? fromString(String value) {
    final simple = value.contains(':') ? value.split(':').last : value;
    return values.where((role) => role.value == simple).firstOrNull;
  }

  /// Extracts all known roles from the raw JWT roles map.
  ///
  /// The JWT claim format is `Map<String, Map<String, String>>` where
  /// outer keys are role names (now composite: `system:role`).
  /// Unknown roles are silently ignored.
  static Set<AuthRole> fromJwtClaim(Map<String, dynamic>? claim) {
    if (claim == null) return const {};
    return claim.keys.map(fromString).nonNulls.toSet();
  }
}

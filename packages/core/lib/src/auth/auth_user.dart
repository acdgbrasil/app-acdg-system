import 'auth_role.dart';

/// Authenticated user extracted from Zitadel OIDC tokens.
///
/// Immutable model combining identity claims (from ID token)
/// with authorization roles (from the project roles claim).
final class AuthUser {
  const AuthUser({
    required this.id,
    required this.roles,
    this.name,
    this.email,
    this.preferredUsername,
  });

  /// Zitadel subject identifier (`sub` claim).
  final String id;

  /// Display name (`name` claim from `profile` scope).
  final String? name;

  /// Email address (`email` claim from `email` scope).
  final String? email;

  /// Username (`preferred_username` claim from `profile` scope).
  final String? preferredUsername;

  /// Resolved roles from `urn:zitadel:iam:org:project:roles`.
  final Set<AuthRole> roles;

  /// Best available display label for the UI.
  String get displayName => name ?? preferredUsername ?? email ?? id;

  bool hasRole(AuthRole role) => roles.contains(role);

  bool hasAnyRole(Set<AuthRole> required) => roles.intersection(required).isNotEmpty;

  /// Whether this user can write data in social-care modules.
  bool get canWrite => hasRole(AuthRole.socialWorker);

  /// Whether this user can read social-care data.
  bool get canRead => roles.isNotEmpty;

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    String? preferredUsername,
    Set<AuthRole>? roles,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      preferredUsername: preferredUsername ?? this.preferredUsername,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.preferredUsername == preferredUsername &&
          other.roles.length == roles.length &&
          other.roles.containsAll(roles);

  @override
  int get hashCode => Object.hash(id, name, email, preferredUsername, Object.hashAll(roles));

  @override
  String toString() => 'AuthUser(id: $id, name: $name, roles: $roles)';
}

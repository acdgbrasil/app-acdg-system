import 'package:core/core.dart';

import 'auth_role.dart';

/// Authenticated user extracted from Zitadel OIDC tokens.
///
/// Immutable model combining identity claims (from ID token)
/// with authorization roles (from the project roles claim).
final class AuthUser with Equatable {
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

  @override
  List<Object?> get props => [id, name, email, preferredUsername, ...roles];

  /// Best available display label for the UI.
  String get displayName => name ?? preferredUsername ?? email ?? id;

  bool hasRole(AuthRole role) => roles.contains(role);

  bool hasAnyRole(Set<AuthRole> required) =>
      roles.intersection(required).isNotEmpty;

  /// Whether this user can write data in social-care modules.
  bool get canWrite => hasRole(AuthRole.socialWorker);

  /// Whether this user can read social-care data.
  bool get canRead => roles.isNotEmpty;

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields ([name], [email], [preferredUsername]) use
  /// `ValueGetter` so they can be explicitly set to `null`:
  /// ```dart
  /// user.copyWith(name: () => null)   // clears name
  /// user.copyWith(name: () => 'Ana')  // sets new value
  /// ```
  AuthUser copyWith({
    String? id,
    String? Function()? name,
    String? Function()? email,
    String? Function()? preferredUsername,
    Set<AuthRole>? roles,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name != null ? name() : this.name,
      email: email != null ? email() : this.email,
      preferredUsername: preferredUsername != null
          ? preferredUsername()
          : this.preferredUsername,
      roles: roles ?? this.roles,
    );
  }

  @override
  String toString() => 'AuthUser(id: $id, name: $name, roles: $roles)';
}

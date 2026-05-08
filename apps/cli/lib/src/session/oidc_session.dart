/// `OidcSession` — the authenticated user's persisted session.
///
/// Replaces the C01 `Credentials` struct. Holds the access/refresh/id
/// tokens plus identity claims extracted from the id_token at login time
/// (`sub`, `email`, `roles`). The CLI reads identity claims locally for
/// display (`acdg auth status`); it does NOT rely on them for security
/// decisions — the BFF Bearer middleware is the source of truth.
///
/// JSON shape uses snake_case keys for interoperability with the Zitadel
/// token response and so an operator can `cat ~/.config/acdg/credentials`
/// and recognise the fields.
library;

import 'package:core_contracts/core_contracts.dart';

/// Immutable session value persisted at `$XDG_CONFIG_HOME/acdg/credentials`.
final class OidcSession with Equatable {
  const OidcSession({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
    required this.accessExpiresAt,
    required this.sub,
    required this.email,
    required this.roles,
  });

  /// JSON deserializer — surfaces a [FormatException] (not a [TypeError])
  /// when a required field is missing or has the wrong shape so
  /// `FileCredentialStore.read()` can drop the corrupt file via the same
  /// `on FormatException` clause it already uses.
  factory OidcSession.fromJson(Map<String, Object?> json) {
    final accessToken = _stringField(json, 'access_token');
    final refreshToken = _stringField(json, 'refresh_token');
    final idToken = _stringField(json, 'id_token');
    final accessExpiresAtRaw = _stringField(json, 'access_expires_at');
    final sub = _stringField(json, 'sub');
    final email = _stringField(json, 'email');
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    final DateTime accessExpiresAt;
    try {
      accessExpiresAt = DateTime.parse(accessExpiresAtRaw);
      // ignore: unused_catch_stack
    } on FormatException catch (e, st) {
      throw FormatException(
        'OidcSession: invalid access_expires_at — ${e.message}',
      );
    }
    return OidcSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      accessExpiresAt: accessExpiresAt,
      sub: sub,
      email: email,
      roles: roles,
    );
  }

  static String _stringField(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('OidcSession: missing or non-string field "$key"');
  }

  final String accessToken;
  final String refreshToken;
  final String idToken;

  /// Access-token expiry — UTC. Used by [isExpired] to drive the proactive
  /// refresh window.
  final DateTime accessExpiresAt;

  /// `sub` claim from the id_token — the Zitadel user id.
  final String sub;

  /// `email` claim from the id_token. Surfaced by `acdg auth status`.
  final String email;

  /// Role names extracted from `urn:zitadel:iam:org:project:roles`. Sorted
  /// alphabetically at write time so equality is deterministic.
  final List<String> roles;

  /// JSON serializer — round-trip stable with [OidcSession.fromJson].
  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'id_token': idToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'sub': sub,
    'email': email,
    'roles': roles,
  };

  /// True when `now >= accessExpiresAt - 60s` — the proactive-refresh
  /// window. The 60s buffer matches spike §5.13: refresh BEFORE the
  /// token would otherwise be rejected by the BFF.
  ///
  /// `now` is injected so tests are deterministic; real callers pass
  /// `DateTime.now().toUtc()` (or omit and let the impl call it).
  bool isExpired({DateTime? now}) {
    final clock = now ?? DateTime.now().toUtc();
    final threshold = accessExpiresAt.subtract(const Duration(seconds: 60));
    return !clock.isBefore(threshold);
  }

  @override
  List<Object?> get props => [
    accessToken,
    refreshToken,
    idToken,
    accessExpiresAt,
    sub,
    email,
    roles,
  ];
}

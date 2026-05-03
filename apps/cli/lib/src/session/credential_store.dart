/// Credential persistence for the CLI session — D5 (XDG path).
///
/// C01 ships:
///   * [Credentials] — immutable triple (access/refresh tokens + expiry).
///   * [CredentialStore] — sub-contract per ENCAPSULATION_POLICY H5
///     (`abstract interface class`, foreign-implementable).
///   * [FileCredentialStore] — JSON-on-disk implementation with chmod 600
///     (best-effort; skipped on Windows) + XDG path resolution.
///
/// PKCE acquisition + refresh-on-401 land in C02. C01 only needs the
/// read/write/clear surface so other layers (BffClient, AuthCommand stub)
/// can compile.
library;

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

/// Immutable token triple persisted between CLI invocations.
///
/// `with Equatable` so tests can assert structural equality (and the value
/// can ride inside a [Result] without bespoke `==` overrides).
final class Credentials with Equatable {
  Credentials({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// JSON deserializer — used by [FileCredentialStore.read].
  factory Credentials.fromJson(Map<String, Object?> json) => Credentials(
    accessToken: json['accessToken']! as String,
    refreshToken: json['refreshToken']! as String,
    expiresAt: DateTime.parse(json['expiresAt']! as String),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// JSON serializer — used by [FileCredentialStore.write].
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt];
}

/// Sub-contract for credential persistence.
///
/// `abstract interface class` (H5) so foreign packages — including the C02
/// PKCE flow and the test suite — can `implements CredentialStore` without
/// inheriting any state.
abstract interface class CredentialStore {
  /// Returns persisted credentials, or `null` if none exist.
  Future<Credentials?> read();

  /// Persists [credentials], replacing any prior value.
  Future<void> write(Credentials credentials);

  /// Removes the persisted credentials (no-op when absent).
  Future<void> clear();
}

/// File-backed [CredentialStore] living at [path].
///
/// File I/O is the one place `try/catch` is allowed (adapter boundary):
/// corrupt JSON → treated as "no credentials" so the user can recover by
/// re-running `acdg auth login`.
final class FileCredentialStore implements CredentialStore {
  FileCredentialStore({required this.path});

  /// Absolute path to the credentials file.
  final String path;

  /// Resolves the default XDG path: `XDG_CONFIG_HOME/acdg/credentials`,
  /// falling back to `$HOME/.config/acdg/credentials` when XDG is unset
  /// or empty.
  ///
  /// [env] is required (not pulled from `Platform.environment`) so tests
  /// drive every branch deterministically. Production callers pass
  /// `Platform.environment`.
  static String defaultPath({required Map<String, String> env}) {
    final xdg = env['XDG_CONFIG_HOME'];
    final home = env['HOME'] ?? '';
    final base = (xdg != null && xdg.isNotEmpty) ? xdg : '$home/.config';
    return '$base/acdg/credentials';
  }

  @override
  Future<Credentials?> read() async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, Object?>;
      return Credentials.fromJson(json);
    } on FormatException {
      // Corrupt JSON — caller should re-authenticate.
      return null;
    } on FileSystemException {
      // Race with concurrent delete / unreadable — treat as missing.
      return null;
    }
  }

  @override
  Future<void> write(Credentials credentials) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(credentials.toJson()));
    if (!Platform.isWindows) {
      // Best-effort chmod 600; ignore failures (filesystem may not support).
      try {
        await Process.run('chmod', ['600', path]);
      } on ProcessException {
        // Non-fatal — credentials are still written.
      }
    }
  }

  @override
  Future<void> clear() async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

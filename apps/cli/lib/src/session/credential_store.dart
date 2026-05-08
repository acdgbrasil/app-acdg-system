/// Credential persistence for the CLI session — D5 (XDG path).
///
/// C02 evolution (Strategy A): the C01 `Credentials` struct is replaced
/// by [OidcSession] (richer: id_token + sub + email + roles + expiry).
/// The store contract is identical at the verb level (`read/write/clear`),
/// only the value type changes. Tests that previously worked on
/// `Credentials` MUST be migrated to `OidcSession` fixtures.
///
/// Pre-C02 credentials files (3 fields: accessToken, refreshToken,
/// expiresAt) fail to parse here and the read returns `null` — treated
/// as "no session". The user re-runs `acdg auth login`, no migration
/// dance, no hard error.
library;

import 'dart:convert';
import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import 'keychain_adapter.dart';
import 'oidc_session.dart';

/// Sub-contract for credential persistence.
///
/// `abstract interface class` (H5) so foreign packages — including the
/// PKCE flow and the test suite — can `implements CredentialStore`
/// without inheriting any state.
abstract interface class CredentialStore {
  /// Returns the persisted session, or `null` if none / corrupt.
  Future<OidcSession?> read();

  /// Persists [session], replacing any prior value.
  Future<void> write(OidcSession session);

  /// Removes the persisted session (no-op when absent).
  Future<void> clear();
}

/// File-backed [CredentialStore] living at [path].
///
/// File I/O is the one place `try/catch` is allowed (adapter boundary):
/// corrupt JSON or stale C01-shape file → treated as "no session" so the
/// user can recover by re-running `acdg auth login`.
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
  Future<OidcSession?> read() async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, Object?>) return null;
      return OidcSession.fromJson(decoded);
    } on FormatException {
      // Corrupt JSON or pre-C02 (3-field) shape — caller should re-auth.
      return null;
    } on FileSystemException {
      // Race with concurrent delete / unreadable — treat as missing.
      return null;
    }
  }

  @override
  Future<void> write(OidcSession session) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(session.toJson()));
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

/// [CredentialStore] backed by a [KeychainAdapter] — B4 production path.
///
/// Bridges the existing `Future<void>` contract that `BffClient` and the
/// auth subcommands rely on into the Result-typed [KeychainAdapter]
/// surface.
///
/// Failure semantics (per B4 002-tests REPORT.md §"KeychainCredentialStore
/// wrapper"):
///   * [read] — `Failure(...)` → `null`. Treats keychain failure as "no
///     session" so the CLI surfaces `AuthRequiredError` (exit code 7) at
///     the next BFF call. Stderr gets a hint so the operator knows.
///   * [write] — `Failure(...)` → `throw StateError(...)`. Fail-loud:
///     silently swallowing a write failure would lose the user's session
///     without warning, which is strictly worse than crashing.
///   * [clear] — idempotent regardless of adapter result. Subsequent
///     [read] returns `null` and the user can re-auth.
final class KeychainCredentialStore implements CredentialStore {
  KeychainCredentialStore({required KeychainAdapter adapter})
    : _adapter = adapter;

  final KeychainAdapter _adapter;

  @override
  Future<OidcSession?> read() async {
    final result = await _adapter.read();
    return switch (result) {
      Success<OidcSession?>(:final value) => value,
      Failure<OidcSession?>(:final error) => () {
        // SEC: no silent fallback to plaintext. Surface a hint so the
        // operator knows why re-auth is needed; never log the session
        // itself (the adapter never returns it on failure anyway).
        stderr.writeln('acdg: keychain read failed — $error');
        return null;
      }(),
    };
  }

  @override
  Future<void> write(OidcSession session) async {
    final result = await _adapter.write(session);
    switch (result) {
      case Success<void>():
        return;
      case Failure<void>(:final error):
        // SEC: fail-loud. Losing tokens silently is the bug we are
        // fixing in B4 — surfacing the StateError makes the failure
        // visible to the auth-login command, which exits non-zero.
        throw StateError('keychain write failed: $error');
    }
  }

  @override
  Future<void> clear() async {
    // Idempotent — even on Failure, the next read returns `null` and
    // the user re-authenticates. Swallow the result.
    await _adapter.delete();
  }
}

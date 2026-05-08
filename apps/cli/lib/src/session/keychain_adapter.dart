/// Platform-native secret store adapter — B4 keychain interface.
///
/// Implementations shell out to OS-shipped binaries (`security`,
/// `secret-tool`, `powershell.exe`). All three methods return [Result];
/// adapter exceptions never escape (translated at the boundary).
///
/// Naming convention (locked by D3 in 000-discuss/CONTEXT.md):
///   * `service` — reverse-DNS, e.g. `com.acdgbrasil.acdg-cli`.
///   * `account` — `<oidc-issuer-host>`, e.g. `auth.acdgbrasil.com.br`.
///
/// Storage shape (D4): a single JSON blob holding the entire
/// [OidcSession.toJson()] map; atomic — either the whole session is
/// readable or it isn't.
library;

import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import 'oidc_session.dart';

/// Function-typed dependency for `Process.run` / `Process.start`.
///
/// Production adapters default to a wrapper that uses the explicit
/// `Process.run(exe, [args])` form (or `Process.start` + stdin pipe when
/// [stdinPayload] is supplied) — never `runInShell: true`, never any
/// string interpolation. Tests inject a fake to record the (argv,
/// stdinPayload) pair and dispense canned [ProcessResult]s.
///
/// SEC: every concrete invocation MUST honour:
///   * the `(executable, [arguments])` form — no shell parses argv;
///   * `runInShell: false` (Dart default; explicit at every call site);
///   * if [stdinPayload] is non-null, the secret reaches the child
///     exclusively via stdin pipe — never on argv.
typedef ProcessRunner =
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments, {
      String? stdinPayload,
    });

/// Three-method contract every B4 keychain adapter implements.
abstract interface class KeychainAdapter {
  /// Upserts the [session]. Replaces any prior entry under the same
  /// `(service, account)` pair.
  ///
  /// Returns [Failure] on keychain unavailability or operation error;
  /// the caller decides whether to fail-loud or surface the hint.
  Future<Result<void>> write(OidcSession session);

  /// Reads the persisted [OidcSession].
  ///
  /// Result variants:
  ///   * `Success(null)` — no entry exists (cold start).
  ///   * `Success(session)` — entry present and parsed.
  ///   * `Failure(KeychainUnavailable)` — backend binary missing.
  ///   * `Failure(KeychainOperationFailed)` — operation error.
  ///   * `Failure(KeychainCorruptEntry)` — entry exists but JSON malformed.
  Future<Result<OidcSession?>> read();

  /// Deletes the entry. Idempotent — a missing entry yields
  /// `Success(void)`, NOT `Failure`. Mirrors `FileCredentialStore.clear()`
  /// semantics.
  Future<Result<void>> delete();
}

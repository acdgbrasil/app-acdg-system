/// Picks the right [KeychainAdapter] for the host platform and returns a
/// [CredentialStore] that delegates to it. Runs the migration shim
/// (read once from the legacy file, write into the keychain, delete the
/// legacy file) on construction so the first authenticated request after
/// upgrade transparently uses the keychain.
///
/// Algorithm (DESIGN §6, §8):
///   1. `keychain.read()` — what does the keychain currently hold?
///   2. If keychain has a session: legacy file is stale; delete it.
///   3. If keychain is empty:
///      a. Read the legacy plaintext file.
///      b. If the file is also empty → cold start, done.
///      c. Otherwise: `keychain.write(session)`.
///         * On `Success` → read-after-write verify → on confirmation,
///           delete the legacy file.
///         * On `Failure` → KEEP the legacy file (no token loss). The
///           operator sees a stderr warning at next operation.
library;

import 'dart:io';

import 'package:core_contracts/core_contracts.dart';

import '../config/oidc_config.dart';
import '../errors/cli_error.dart';
import 'credential_store.dart';
import 'keychain_adapter.dart';
import 'keychain_linux_adapter.dart';
import 'keychain_macos_adapter.dart';
import 'keychain_windows_adapter.dart';
import 'oidc_session.dart';

/// Default reverse-DNS service identifier — ratified in DESIGN §D3.
const String _defaultService = 'com.acdgbrasil.acdg-cli';

/// Sentinel for "unsupported platform" — [Platform.operatingSystem] is
/// not in the macOS/Linux/Windows triple.
final class CredentialStoreFactory {
  const CredentialStoreFactory._();

  /// Returns the production [CredentialStore] for the current platform.
  ///
  /// Returns `Failure(KeychainUnavailable)` when:
  ///   * the platform is unsupported (Fuchsia, Android, iOS, …);
  ///   * Windows but `LOCALAPPDATA` is unset.
  ///
  /// NEVER returns the plaintext [FileCredentialStore] as a production
  /// path — the legacy file is consulted only by the migration shim
  /// (read-once-then-delete).
  static Future<Result<CredentialStore>> create({
    required Map<String, String> env,
    String service = _defaultService,
    String? account,
  }) async {
    final accountResolved = account ?? Uri.parse(OidcConfig.issuer).host;
    final adapterResult = _buildAdapter(
      env: env,
      service: service,
      account: accountResolved,
    );
    return switch (adapterResult) {
      Failure<KeychainAdapter>(:final error, :final stackTrace) =>
        Failure<CredentialStore>(error, stackTrace: stackTrace),
      Success<KeychainAdapter>(:final value) => Success<CredentialStore>(
        await _wrapWithMigration(adapter: value, env: env),
      ),
    };
  }

  /// Synchronous variant — picks the platform adapter and wraps it
  /// without running the migration shim. Intended for callers (e.g.
  /// [CliRunner]) that need a [CredentialStore] at construction time;
  /// they should call [migrateLegacyOnce] from their async entry point
  /// before any credential operation.
  ///
  /// Returns `Failure` for the same reasons as [create].
  static Result<CredentialStore> createSync({
    required Map<String, String> env,
    String service = _defaultService,
    String? account,
  }) {
    final accountResolved = account ?? Uri.parse(OidcConfig.issuer).host;
    final adapterResult = _buildAdapter(
      env: env,
      service: service,
      account: accountResolved,
    );
    return switch (adapterResult) {
      Failure<KeychainAdapter>(:final error, :final stackTrace) =>
        Failure<CredentialStore>(error, stackTrace: stackTrace),
      Success<KeychainAdapter>(:final value) => Success<CredentialStore>(
        KeychainCredentialStore(adapter: value),
      ),
    };
  }

  /// Runs the migration shim against the current platform's keychain
  /// adapter. Intended to be awaited once per CLI invocation, before any
  /// credential operation. Idempotent — safe to call repeatedly.
  static Future<void> migrateLegacyOnce({
    required Map<String, String> env,
    String service = _defaultService,
    String? account,
  }) async {
    final accountResolved = account ?? Uri.parse(OidcConfig.issuer).host;
    final adapterResult = _buildAdapter(
      env: env,
      service: service,
      account: accountResolved,
    );
    switch (adapterResult) {
      case Success<KeychainAdapter>(:final value):
        await _migrateLegacyFile(adapter: value, env: env);
      case Failure<KeychainAdapter>():
        // No keychain backend → nothing to migrate to. The wrapper from
        // [createSync] will surface the failure on first read.
        return;
    }
  }

  /// Test seam — exposes the migration shim with an injected adapter so
  /// migration tests don't have to fight platform detection.
  ///
  /// SEC: production callers MUST use [create] — `migrateForTest`
  /// bypasses platform-correctness checks.
  static Future<CredentialStore> migrateForTest({
    required KeychainAdapter keychain,
    required Map<String, String> env,
  }) {
    return _wrapWithMigration(adapter: keychain, env: env);
  }

  /// Picks the platform adapter or surfaces [KeychainUnavailable].
  static Result<KeychainAdapter> _buildAdapter({
    required Map<String, String> env,
    required String service,
    required String account,
  }) {
    if (Platform.isMacOS) {
      return Success<KeychainAdapter>(
        KeychainMacosAdapter(service: service, account: account),
      );
    }
    if (Platform.isLinux) {
      return Success<KeychainAdapter>(
        KeychainLinuxAdapter(service: service, account: account),
      );
    }
    if (Platform.isWindows) {
      final localAppData = env['LOCALAPPDATA'];
      if (localAppData == null || localAppData.isEmpty) {
        return const Failure<KeychainAdapter>(
          KeychainUnavailable(
            'powershell.exe',
            'LOCALAPPDATA environment variable is not set.',
          ),
        );
      }
      return Success<KeychainAdapter>(
        KeychainWindowsAdapter(
          service: service,
          account: account,
          storePath: '$localAppData\\acdg\\creds.dpapi',
        ),
      );
    }
    return const Failure<KeychainAdapter>(
      KeychainUnavailable(
        'none',
        'unsupported platform — only macOS, Linux, Windows are supported.',
      ),
    );
  }

  /// Wraps [adapter] in a [KeychainCredentialStore] AFTER running the
  /// one-shot migration shim. Returns the wrapper so callers can use it
  /// for the rest of the CLI invocation.
  static Future<CredentialStore> _wrapWithMigration({
    required KeychainAdapter adapter,
    required Map<String, String> env,
  }) async {
    final wrapper = KeychainCredentialStore(adapter: adapter);
    await _migrateLegacyFile(adapter: adapter, env: env);
    return wrapper;
  }

  /// Best-effort one-shot migration. Documented in DESIGN §6, §8.
  ///
  /// Properties enforced by the test suite:
  ///   * Idempotent — re-running yields the same end-state.
  ///   * Token never lost — file deleted ONLY after read-after-write
  ///     verification confirms the keychain entry.
  ///   * Fail-loud — write failure leaves the file in place; user sees a
  ///     stderr warning.
  static Future<void> _migrateLegacyFile({
    required KeychainAdapter adapter,
    required Map<String, String> env,
  }) async {
    final legacyPath = FileCredentialStore.defaultPath(env: env);
    final legacy = FileCredentialStore(path: legacyPath);

    // Step 1 — what does the keychain currently hold?
    final OidcSession? current;
    switch (await adapter.read()) {
      case Success<OidcSession?>(:final value):
        current = value;
      case Failure<OidcSession?>():
        // Bail out on ambiguous state — the migration is best-effort, and
        // surfacing the failure on next read is preferable to clobbering
        // either side. Do NOT delete the legacy file.
        return;
    }

    if (current != null) {
      // Step 2a — keychain populated; legacy file (if any) is stale.
      if (await File(legacyPath).exists()) {
        await legacy.clear();
      }
      return;
    }

    // Step 2b — keychain empty; consult the legacy file.
    final fileSession = await legacy.read();
    if (fileSession == null) {
      // Cold start — nothing to migrate.
      return;
    }

    // Step 3 — write into keychain. On failure: KEEP the file so the
    // session is not lost; do not verify, do not clear, simply abort.
    switch (await adapter.write(fileSession)) {
      case Success<void>():
        break;
      case Failure<void>():
        stderr.writeln(
          'acdg: keychain migration failed; legacy credentials file '
          'preserved. Re-run after fixing the keychain backend.',
        );
        return;
    }

    // SEC: read-after-write verification — only delete the plaintext
    // file once the keychain entry is confirmed present. This is the
    // partial-failure-safe property locked by DESIGN §8.
    final OidcSession? verified;
    switch (await adapter.read()) {
      case Success<OidcSession?>(:final value):
        verified = value;
      case Failure<OidcSession?>():
        verified = null;
    }
    if (verified != null) {
      await legacy.clear();
      stderr.writeln(
        'acdg: migrated session from legacy credentials file to system '
        'keychain.',
      );
    } else {
      stderr.writeln(
        'acdg: keychain migration write succeeded but read-after-write '
        'verification failed; legacy credentials file preserved.',
      );
    }
  }
}

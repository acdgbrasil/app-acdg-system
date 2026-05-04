/// W0 RED — `runCliForGolden` helper.
///
/// Drives `CliRunner` end-to-end against a [MockBffServer], capturing
/// stdout/stderr + exit code. Tests then compare the captured output with a
/// golden file via [expectGolden].
///
/// **W1 contract** — references symbols that don't exist yet:
///   1. `CliRunner` must accept named params:
///      - `HttpClientAdapter? adapter` — when non-null, every BFF call uses
///        this adapter instead of the production Dio.
///      - `CredentialStore? credentialStore` — when non-null, the runner
///        skips the `FileCredentialStore` wiring and uses the supplied store
///        directly. Lets golden tests inject a fake "signed-in" session.
///   2. `--output` global flag must be wired to a runner-level resolver
///      (today it's parsed but ignored — every command hardcodes
///      `JsonFormatter`). The resolver picks the formatter passed down to
///      every leaf command.
///
/// W0 prediction: this file references `CliRunner(..., adapter: ..., credentialStore: ...)`,
/// which fails to analyze until W1 lands the additive params.
library;

import 'package:cli/src/cli_runner.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';
import 'package:dio/dio.dart';

/// Result of one golden CLI invocation.
final class GoldenInvocation {
  const GoldenInvocation({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Runs `acdg [args]` with the given [mockAdapter] wired in place of real Dio.
///
/// [credentialStore] defaults to a "signed-in fake" so commands don't bail at
/// the auth step; tests that exercise auth-failure paths pass a different
/// store (e.g. one that returns `null`).
///
/// [clock] is forwarded to `CliRunner.clock` so tests that exercise time-
/// sensitive output (e.g. `auth status` relative time) can pin a fixed
/// `now()`.
Future<GoldenInvocation> runCliForGolden(
  List<String> args, {
  required HttpClientAdapter mockAdapter,
  CredentialStore? credentialStore,
  DateTime Function()? clock,
}) async {
  final stdout = StringBuffer();
  final stderr = StringBuffer();

  final cli = CliRunner(
    stdout: stdout,
    stderr: stderr,
    // W1 must add these named params (additive, default null = production
    // wiring — preserves C02-C09 behavior verbatim).
    adapter: mockAdapter,
    credentialStore: credentialStore ?? FakeCredentialStore.signedIn(),
    clock: clock,
  );

  final exitCode = await cli.run(args);
  return GoldenInvocation(
    exitCode: exitCode,
    stdout: stdout.toString(),
    stderr: stderr.toString(),
  );
}

/// In-memory [CredentialStore] for golden tests. NEVER touches disk.
///
/// Three constructors:
///   * [signedIn] — returns a synthetic `OidcSession` with a fake bearer.
///   * [signedOut] — returns `null` from `read()` so commands hit
///     `AuthRequiredError` before any HTTP round-trip.
///   * [withSession] — caller-supplied session.
final class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore._(this._session);

  /// "Signed in" — fixed token, expiry far in the future. Roles list mirrors
  /// production shapes (3 enum values per ADR-011).
  factory FakeCredentialStore.signedIn() => FakeCredentialStore._(
    OidcSession(
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      idToken: 'fake-id-token',
      accessExpiresAt: DateTime.utc(2099, 1, 1),
      sub: 'fake-sub',
      email: 'fake@example.com',
      roles: const ['social_worker'],
    ),
  );

  /// "Signed out" — `read()` returns null. Commands surface
  /// `AuthRequiredError` ⇒ exit 2 ⇒ stderr message.
  factory FakeCredentialStore.signedOut() => FakeCredentialStore._(null);

  /// Custom session — for tests that need specific roles or expired tokens.
  factory FakeCredentialStore.withSession(OidcSession session) =>
      FakeCredentialStore._(session);

  OidcSession? _session;

  @override
  Future<OidcSession?> read() async => _session;

  @override
  Future<void> write(OidcSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

/// `acdg auth logout` — best-effort revoke + local clear.
///
/// Behavior (spike §5.14):
///   * No local session → exit 0, no-op (idempotent).
///   * Local session present:
///     1. Try to load discovery (best-effort — failure does not block).
///     2. Try `revoker(refresh_token)` against the discovery
///        revocation_endpoint (best-effort — failure does not block).
///     3. ALWAYS clear the local store at the end.
///   * Always exits 0 (idempotent UX).
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../oidc/oidc_discovery.dart';
import '../session/credential_store.dart';

/// Function shape passed in for the best-effort revoke call. Keeps
/// HTTP wiring out of the command — the real impl lives in the
/// `cli_runner.dart` factory.
typedef RevokeFn =
    Future<Result<void>> Function({
      required OidcDiscovery discovery,
      required String refreshToken,
    });

/// `acdg auth logout` — see file-level docstring.
final class AuthLogoutCommand extends Command<int> {
  AuthLogoutCommand({
    required this.credentialStore,
    required this.discoveryLoader,
    required this.revoker,
    this.stdout,
    this.stderr,
  });

  final CredentialStore credentialStore;
  final Future<Result<OidcDiscovery>> Function() discoveryLoader;
  final RevokeFn revoker;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'logout';

  @override
  String get description => 'Revoke refresh token and clear local session';

  @override
  Future<int> run() async {
    final session = await credentialStore.read();
    if (session == null) {
      _writeOut('Already logged out.');
      return 0;
    }

    final discoveryResult = await discoveryLoader();
    switch (discoveryResult) {
      case Success(:final value):
        final revokeResult = await revoker(
          discovery: value,
          refreshToken: session.refreshToken,
        );
        switch (revokeResult) {
          case Success():
            _writeOut('Refresh token revoked.');
          case Failure(:final error):
            _writeErr(
              'Warning: revoke at the IdP failed ($error). '
              'Local session will still be cleared.',
            );
        }
      case Failure(:final error):
        _writeErr(
          'Warning: discovery failed ($error). '
          'Skipping remote revoke; local session will still be cleared.',
        );
    }

    await credentialStore.clear();
    _writeOut('Logged out.');
    return 0;
  }

  void _writeOut(String line) {
    final out = stdout;
    if (out != null) out.writeln(line);
  }

  void _writeErr(String line) {
    final err = stderr ?? stdout;
    if (err != null) err.writeln(line);
  }
}

/// `acdg auth refresh` — manually rotate the access/refresh token pair.
///
/// Exit codes (spike §5.9):
///   * 0 — success
///   * 1 — no session (must run `acdg auth login` first)
///   * 7 — RefreshTokenInvalid (session invalidated upstream); local cleared
///   * non-zero (other) — generic refresh failure (local session preserved)
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';

import '../errors/cli_error.dart';
import '../oidc/oidc_discovery.dart';
import '../oidc/token_client.dart';
import '../session/credential_store.dart';
import '../session/oidc_session.dart';

/// `acdg auth refresh` — see file-level docstring.
final class AuthRefreshCommand extends Command<int> {
  AuthRefreshCommand({
    required this.credentialStore,
    required this.discoveryLoader,
    required this.tokenClientFactory,
    this.stdout,
    this.stderr,
  });

  final CredentialStore credentialStore;
  final Future<Result<OidcDiscovery>> Function() discoveryLoader;
  final TokenClient Function(OidcDiscovery) tokenClientFactory;
  final StringSink? stdout;
  final StringSink? stderr;

  @override
  String get name => 'refresh';

  @override
  String get description => 'Force a refresh of the access/refresh token pair';

  @override
  Future<int> run() async {
    final session = await credentialStore.read();
    if (session == null) {
      _writeErr('Not logged in. Run: acdg auth login');
      return 1;
    }

    final discoveryResult = await discoveryLoader();
    final discovery = switch (discoveryResult) {
      Success(:final value) => value,
      Failure(:final error) => () {
        _writeErr('Discovery failed: $error');
        return null;
      }(),
    };
    if (discovery == null) return 5;

    final tokenClient = tokenClientFactory(discovery);
    final refresh = await tokenClient.refresh(
      refreshToken: session.refreshToken,
    );

    switch (refresh) {
      case Success(:final value):
        final rotated = OidcSession(
          accessToken: value.accessToken,
          refreshToken: value.refreshToken,
          idToken: value.idToken,
          accessExpiresAt: DateTime.now().toUtc().add(value.expiresIn),
          sub: session.sub,
          email: session.email,
          roles: session.roles,
        );
        await credentialStore.write(rotated);
        _writeOut(
          'Refreshed. Session valid until '
          '${rotated.accessExpiresAt.toIso8601String()}.',
        );
        return 0;
      case Failure(:final error) when error is RefreshTokenInvalidError:
        await credentialStore.clear();
        _writeErr(
          'Sessão invalidada — execute `acdg auth login` para entrar de novo.',
        );
        return 7;
      case Failure(:final error):
        _writeErr('Refresh failed: $error');
        // Generic failure: keep the session — the next attempt may succeed.
        return 6;
    }
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

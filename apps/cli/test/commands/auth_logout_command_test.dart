/// W0 RED — `AuthLogoutCommand` contract (C02 §5.14).
///
/// W1 must create `apps/cli/lib/src/commands/auth_logout_command.dart`:
///
/// ```dart
/// class AuthLogoutCommand extends Command<int> {
///   AuthLogoutCommand({
///     required this.credentialStore,
///     required this.discoveryLoader,
///     required this.revoker,
///     this.stdout,
///     this.stderr,
///   });
///
///   final CredentialStore credentialStore;
///   final Future<Result<OidcDiscovery>> Function() discoveryLoader;
///   final Future<Result<void>> Function({
///     required OidcDiscovery discovery,
///     required String refreshToken,
///   }) revoker;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'logout';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior:
///   * No session → exit 0, no-op (idempotent).
///   * Session present → call revoker (best-effort: a Failure is logged but
///     does NOT block local clear); always clear local store; exit 0.
library;

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_logout_command.dart';
import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  late _FakeStore store;
  late StringBuffer stdout;
  late StringBuffer stderr;

  setUp(() {
    store = _FakeStore();
    stdout = StringBuffer();
    stderr = StringBuffer();
  });

  AuthLogoutCommand buildCommand({
    Future<Result<void>> Function({
      required OidcDiscovery discovery,
      required String refreshToken,
    })?
    revoker,
    Future<Result<OidcDiscovery>> Function()? discoveryLoader,
  }) {
    return AuthLogoutCommand(
      credentialStore: store,
      discoveryLoader: discoveryLoader ?? () async => Success(_kDiscovery),
      revoker:
          revoker ??
          ({required discovery, required refreshToken}) async =>
              const Success<void>(null),
      stdout: stdout,
      stderr: stderr,
    );
  }

  group('AuthLogoutCommand basics', () {
    test('extends Command<int> with name "logout"', () {
      final cmd = buildCommand();
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('logout'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('AuthLogoutCommand — no session', () {
    test('exits 0 and does not call revoker (no-op)', () async {
      var revokerCalled = false;
      final cmd = buildCommand(
        revoker: ({required discovery, required refreshToken}) async {
          revokerCalled = true;
          return const Success<void>(null);
        },
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(revokerCalled, isFalse);
    });
  });

  group('AuthLogoutCommand — with session', () {
    test('exits 0, calls revoker with refresh token, clears store', () async {
      final session = _aSession();
      store.stored = session;

      String? capturedRefresh;
      final cmd = buildCommand(
        revoker: ({required discovery, required refreshToken}) async {
          capturedRefresh = refreshToken;
          return const Success<void>(null);
        },
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(capturedRefresh, equals(session.refreshToken));
      expect(store.stored, isNull);
    });

    test(
      'revoker failure is best-effort: clears store anyway, still exits 0',
      () async {
        store.stored = _aSession();
        final cmd = buildCommand(
          revoker: ({required discovery, required refreshToken}) async =>
              const Failure<void>(NetworkError('zitadel down')),
        );

        final exitCode = await cmd.run();

        expect(exitCode, equals(0));
        expect(store.stored, isNull);
        // A warning may be printed; we don't assert exact text but it should
        // mention something so the user knows revoke didn't reach Zitadel.
        final combined = stdout.toString() + stderr.toString();
        expect(combined, isNotEmpty);
      },
    );

    test(
      'discovery failure is best-effort: clears store anyway, still exits 0',
      () async {
        store.stored = _aSession();
        final cmd = buildCommand(
          discoveryLoader: () async =>
              const Failure(NetworkError('discovery down')),
        );

        final exitCode = await cmd.run();

        expect(exitCode, equals(0));
        expect(store.stored, isNull);
      },
    );
  });
}

OidcSession _aSession() => OidcSession(
  accessToken: 'at-1',
  refreshToken: 'rt-old',
  idToken: 'it-1',
  accessExpiresAt: DateTime.utc(2099, 1, 1),
  sub: 's',
  email: 'e@e',
  roles: const ['social_worker'],
);

const OidcDiscovery _kDiscovery = OidcDiscovery(
  issuer: 'https://auth.acdgbrasil.com.br',
  authorizationEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/authorize',
  tokenEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/token',
  jwksUri: 'https://auth.acdgbrasil.com.br/oauth/v2/keys',
  userinfoEndpoint: 'https://auth.acdgbrasil.com.br/oidc/v1/userinfo',
  endSessionEndpoint: 'https://auth.acdgbrasil.com.br/oidc/v1/end_session',
  revocationEndpoint: 'https://auth.acdgbrasil.com.br/oauth/v2/revoke',
  deviceAuthorizationEndpoint:
      'https://auth.acdgbrasil.com.br/oauth/v2/device_authorization',
);

class _FakeStore implements CredentialStore {
  OidcSession? stored;

  @override
  Future<OidcSession?> read() async => stored;

  @override
  Future<void> write(OidcSession session) async {
    stored = session;
  }

  @override
  Future<void> clear() async {
    stored = null;
  }
}

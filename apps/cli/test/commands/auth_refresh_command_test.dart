/// W0 RED — `AuthRefreshCommand` contract (C02 §5.9).
///
/// W1 must create `apps/cli/lib/src/commands/auth_refresh_command.dart`:
///
/// ```dart
/// class AuthRefreshCommand extends Command<int> {
///   AuthRefreshCommand({
///     required this.credentialStore,
///     required this.discoveryLoader,
///     required this.tokenClientFactory,
///     this.stdout,
///     this.stderr,
///   });
///
///   final CredentialStore credentialStore;
///   final Future<Result<OidcDiscovery>> Function() discoveryLoader;
///   final TokenClient Function(OidcDiscovery) tokenClientFactory;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'refresh';
///   @override Future<int> run();
/// }
/// ```
///
/// Exit codes (per spike §5.9):
///   * 0 — success
///   * 1 — no session (must run `acdg auth login` first)
///   * 7 — RefreshTokenInvalid (session invalidated upstream); local cleared
library;

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_refresh_command.dart';
import 'package:cli/src/config/oidc_config.dart';
import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';
import 'package:cli/src/oidc/token_client.dart';
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

  AuthRefreshCommand buildCommand({
    Result<TokenResponse>? refreshResult,
    Future<Result<OidcDiscovery>> Function()? discoveryLoader,
  }) {
    return AuthRefreshCommand(
      credentialStore: store,
      discoveryLoader: discoveryLoader ?? () async => Success(_kDiscovery),
      tokenClientFactory: (_) => _FakeTokenClient(refreshResult: refreshResult),
      stdout: stdout,
      stderr: stderr,
    );
  }

  group('AuthRefreshCommand basics', () {
    test('extends Command<int> with name "refresh"', () {
      final cmd = buildCommand();
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('refresh'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('AuthRefreshCommand — no session', () {
    test('exits 1 and prints "Not logged in"', () async {
      final cmd = buildCommand();

      final exitCode = await cmd.run();

      expect(exitCode, equals(1));
      final out = (stdout.toString() + stderr.toString()).toLowerCase();
      expect(out, contains('not logged in'));
      // Must NOT have called the token client.
      expect(store.stored, isNull);
    });
  });

  group('AuthRefreshCommand — happy path', () {
    test('exits 0, saves rotated session, prints success', () async {
      store.stored = _aSession(refreshToken: 'rt-old');

      final cmd = buildCommand(
        refreshResult: Success(
          _validTokenResponse(accessToken: 'at-new', refreshToken: 'rt-new'),
        ),
      );

      final exitCode = await cmd.run();

      expect(exitCode, equals(0));
      expect(store.stored, isNotNull);
      expect(store.stored!.accessToken, equals('at-new'));
      expect(store.stored!.refreshToken, equals('rt-new'));
    });
  });

  group('AuthRefreshCommand — RefreshTokenInvalid (spike §5.9)', () {
    test(
      'exits 7, clears local session, prints `acdg auth login` hint',
      () async {
        store.stored = _aSession(refreshToken: 'rt-stale');

        final cmd = buildCommand(
          refreshResult: const Failure(RefreshTokenInvalidError()),
        );

        final exitCode = await cmd.run();

        expect(exitCode, equals(7));
        expect(store.stored, isNull);
        final out = (stdout.toString() + stderr.toString()).toLowerCase();
        expect(out, contains('acdg auth login'));
      },
    );
  });

  group('AuthRefreshCommand — generic refresh failure', () {
    test('exits non-zero (and not 7), session NOT cleared', () async {
      store.stored = _aSession();

      final cmd = buildCommand(
        refreshResult: const Failure(NetworkError('upstream timeout')),
      );

      final exitCode = await cmd.run();

      expect(exitCode, isNot(equals(0)));
      expect(exitCode, isNot(equals(7)));
      // Generic failure: keep the session (next attempt may succeed).
      expect(store.stored, isNotNull);
    });
  });
}

OidcSession _aSession({String refreshToken = 'rt'}) => OidcSession(
  accessToken: 'at',
  refreshToken: refreshToken,
  idToken: 'it',
  accessExpiresAt: DateTime.utc(2099, 1, 1),
  sub: '363088829932634233',
  email: 'user@example.com',
  roles: const ['social_worker'],
);

TokenResponse _validTokenResponse({
  String accessToken = 'at',
  String refreshToken = 'rt',
}) {
  String b64Url(String s) =>
      base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  final header = b64Url(jsonEncode({'alg': 'RS256', 'kid': 'k'}));
  final payload = b64Url(
    jsonEncode({
      'iss': 'https://auth.acdgbrasil.com.br',
      'sub': '363088829932634233',
      'email': 'user@example.com',
      'urn:zitadel:iam:org:project:roles': {
        'social_worker': {'363109592139300987': 'acdg.auth.acdgbrasil.com.br'},
      },
    }),
  );
  return TokenResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    idToken: '$header.$payload.fake-sig',
    tokenType: 'Bearer',
    expiresIn: const Duration(seconds: 43200),
  );
}

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

class _FakeTokenClient implements TokenClient {
  _FakeTokenClient({this.refreshResult});

  final Result<TokenResponse>? refreshResult;

  @override
  OidcDiscovery get discovery => _kDiscovery;

  @override
  Future<Result<TokenResponse>> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    String clientId = OidcConfig.clientId,
  }) async => const Failure(CliError.server(500, 'not used in this suite'));

  @override
  Future<Result<TokenResponse>> refresh({
    required String refreshToken,
    String clientId = OidcConfig.clientId,
    String scopes = OidcConfig.scopes,
  }) async =>
      refreshResult ??
      const Failure(CliError.server(500, 'no result configured'));
}

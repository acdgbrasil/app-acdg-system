/// W0 RED — `AuthLoginCommand` orchestration contract (C02).
///
/// W1 must create `apps/cli/lib/src/commands/auth_login_command.dart` with:
///
/// ```dart
/// class AuthLoginCommand extends Command<int> {
///   AuthLoginCommand({
///     required this.discoveryLoader,
///     required this.pkceFactory,
///     required this.listenerFactory,
///     required this.tokenClientFactory,
///     required this.credentialStore,
///     required this.browserOpener,
///     required this.stateNonceFactory,
///     this.stdout,
///     this.stderr,
///   });
///
///   final Future<Result<OidcDiscovery>> Function() discoveryLoader;
///   final PkcePair Function() pkceFactory;
///   final LoopbackListener Function({required String expectedState})
///       listenerFactory;
///   final TokenClient Function(OidcDiscovery) tokenClientFactory;
///   final CredentialStore credentialStore;
///   final Future<void> Function(Uri) browserOpener;
///   final ({String state, String nonce}) Function() stateNonceFactory;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'login';
///   @override Future<int> run();
/// }
/// ```
///
/// The orchestration sequence (spike §5.1 .. §5.8):
///
/// 1. `discoveryLoader()` -> `Result<OidcDiscovery>`
/// 2. `pkceFactory()` and `stateNonceFactory()`
/// 3. `listenerFactory(expectedState).bindEphemeralPort()`
/// 4. Build authorize URL with `prompt=login`, S256 challenge, scopes.
/// 5. Print URL to stdout (so SSH/CI users can copy).
/// 6. `browserOpener(url)`.
/// 7. `listener.awaitCallback()` -> `Result<String>` (the captured code).
/// 8. `tokenClient.exchangeCode(code, verifier, redirectUri)` -> tokens.
/// 9. Decode id_token (no signature validation — that's the BFF's job),
///    extract `sub`, `email`, roles into an `OidcSession`.
/// 10. `credentialStore.write(session)`.
/// 11. Print `Logged in as <email>` + roles count + expiration.
///
/// Failure paths: every failing step propagates a non-zero exit code AND
/// MUST NOT save a partial session. Tests below cover the major branches.
library;

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:core_contracts/core_contracts.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/auth_login_command.dart';
import 'package:cli/src/config/oidc_config.dart';
import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/loopback_listener.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';
import 'package:cli/src/oidc/pkce_pair.dart';
import 'package:cli/src/oidc/token_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  late _FakeStore store;
  late List<Uri> openedUrls;
  late StringBuffer stdout;
  late StringBuffer stderr;
  late _FakeListener fakeListener;

  setUp(() {
    store = _FakeStore();
    openedUrls = [];
    stdout = StringBuffer();
    stderr = StringBuffer();
    fakeListener = _FakeListener(
      expectedState: 'fixed-state',
      port: 55555,
      onAwait: () async => const Success<String>('AUTH-CODE-123'),
    );
  });

  AuthLoginCommand buildCommand({
    Future<Result<OidcDiscovery>> Function()? discoveryLoader,
    PkcePair Function()? pkceFactory,
    LoopbackListener Function({required String expectedState})? listenerFactory,
    TokenClient Function(OidcDiscovery)? tokenClientFactory,
    Future<void> Function(Uri)? browserOpener,
    ({String state, String nonce}) Function()? stateNonceFactory,
  }) {
    return AuthLoginCommand(
      discoveryLoader: discoveryLoader ?? () async => Success(_kDiscovery),
      pkceFactory:
          pkceFactory ??
          () => const PkcePair(verifier: 'V123', challenge: 'CH456'),
      listenerFactory:
          listenerFactory ?? ({required String expectedState}) => fakeListener,
      tokenClientFactory:
          tokenClientFactory ??
          (_) =>
              _FakeTokenClient(exchangeResult: Success(_validTokenResponse())),
      credentialStore: store,
      browserOpener: browserOpener ?? (uri) async => openedUrls.add(uri),
      stateNonceFactory:
          stateNonceFactory ??
          () => (state: 'fixed-state', nonce: 'fixed-nonce'),
      stdout: stdout,
      stderr: stderr,
    );
  }

  group('AuthLoginCommand basics', () {
    test('extends Command<int> with name "login"', () {
      final cmd = buildCommand();
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('login'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('AuthLoginCommand — happy path', () {
    test(
      'opens browser with authorize URL, saves session, prints email',
      () async {
        final cmd = buildCommand();

        final exitCode = await cmd.run();

        expect(exitCode, equals(0));

        // Browser must have been called with one URL.
        expect(openedUrls, hasLength(1));
        final url = openedUrls.single;

        // Authorize URL invariants (spike §5.6).
        expect(url.queryParameters['response_type'], equals('code'));
        expect(url.queryParameters['client_id'], equals(OidcConfig.clientId));
        expect(url.queryParameters['code_challenge'], equals('CH456'));
        expect(url.queryParameters['code_challenge_method'], equals('S256'));
        expect(url.queryParameters['state'], equals('fixed-state'));
        expect(url.queryParameters['nonce'], equals('fixed-nonce'));
        expect(url.queryParameters['prompt'], equals('login'));
        // Scope must include offline_access + the magic aud scope.
        final scope = url.queryParameters['scope'] ?? '';
        expect(scope, contains('offline_access'));
        expect(scope, contains('urn:zitadel:iam:org:project:id:'));
        expect(scope, contains(OidcConfig.projectId));

        // Session was persisted.
        expect(store.lastWritten, isNotNull);
        expect(store.lastWritten!.email, equals('user@example.com'));
        expect(store.lastWritten!.roles, contains('superadmin'));

        // Stdout reports who logged in.
        expect(stdout.toString(), contains('user@example.com'));
      },
    );

    test(
      'prints the authorize URL too (so SSH/CI users can copy-paste)',
      () async {
        final cmd = buildCommand();

        await cmd.run();

        expect(stdout.toString(), contains('http'));
        expect(stdout.toString(), contains('authorize'));
      },
    );
  });

  group('AuthLoginCommand — failure paths', () {
    test('discovery fails → non-zero exit, no session saved', () async {
      final cmd = buildCommand(
        discoveryLoader: () async =>
            const Failure(NetworkError('issuer unreachable')),
      );

      final exitCode = await cmd.run();

      expect(exitCode, isNot(equals(0)));
      expect(store.lastWritten, isNull);
    });

    test(
      'authorize callback returns Failure → non-zero exit, no session saved',
      () async {
        fakeListener = _FakeListener(
          expectedState: 'fixed-state',
          port: 55555,
          onAwait: () async => const Failure<String>(
            CliError.invalidArg('access_denied: user cancelled'),
          ),
        );
        final cmd = buildCommand();

        final exitCode = await cmd.run();

        expect(exitCode, isNot(equals(0)));
        expect(store.lastWritten, isNull);
      },
    );

    test('token exchange fails → non-zero exit, no session saved', () async {
      final cmd = buildCommand(
        tokenClientFactory: (_) => _FakeTokenClient(
          exchangeResult: const Failure(CliError.server(400, 'invalid_grant')),
        ),
      );

      final exitCode = await cmd.run();

      expect(exitCode, isNot(equals(0)));
      expect(store.lastWritten, isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

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

/// Returns a TokenResponse whose `id_token` decodes (header.payload.sig)
/// with a payload containing `sub`, `email`, and the project-roles claim.
TokenResponse _validTokenResponse() {
  String b64Url(String s) =>
      base64Url.encode(utf8.encode(s)).replaceAll('=', '');

  final header = b64Url(jsonEncode({'alg': 'RS256', 'kid': 'test'}));
  final payload = b64Url(
    jsonEncode({
      'iss': 'https://auth.acdgbrasil.com.br',
      'sub': '363088829932634233',
      'email': 'user@example.com',
      'urn:zitadel:iam:org:project:roles': {
        'superadmin': {'363109592139300987': 'acdg.auth.acdgbrasil.com.br'},
        'social_worker': {'363109592139300987': 'acdg.auth.acdgbrasil.com.br'},
      },
    }),
  );
  // Signature is irrelevant — the CLI only decodes (validation is BFF-side).
  final fakeIdToken = '$header.$payload.fake-sig';

  return TokenResponse(
    accessToken: 'at-fixture',
    refreshToken: 'rt-fixture',
    idToken: fakeIdToken,
    tokenType: 'Bearer',
    expiresIn: const Duration(seconds: 43200),
  );
}

class _FakeStore implements CredentialStore {
  OidcSession? lastWritten;
  bool clearCalled = false;

  @override
  Future<OidcSession?> read() async => lastWritten;

  @override
  Future<void> write(OidcSession session) async {
    lastWritten = session;
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
    lastWritten = null;
  }
}

class _FakeListener implements LoopbackListener {
  _FakeListener({
    required this.expectedState,
    required this.port,
    required this.onAwait,
  });

  @override
  final String expectedState;
  final int port;
  final Future<Result<String>> Function() onAwait;

  @override
  Duration get timeout => const Duration(seconds: 5);

  @override
  Future<int> bindEphemeralPort() async => port;

  @override
  Future<Result<String>> awaitCallback() => onAwait();
}

class _FakeTokenClient implements TokenClient {
  _FakeTokenClient({this.exchangeResult});

  final Result<TokenResponse>? exchangeResult;

  @override
  OidcDiscovery get discovery => _kDiscovery;

  @override
  Future<Result<TokenResponse>> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    String clientId = OidcConfig.clientId,
  }) async =>
      exchangeResult ??
      const Failure(CliError.server(500, 'no result configured'));

  // `AuthLoginCommand` never calls `refresh` — surface only required to
  // satisfy `implements TokenClient`. Returns a stable failure so any
  // accidental call is loud, not silent.
  @override
  Future<Result<TokenResponse>> refresh({
    required String refreshToken,
    String clientId = OidcConfig.clientId,
    String scopes = OidcConfig.scopes,
  }) async => const Failure(
    CliError.server(500, 'refresh not exercised by login tests'),
  );
}

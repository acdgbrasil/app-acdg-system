/// W1 GREEN — `BffClient` scaffold + 401 refresh-retry (C02).
///
/// W0 RED file. The C01 fakes were migrated by W1 from `Credentials` to
/// `OidcSession` per W0 REPORT §4.1 Strategy A — verb shape and assertions
/// are unchanged; only the fixture type evolved. The C02-additive section
/// (401 refresh-retry) is intact.
///
/// Contract:
///   * Construction wires baseUrl + credentialStore + (optional) Dio +
///     optional [TokenClient] / [OidcDiscovery] for refresh-retry.
///   * Bearer interceptor: when CredentialStore yields a session, the next
///     request carries `Authorization: Bearer <token>`. When it yields
///     null, no Authorization header is added.
///   * On 401, the client refreshes once + retries once with the new
///     bearer; `RefreshTokenInvalidError` clears the store and surfaces
///     `AuthRequiredError`.
///   * Adapter that throws → caller sees `Failure(...)`, NEVER an exception.
library;

import 'dart:typed_data';

import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/config/oidc_config.dart';
import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/oidc/oidc_discovery.dart';
import 'package:cli/src/oidc/token_client.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('BffClient construction', () {
    test('exposes baseUrl after construction', () {
      final store = _FakeCredentialStore();
      final client = BffClient(
        baseUrl: 'http://localhost:3000',
        credentialStore: store,
      );

      expect(client.baseUrl, equals('http://localhost:3000'));
    });

    test('accepts an injectable Dio instance for testing', () {
      final store = _FakeCredentialStore();
      final dio = Dio();
      final client = BffClient(
        baseUrl: 'http://localhost:3000',
        credentialStore: store,
        dio: dio,
      );

      expect(client, isNotNull);
    });
  });

  group('BffClient — Bearer interceptor', () {
    test(
      'attaches Authorization: Bearer <token> when credentials present',
      () async {
        final adapter = _CapturingAdapter(
          response: ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        );
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
          ..httpClientAdapter = adapter;
        final store = _FakeCredentialStore(
          stored: OidcSession(
            accessToken: 'test-token-123',
            refreshToken: 'r',
            idToken: 'i',
            accessExpiresAt: DateTime.utc(2099, 1, 1),
            sub: 's',
            email: 'e@e',
            roles: const [],
          ),
        );
        final client = BffClient(
          baseUrl: 'http://localhost:3000',
          credentialStore: store,
          dio: dio,
        );

        await client.get<Map<String, Object?>>('/health');

        final captured = adapter.lastOptions;
        expect(captured, isNotNull);
        expect(
          captured!.headers['Authorization'] ??
              captured.headers['authorization'],
          equals('Bearer test-token-123'),
        );
      },
    );

    test(
      'omits Authorization header when CredentialStore returns null',
      () async {
        final adapter = _CapturingAdapter(
          response: ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        );
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
          ..httpClientAdapter = adapter;
        final store = _FakeCredentialStore(); // no stored credentials
        final client = BffClient(
          baseUrl: 'http://localhost:3000',
          credentialStore: store,
          dio: dio,
        );

        await client.get<Map<String, Object?>>('/health');

        final captured = adapter.lastOptions;
        expect(captured, isNotNull);
        // Either absent or empty — the test asserts "no Bearer leaked".
        final authHeader =
            captured!.headers['Authorization'] ??
            captured.headers['authorization'];
        expect(authHeader, anyOf(isNull, equals('')));
      },
    );
  });

  group('BffClient — Result discipline (never throws)', () {
    test('adapter failure → Result.Failure (no exception escapes)', () async {
      final adapter = _ThrowingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter;
      final store = _FakeCredentialStore();
      final client = BffClient(
        baseUrl: 'http://localhost:3000',
        credentialStore: store,
        dio: dio,
      );

      // MUST return Result, NOT throw.
      final result = await client.get<Map<String, Object?>>('/health');

      expect(result, isA<Failure<Map<String, Object?>>>());
    });
  });

  // ---------------------------------------------------------------------------
  // C02 ADDITIVE — 401 refresh-retry contract (spike §5.13).
  // ---------------------------------------------------------------------------
  //
  // W1 must extend `BffClient` so it accepts:
  //
  // ```dart
  // BffClient({
  //   required this.baseUrl,
  //   required CredentialStore credentialStore,
  //   TokenClient? tokenClient,        // NEW (optional — keeps C01 tests green)
  //   OidcDiscovery? discovery,        // NEW (optional — required if tokenClient != null)
  //   Dio? dio,
  // });
  // ```
  //
  // Behavior:
  //   * On 401 from `_dio.fetch`, IF tokenClient != null AND credentials present
  //     → call tokenClient.refresh(refreshToken: session.refreshToken)
  //     → on Success(new tokens): persist new OidcSession and retry the request
  //                                exactly once with the new access token.
  //     → on Failure(RefreshTokenInvalidError): clear store, propagate
  //                                AuthRequiredError as Failure.
  //     → on other Failure: propagate as Failure (no retry).
  //   * The refresh path MUST be invoked at most once per outbound request
  //     (no infinite retry loop on persistent 401).
  group('BffClient — 401 refresh-retry (C02)', () {
    test(
      '401 → refresh succeeds → retries with new token → returns Success',
      () async {
        final adapter = _SequencedAdapter([
          // First call: 401.
          ResponseBody.fromString(
            'unauthorized',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          ),
          // Second call (after refresh): 200.
          ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        ]);
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
          ..httpClientAdapter = adapter;
        final store = _FakeOidcStore(
          stored: _aSession(accessToken: 'old', refreshToken: 'rt-old'),
        );
        final tokenClient = _RefreshOnlyTokenClient(
          refreshResult: Success(
            TokenResponse(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
              idToken: _idToken(),
              tokenType: 'Bearer',
              expiresIn: const Duration(seconds: 43200),
            ),
          ),
        );
        final client = BffClient(
          baseUrl: 'http://localhost:3000',
          credentialStore: store,
          dio: dio,
          tokenClient: tokenClient,
          discovery: _kDiscovery,
        );

        final result = await client.get<Map<String, Object?>>('/me');

        expect(result, isA<Success<Map<String, Object?>>>());
        // Adapter saw exactly two requests.
        expect(adapter.calls, equals(2));
        // Second request MUST carry the new bearer.
        final secondAuth =
            adapter.captured[1].headers['Authorization'] ??
            adapter.captured[1].headers['authorization'];
        expect(secondAuth, equals('Bearer new-access'));
        // Refresh used at most once.
        expect(tokenClient.refreshCalls, equals(1));
      },
    );

    test(
      '401 → refresh RefreshTokenInvalid → clears store + AuthRequiredError',
      () async {
        final adapter = _SequencedAdapter([
          ResponseBody.fromString(
            'unauthorized',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        ]);
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
          ..httpClientAdapter = adapter;
        final store = _FakeOidcStore(stored: _aSession());
        final tokenClient = _RefreshOnlyTokenClient(
          refreshResult: const Failure(RefreshTokenInvalidError()),
        );
        final client = BffClient(
          baseUrl: 'http://localhost:3000',
          credentialStore: store,
          dio: dio,
          tokenClient: tokenClient,
          discovery: _kDiscovery,
        );

        final result = await client.get<Map<String, Object?>>('/me');

        expect(result, isA<Failure<Map<String, Object?>>>());
        final failure = result as Failure<Map<String, Object?>>;
        expect(failure.error, isA<AuthRequiredError>());
        // Local session wiped.
        expect(await store.read(), isNull);
        // No retry happened (only one HTTP call).
        expect(adapter.calls, equals(1));
      },
    );

    test(
      '401 then 401 again on retry → no infinite loop, returns Failure',
      () async {
        final adapter = _SequencedAdapter([
          ResponseBody.fromString(
            '401-1',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          ),
          ResponseBody.fromString(
            '401-2',
            401,
            headers: {
              'content-type': ['application/json'],
            },
          ),
        ]);
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
          ..httpClientAdapter = adapter;
        final store = _FakeOidcStore(stored: _aSession());
        final tokenClient = _RefreshOnlyTokenClient(
          refreshResult: Success(
            TokenResponse(
              accessToken: 'new',
              refreshToken: 'new-rt',
              idToken: _idToken(),
              tokenType: 'Bearer',
              expiresIn: const Duration(seconds: 60),
            ),
          ),
        );
        final client = BffClient(
          baseUrl: 'http://localhost:3000',
          credentialStore: store,
          dio: dio,
          tokenClient: tokenClient,
          discovery: _kDiscovery,
        );

        final result = await client.get<Map<String, Object?>>('/me');

        expect(result, isA<Failure<Map<String, Object?>>>());
        // Refresh path attempted exactly once (no infinite loop).
        expect(tokenClient.refreshCalls, equals(1));
        // At most 2 HTTP calls (original + retry-once).
        expect(adapter.calls, lessThanOrEqualTo(2));
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Test doubles — local to this file (CLI testing convention: no shared mock
// runtime, fakes only).
// ---------------------------------------------------------------------------

class _FakeCredentialStore implements CredentialStore {
  _FakeCredentialStore({this.stored});
  final OidcSession? stored;

  @override
  Future<OidcSession?> read() async => stored;

  @override
  Future<void> write(OidcSession session) async {}

  @override
  Future<void> clear() async {}
}

/// Captures the last `RequestOptions` Dio sent. Returns a fixed response
/// payload supplied by the test.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({required this.response});
  final ResponseBody response;
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return response;
  }
}

/// Adapter that always raises a synchronous `DioException` to emulate a
/// network/protocol failure. BffClient must convert this into Result.Failure
/// instead of letting the exception escape.
class _ThrowingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'simulated network failure',
    );
  }
}

// ---------------------------------------------------------------------------
// C02 fakes — appended (no modification to C01 fakes above).
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

OidcSession _aSession({
  String accessToken = 'at-old',
  String refreshToken = 'rt-old',
}) => OidcSession(
  accessToken: accessToken,
  refreshToken: refreshToken,
  idToken: _idToken(),
  accessExpiresAt: DateTime.utc(2099, 1, 1),
  sub: '363088829932634233',
  email: 'user@example.com',
  roles: const ['social_worker'],
);

/// Three-part placeholder. BffClient does not decode the id_token; the value
/// only needs to be non-empty for the OidcSession invariant.
String _idToken() => 'header.payload.signature';

class _FakeOidcStore implements CredentialStore {
  _FakeOidcStore({OidcSession? stored}) : _stored = stored;
  OidcSession? _stored;

  @override
  Future<OidcSession?> read() async => _stored;

  @override
  Future<void> write(OidcSession session) async {
    _stored = session;
  }

  @override
  Future<void> clear() async {
    _stored = null;
  }
}

/// Sequenced adapter — pops one canned `ResponseBody` per call, records every
/// `RequestOptions`. Fails fast (via fallback empty 500) if the test makes
/// more requests than scripted, so unexpected fan-out shows up as a red test.
class _SequencedAdapter implements HttpClientAdapter {
  _SequencedAdapter(this._responses);

  final List<ResponseBody> _responses;
  final List<RequestOptions> captured = [];

  int get calls => captured.length;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    if (captured.length > _responses.length) {
      return ResponseBody.fromString(
        'unexpected extra request',
        500,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    return _responses[captured.length - 1];
  }
}

/// TokenClient fake exposing only the `refresh` path used by BffClient.
/// `exchangeCode` is unreachable on this code path; we still implement it
/// to satisfy the interface, returning an explicit failure.
class _RefreshOnlyTokenClient implements TokenClient {
  _RefreshOnlyTokenClient({this.refreshResult});

  final Result<TokenResponse>? refreshResult;
  int refreshCalls = 0;

  @override
  OidcDiscovery get discovery => _kDiscovery;

  @override
  Future<Result<TokenResponse>> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    String clientId = OidcConfig.clientId,
  }) async => const Failure(CliError.server(500, 'not used'));

  @override
  Future<Result<TokenResponse>> refresh({
    required String refreshToken,
    String clientId = OidcConfig.clientId,
    String scopes = OidcConfig.scopes,
  }) async {
    refreshCalls += 1;
    return refreshResult ??
        const Failure(CliError.server(500, 'no result configured'));
  }
}

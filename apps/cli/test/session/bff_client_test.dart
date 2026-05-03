/// W0.5 RED — `BffClient` scaffold contract.
///
/// W1 must create `apps/cli/lib/src/session/bff_client.dart` with:
///
/// ```dart
/// final class BffClient {
///   BffClient({
///     required this.baseUrl,
///     required CredentialStore credentialStore,
///     Dio? dio,
///   });
///
///   final String baseUrl;
///   final CredentialStore _credentialStore;
///   final Dio _dio;
///
///   /// Returns a Result — never throws.
///   Future<Result<T>> get<T>(String path, {T Function(Object?)? decode});
/// }
/// ```
///
/// C01 contract:
///   * Construction wires baseUrl + credentialStore + (optional) Dio.
///   * Bearer interceptor: when CredentialStore yields Credentials, the next
///     request carries `Authorization: Bearer <token>`. When it yields null,
///     no Authorization header is added (caller must run `acdg auth login`
///     first — enforced in C02+).
///   * Adapter that throws → caller sees `Failure(...)`, NEVER an exception.
///
/// Real HTTP wiring (decoding, retry, refresh-on-401) lands in C03+.
library;

import 'dart:typed_data';

import 'package:core_contracts/core_contracts.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';

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
          stored: Credentials(
            accessToken: 'test-token-123',
            refreshToken: 'r',
            expiresAt: DateTime.utc(2099, 1, 1),
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
        final authHeader = captured!.headers['Authorization'] ??
            captured.headers['authorization'];
        expect(authHeader, anyOf(isNull, equals('')));
      },
    );
  });

  group('BffClient — Result discipline (never throws)', () {
    test(
      'adapter failure → Result.Failure (no exception escapes)',
      () async {
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
  final Credentials? stored;

  @override
  Future<Credentials?> read() async => stored;

  @override
  Future<void> write(Credentials credentials) async {}

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


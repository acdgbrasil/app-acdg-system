/// W2 RED helper — `BffClient` test double for MCP tool tests.
///
/// `BffClient` is a `final class` (apps/cli/lib/src/session/bff_client.dart),
/// so the existing CLI test convention (and what we follow here) is to
/// construct a real [BffClient] wired to a stubbed Dio [HttpClientAdapter].
/// That keeps the verb dispatch (GET/POST/...) honest while letting tests
/// assert on the captured request and stage canned responses.
///
/// `_NullCredentialStore` is the always-empty store: tools that take a
/// `BffClient` only here just need outbound dispatch; auth-status / RBAC
/// tests use [FakeCredentialStore] separately.
library;

import 'dart:typed_data';

import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';
import 'package:dio/dio.dart';

/// Builds a real [BffClient] whose Dio adapter responds with [body] and
/// [status]. Returns the adapter alongside so tests can assert on
/// `adapter.lastOptions` (path, method, query string).
({BffClient client, FakeBffAdapter adapter}) buildFakeBffClient({
  String body = '{}',
  int status = 200,
  String baseUrl = 'http://localhost:3000',
}) {
  final adapter = FakeBffAdapter(body: body, status: status);
  final dio = Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
  final client = BffClient(
    baseUrl: baseUrl,
    credentialStore: _NullCredentialStore(),
    dio: dio,
  );
  return (client: client, adapter: adapter);
}

/// Captures the last [RequestOptions] Dio dispatched and returns a fixed
/// `(body, status)` pair. Mirrors the convention used in
/// `test/commands/patient_get_command_test.dart`.
final class FakeBffAdapter implements HttpClientAdapter {
  FakeBffAdapter({required this.body, required this.status});

  String body;
  int status;
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
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class _NullCredentialStore implements CredentialStore {
  @override
  Future<OidcSession?> read() async => null;
  @override
  Future<void> write(OidcSession session) async {}
  @override
  Future<void> clear() async {}
}

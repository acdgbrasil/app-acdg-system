/// W0 RED — `MockBffServer` contract for golden tests.
///
/// Different shape from the per-command `_CapturingAdapter` (C03–C09): those
/// were single-route fixtures used to assert wire details. `MockBffServer`
/// replays canned responses from JSON fixture files so we can drive the FULL
/// CLI through `CliRunner.run([...])` and golden-compare stdout/stderr.
///
/// Pattern-matches by `(method, path)` — query string is ignored when
/// matching. The first registered match wins; unmatched requests return 404
/// so a missing fixture surfaces as a clear failure rather than a hang.
///
/// Typical shape (W1 will compile this):
/// ```dart
/// final server = MockBffServer()
///   ..register(method: 'GET', path: '/patients',
///              fixture: 'patient/list_2_patients.json')
///   ..register(method: 'GET', path: '/patients/<id>', status: 401,
///              fixture: 'errors/auth_expired.json');
///
/// final runner = CliRunner(
///   stdout: out, stderr: err,
///   adapter: server.asAdapter(),                  // W1 contract
///   credentialStore: FakeCredentialStore.signedIn(), // W1 contract
/// );
/// await runner.run(['patient', 'list', '--output=table']);
/// ```
///
/// W1 must:
///   1. Implement [MockBffServer] backed by Dio's [HttpClientAdapter].
///   2. Add `adapter` + `credentialStore` named params to `CliRunner`.
///   3. Provide `FakeCredentialStore` (or expose the test-friendly factory
///      these golden tests assume — see `golden_runner.dart`).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Canonical fixture root — relative to the package.
///
/// Tests resolve fixtures via [MockBffServer.register] (string path) so the
/// fixture name in test source stays short and stable.
const String fixturesRoot = 'test/golden/_fixtures';

/// One canned reply: HTTP status + body bytes + content type.
final class MockResponse {
  const MockResponse({
    required this.statusCode,
    required this.body,
    this.contentType = 'application/json',
  });

  /// Builds a JSON response from a fixture file path (relative to
  /// `test/golden/_fixtures/`). Reads the file synchronously at
  /// registration time so route lookup at request time is allocation-free.
  factory MockResponse.fromFixture(
    String relativePath, {
    int statusCode = 200,
  }) {
    final file = File('$fixturesRoot/$relativePath');
    if (!file.existsSync()) {
      throw StateError(
        'Fixture not found: $fixturesRoot/$relativePath '
        '(did you forget to add it under test/golden/_fixtures/?)',
      );
    }
    return MockResponse(statusCode: statusCode, body: file.readAsStringSync());
  }

  /// Builds a synthetic JSON response from an in-memory map (no file).
  factory MockResponse.json(Object? payload, {int statusCode = 200}) {
    return MockResponse(statusCode: statusCode, body: jsonEncode(payload));
  }

  /// Empty 204 — used by lifecycle commands (admit/discharge/...) that
  /// return no body.
  factory MockResponse.noContent() =>
      const MockResponse(statusCode: 204, body: '');

  final int statusCode;
  final String body;
  final String contentType;
}

/// Replays canned responses for `(method, path)` pairs. Pattern-match is
/// O(N) over registered routes; we expect ≤ 50 routes per test so a Map is
/// not warranted.
final class MockBffServer {
  MockBffServer();

  final List<_Route> _routes = <_Route>[];
  final List<({String method, String path, Map<String, String> query})>
  _requestLog = [];

  /// Registers a response for `(method, path)`. [path] supports a trailing
  /// `*` wildcard so dynamic-id routes can be expressed as
  /// `/patients/*/family-members`.
  ///
  /// [fixture] is a path relative to `test/golden/_fixtures/`; mutually
  /// exclusive with [response] (one of them required).
  void register({
    required String method,
    required String path,
    String? fixture,
    MockResponse? response,
    int statusCode = 200,
  }) {
    if (fixture == null && response == null) {
      throw ArgumentError(
        'register() requires either `fixture` or `response`.',
      );
    }
    if (fixture != null && response != null) {
      throw ArgumentError(
        'register() takes `fixture` OR `response` — not both.',
      );
    }
    final canned =
        response ?? MockResponse.fromFixture(fixture!, statusCode: statusCode);
    _routes.add(
      _Route(method: method.toUpperCase(), path: path, response: canned),
    );
  }

  /// Returns every request the adapter saw, in order, as
  /// `(method, path, query)` tuples — for assertions that need wire
  /// inspection beyond the golden output.
  List<({String method, String path, Map<String, String> query})>
  get recordedRequests => List.unmodifiable(_requestLog);

  /// Adapter to plug into Dio (`dio.httpClientAdapter = server.asAdapter()`).
  HttpClientAdapter asAdapter() => _MockAdapter(this);

  MockResponse _resolve(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = options.uri.path;
    _requestLog.add((
      method: method,
      path: path,
      query: Map<String, String>.from(options.uri.queryParameters),
    ));
    for (final route in _routes) {
      if (route.matches(method: method, path: path)) {
        return route.response;
      }
    }
    return MockResponse.json({
      'error': 'no fixture registered',
      'method': method,
      'path': path,
    }, statusCode: 404);
  }
}

final class _Route {
  const _Route({
    required this.method,
    required this.path,
    required this.response,
  });

  final String method;
  final String path;
  final MockResponse response;

  bool matches({required String method, required String path}) {
    if (method != this.method) return false;
    if (this.path == path) return true;
    // Generic segment-by-segment match — handles single and multi-`*`
    // patterns uniformly. `*` matches a single non-empty segment. Patterns
    // that end with `/*` (single trailing wildcard) and patterns that mix
    // mid-path `*` with a trailing `*` (e.g. `/patients/*/family-members/*`)
    // both go through the same loop. Mismatched segment counts → no match.
    if (this.path.contains('*')) {
      final segments = this.path.split('/');
      final actual = path.split('/');
      if (segments.length != actual.length) return false;
      for (var i = 0; i < segments.length; i++) {
        if (segments[i] == '*') {
          if (actual[i].isEmpty) return false;
          continue;
        }
        if (segments[i] != actual[i]) return false;
      }
      return true;
    }
    return false;
  }
}

final class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._server);

  final MockBffServer _server;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final canned = _server._resolve(options);
    return ResponseBody.fromString(
      canned.body,
      canned.statusCode,
      headers: {
        'content-type': [canned.contentType],
      },
    );
  }
}

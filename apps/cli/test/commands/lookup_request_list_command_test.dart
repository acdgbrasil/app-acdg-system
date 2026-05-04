/// W0 RED — `LookupRequestListCommand` orchestration contract (C08).
///
/// W1 must create
/// `apps/cli/lib/src/commands/lookup_request_list_command.dart`:
///
/// ```dart
/// class LookupRequestListCommand extends Command<int> {
///   LookupRequestListCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   });
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'list';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `GetLookupRequestsIntent` (empty value object) +
/// `LookupContract.getLookupRequests`):
///   * No positionals, no flags. The BFF intent has no parameters.
///   * GET `/lookup-requests` → decoded as
///     `StandardResponse<List<LookupRequestResponse>>`.
///   * Format the `data` list via injected formatter, write to stdout.
///   * 401 / 5xx → non-zero exit + stderr.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_request_list_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kRequestsListJson =
    '{"data":[{"id":"11111111-1111-4111-8111-111111111111",'
    '"tableName":"dominio_parentesco","codigo":"GRANDFATHER",'
    '"descricao":"Avô","justificativa":null,"status":"PENDING",'
    '"createdAt":"2026-05-04T10:00:00Z","requestedBy":"user-uuid"}],'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('LookupRequestListCommand basics', () {
    test('extends Command<int> with name "list"', () {
      final cmd = LookupRequestListCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('list'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('LookupRequestListCommand — happy path', () {
    test('GETs /lookup-requests with no args', () async {
      final adapter = _CapturingAdapter(_kRequestsListJson, status: 200);
      final cmd = LookupRequestListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/lookup-requests'));
      // No query params expected — the BFF intent is an empty value object.
      expect(adapter.lastOptions!.uri.queryParameters, isEmpty);
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kRequestsListJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupRequestListCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const []);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });

    test('empty data array → exit 0 (no governance requests is OK)', () async {
      final adapter = _CapturingAdapter(
        '{"data":[],"meta":{"timestamp":"2026-05-04T12:00:00Z"}}',
        status: 200,
      );
      final cmd = LookupRequestListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, equals(0));
    });
  });

  group('LookupRequestListCommand — failure paths', () {
    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupRequestListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupRequestListCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures + fakes
// ---------------------------------------------------------------------------

BffClient _bff(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return BffClient(
    baseUrl: 'http://localhost:3000',
    credentialStore: _NullStore(),
    dio: dio,
  );
}

class _NullStore implements CredentialStore {
  @override
  Future<OidcSession?> read() async => null;
  @override
  Future<void> write(OidcSession session) async {}
  @override
  Future<void> clear() async {}
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this._body, {required this.status});

  final String _body;
  final int status;
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
      _body,
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

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

class _CapturingFormatter implements OutputFormatter {
  const _CapturingFormatter();
  @override
  String format(Object? data) => '[CAPTURED]\n';
}

Future<int> _runWithArgs(Command<int> cmd, List<String> args) async {
  final runner = CommandRunner<int>('test', 'test')..addCommand(cmd);
  try {
    final code = await runner.run([cmd.name, ...args]);
    return code ?? 0;
  } on UsageException {
    return 64;
  }
}

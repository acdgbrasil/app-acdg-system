/// W0 RED — `LookupBatchCommand` orchestration contract (C08).
///
/// W1 must create `apps/cli/lib/src/commands/lookup_batch_command.dart`:
///
/// ```dart
/// class LookupBatchCommand extends Command<int> {
///   LookupBatchCommand({
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
///   @override String get name => 'batch';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `GetLookupsBatchIntent` + `LookupContract.getLookupsBatch`):
///   * Required positional `<csv>` — comma-separated table names.
///   * **Tolerant CSV split** (project-wide convention, mirrored from
///     `get_lookups_batch_intent.dart` lines 17-21 of the BFF):
///     `"a, b ,c"` → `[a, b, c]`. Whitespace trimmed, empty tokens dropped.
///   * **Cap of 20 tables** (BFF `GetLookupsBatchIntent.maxTables`,
///     `get_lookups_batch_intent.dart:30-32`). 21+ → client-side usage error
///     BEFORE the HTTP call (no BFF round trip wasted on a guaranteed reject).
///   * **Empty after parse** (e.g. `--`, `,,,`, `   `) → usage error,
///     no BFF call.
///   * GET `/lookups?tables=a,b,c` → decoded as
///     `StandardResponse<LookupsBatchResponse>`.
///     Wire query param spelling is exactly `tables=...` (verified against
///     `get_lookups_batch_intent.dart:42` reading `queryParameters['tables']`).
///   * Format the `data.tables` map via injected formatter, write to stdout.
///   * 401 / 5xx → non-zero exit + stderr surfaces status.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_batch_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kBatchResponseJson =
    '{"data":{"tables":{'
    '"dominio_a":[{"id":"11111111-1111-4111-8111-111111111111",'
    '"codigo":"X","descricao":"X-desc"}],'
    '"dominio_b":[{"id":"22222222-2222-4222-8222-222222222222",'
    '"codigo":"Y","descricao":"Y-desc"}]'
    '}},"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('LookupBatchCommand basics', () {
    test('extends Command<int> with name "batch"', () {
      final cmd = LookupBatchCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('batch'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('LookupBatchCommand — happy path', () {
    test('GETs /lookups?tables=a,b,c with the parsed table names', () async {
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        'dominio_a,dominio_b,dominio_c',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/lookups'));

      final qp = adapter.lastOptions!.uri.queryParameters;
      expect(qp.containsKey('tables'), isTrue);
      // The `tables` query param value MUST be a CSV holding the three
      // requested names (matching BFF's `parseFromQuery`, which calls
      // `raw.split(',')`).
      final tablesParam = qp['tables']!;
      expect(tablesParam, contains('dominio_a'));
      expect(tablesParam, contains('dominio_b'));
      expect(tablesParam, contains('dominio_c'));
    });

    test('CSV parsing: trims whitespace and drops empty tokens', () async {
      // Project convention (mirrored by BFF `parseFromQuery` lines 57-61):
      // `"a, b ,c"` → `[a, b, c]`. The CLI MAY normalize before sending OR
      // forward the raw CSV to the BFF — either way, the request must reach
      // the BFF parsable by its tolerant split.
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        'dominio_a, dominio_b ,dominio_c',
      ]);

      expect(exit, equals(0));
      final qp = adapter.lastOptions!.uri.queryParameters;
      final tablesParam = qp['tables']!;
      // After BFF-side tolerant split, all three names must be reachable.
      expect(tablesParam, contains('dominio_a'));
      expect(tablesParam, contains('dominio_b'));
      expect(tablesParam, contains('dominio_c'));
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const ['dominio_a,dominio_b']);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });
  });

  group('LookupBatchCommand — client-side validation', () {
    test('cap of 20 tables: 21 names → usage error, NO BFF call', () async {
      // Mirrors `GetLookupsBatchIntent.maxTables = 20`. The CLI fails fast
      // client-side instead of letting the BFF return 400.
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      // Build a CSV of 21 distinct names.
      final names = List.generate(21, (i) => 'dominio_$i').join(',');
      final exit = await _runWithArgs(cmd, [names]);

      expect(
        exit,
        isNot(equals(0)),
        reason: '21 tables must trigger a client-side usage error',
      );
      expect(
        adapter.lastOptions,
        isNull,
        reason: 'No HTTP call must be made when client-side cap rejects',
      );
    });

    test('exactly 20 tables → accepted (boundary, inclusive)', () async {
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final names = List.generate(20, (i) => 'dominio_$i').join(',');
      final exit = await _runWithArgs(cmd, [names]);

      expect(exit, equals(0));
      expect(adapter.lastOptions, isNotNull);
    });

    test(
      'CSV parses to empty (only commas) → usage error, NO BFF call',
      () async {
        final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
        final cmd = LookupBatchCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [',,,']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      'CSV parses to empty (only whitespace) → usage error, NO BFF call',
      () async {
        final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
        final cmd = LookupBatchCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const ['   ,  ,  ']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing positional CSV → usage error, NO BFF call', () async {
      final adapter = _CapturingAdapter(_kBatchResponseJson, status: 200);
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });
  });

  group('LookupBatchCommand — failure paths', () {
    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const ['dominio_a']);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = LookupBatchCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const ['dominio_a,dominio_b']);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupBatchCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const ['dominio_a']);

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

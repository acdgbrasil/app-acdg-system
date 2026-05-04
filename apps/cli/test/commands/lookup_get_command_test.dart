/// W0 RED — `LookupGetCommand` orchestration contract (C08).
///
/// W1 must create `apps/cli/lib/src/commands/lookup_get_command.dart`:
///
/// ```dart
/// class LookupGetCommand extends Command<int> {
///   LookupGetCommand({
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
///   @override String get name => 'get';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `GetLookupTableIntent` + `LookupContract.getLookupTable`):
///   * Required positional `<table-name>` (e.g. `dominio_parentesco`).
///     `tableName` is a literal pass-through — NOT UUID-validated.
///   * GET `/lookups/<tableName>` → decoded as
///     `StandardResponse<List<LookupItemResponse>>`.
///   * Format the `data` list via injected formatter, write to stdout.
///   * Missing positional → usage error (non-zero exit, no BFF call).
///   * 404 / 401 / 5xx → non-zero exit + stderr surfaces status code.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_get_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kTableName = 'dominio_parentesco';
const String _kLookupTableJson =
    '{"data":[{"id":"11111111-1111-4111-8111-111111111111",'
    '"codigo":"MOTHER","descricao":"Mother"},'
    '{"id":"22222222-2222-4222-8222-222222222222",'
    '"codigo":"FATHER","descricao":"Father"}],'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('LookupGetCommand basics', () {
    test('extends Command<int> with name "get"', () {
      final cmd = LookupGetCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('get'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('LookupGetCommand — happy path', () {
    test('GETs /lookups/<tableName> with the positional table name', () async {
      final adapter = _CapturingAdapter(_kLookupTableJson, status: 200);
      final cmd = LookupGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [_kTableName]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/lookups/$_kTableName'));
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kLookupTableJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupGetCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const [_kTableName]);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });

    test(
      'tableName is pass-through (not UUID-validated): arbitrary literals work',
      () async {
        // `dominio_parentesco`, `dominio_genero`, etc — these are NOT UUIDs.
        // The BFF `GetLookupTableIntent` (path-only) is also pass-through.
        final adapter = _CapturingAdapter(_kLookupTableJson, status: 200);
        final cmd = LookupGetCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const ['dominio_genero']);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.path, equals('/lookups/dominio_genero'));
      },
    );
  });

  group('LookupGetCommand — failure paths', () {
    test(
      'missing positional table-name → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('{}', status: 200);
        final cmd = LookupGetCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const []);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 404 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"LKP_NOT_FOUND","message":"table not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = LookupGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kTableName]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('404'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kTableName]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = LookupGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kTableName]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupGetCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kTableName]);

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

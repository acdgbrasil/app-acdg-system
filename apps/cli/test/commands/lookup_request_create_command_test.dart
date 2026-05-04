/// W0 RED — `LookupRequestCreateCommand` orchestration contract (C08).
///
/// W1 must create
/// `apps/cli/lib/src/commands/lookup_request_create_command.dart`:
///
/// ```dart
/// class LookupRequestCreateCommand extends Command<int> {
///   LookupRequestCreateCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('code',
///           help: 'Proposed item code (required)')
///       ..addOption('label',
///           help: 'Proposed item description (required)')
///       ..addOption('justificativa',
///           help: 'Free-text rationale (optional, PII-dense — '
///                 'never echoed by the BFF in error responses)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'create';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `CreateLookupRequestIntent` + `CreateLookupRequestRequest` +
/// `LookupContract.createLookupRequest`):
///   * Required positional `<table-name>` (literal — pass-through).
///   * Required `--code` (DTO `codigo`) and `--label` (DTO `descricao`).
///   * Optional `--justificativa` (DTO `justificativa?`). PII-dense — the
///     BFF intent (`create_lookup_request_intent.dart:14-20`) never echoes
///     it in error responses. CLI MUST forward verbatim only when present.
///   * POST `/lookup-requests` body shape:
///     ```json
///     {
///       "tableName": "<positional>",
///       "codigo": "<--code>",
///       "descricao": "<--label>",
///       "justificativa": "<optional, omitted when absent>"
///     }
///     ```
///   * Decode `StandardIdResponse` (`{"data":{"id":...},"meta":...}`)
///     and surface the new request id on stdout.
///   * 400 INVALID_CREATE_LOOKUP_REQUEST_BODY / 401 / 5xx → non-zero exit
///     + stderr.
///
/// **Naming decision (deviation).** Ticket prose:
/// `lookup request create &lt;table-name&gt; --code=X --label=Y
/// --justificativa=Z`. DTO-as-canon: wire
/// fields are `tableName`/`codigo`/`descricao`/`justificativa`. CLI flags
/// stay human-friendly (`--code`, `--label`); wire follows DTO. Justificativa
/// keeps its Portuguese spelling because the DTO does (CLI mirrors the
/// canonical wire vocabulary so the user can grep the BFF errors back to
/// the same name).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_request_create_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kTableName = 'dominio_parentesco';
const String _kNewRequestId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kIdResponseJson =
    '{"data":{"id":"$_kNewRequestId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('LookupRequestCreateCommand basics', () {
    test('extends Command<int> with name "create"', () {
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('create'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --code, --label, --justificativa', () {
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('code'));
      expect(options, contains('label'));
      expect(options, contains('justificativa'));
    });
  });

  group('LookupRequestCreateCommand — happy path', () {
    test(
      'POSTs /lookup-requests with the CreateLookupRequestRequest body shape '
      '(DTO field names — tableName/codigo/descricao/justificativa)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = LookupRequestCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          '--code=GRANDFATHER',
          '--label=Avô',
          '--justificativa=Termo solicitado por familias atendidas no NAT.',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
        expect(adapter.lastOptions!.path, equals('/lookup-requests'));

        final body = _decodeBody(adapter.lastOptions!.data);
        // 3 required + 1 optional, all DTO-faithful camelCase.
        expect(body['tableName'], equals(_kTableName));
        expect(body['codigo'], equals('GRANDFATHER'));
        expect(body['descricao'], equals('Avô'));
        expect(
          body['justificativa'],
          equals('Termo solicitado por familias atendidas no NAT.'),
        );
        // CLI-friendly names MUST NOT leak.
        expect(body.containsKey('code'), isFalse);
        expect(body.containsKey('label'), isFalse);
      },
    );

    test('omits --justificativa when absent (DTO `?` convention)', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
        '--label=Avô',
        // No --justificativa.
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['tableName'], equals(_kTableName));
      expect(body['codigo'], equals('GRANDFATHER'));
      expect(body['descricao'], equals('Avô'));
      // `justificativa` MUST be omitted (or null) — the BFF intent reads
      // it via `_asString` returning null on missing/non-string.
      if (body.containsKey('justificativa')) {
        expect(
          body['justificativa'],
          isNull,
          reason: 'justificativa must be omitted or null when absent',
        );
      }
    });

    test('surfaces the returned request id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
        '--label=Avô',
      ]);

      expect(exit, equals(0));
      expect(stdout.toString(), contains(_kNewRequestId));
    });
  });

  group('LookupRequestCreateCommand — failure paths', () {
    test(
      'missing positional table-name → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = LookupRequestCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--code=GRANDFATHER',
          '--label=Avô',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --code → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kTableName, '--label=Avô']);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --label → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'BFF 400 INVALID_CREATE_LOOKUP_REQUEST_BODY → non-zero exit + stderr',
      () async {
        final adapter = _CapturingAdapter(
          '{"error":{"code":"INVALID_CREATE_LOOKUP_REQUEST_BODY",'
          '"message":"missing or empty [tableName]"}}',
          status: 400,
        );
        final stderr = StringBuffer();
        final cmd = LookupRequestCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: stderr,
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          '--code=GRANDFATHER',
          '--label=Avô',
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('400'));
      },
    );

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
        '--label=Avô',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
        '--label=Avô',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupRequestCreateCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=GRANDFATHER',
        '--label=Avô',
      ]);

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

Map<String, Object?> _decodeBody(Object? raw) {
  if (raw is Map<String, Object?>) return raw;
  if (raw is String) {
    if (raw.isEmpty) return const <String, Object?>{};
    final decoded = jsonDecode(raw);
    return decoded as Map<String, Object?>;
  }
  if (raw == null) return const <String, Object?>{};
  fail('Unexpected request body shape: ${raw.runtimeType}');
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

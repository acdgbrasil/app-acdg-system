/// W0 RED — `LookupCreateCommand` orchestration contract (C08).
///
/// W1 must create `apps/cli/lib/src/commands/lookup_create_command.dart`:
///
/// ```dart
/// class LookupCreateCommand extends Command<int> {
///   LookupCreateCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('code', help: 'Lookup item code (required)')
///       ..addOption('label', help: 'Lookup item description (required)');
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
/// Behavior (per `CreateLookupItemIntent` + `CreateLookupItemRequest` +
/// `LookupContract.createLookupItem`):
///   * Required positional `<table-name>` (literal — pass-through, NOT UUID).
///   * Required `--code` (BFF intent line 41-49: `codigo` non-empty string).
///   * Required `--label` (BFF intent line 41-49: `descricao` non-empty
///     string). UI label flips back to DTO `descricao` on the wire.
///   * POST `/lookups/<tableName>` with body shape:
///     ```json
///     {"codigo": "<code>", "descricao": "<label>"}
///     ```
///   * Decode response as `StandardIdResponse`
///     (`{"data": {"id": "<uuid>"}, "meta": {...}}`) and surface the new
///     item id on stdout (uses shared `decodeStandardIdResponse` helper).
///   * 401 → exit 2 + auth stderr.
///   * 4xx (e.g. 400 INVALID_CREATE_LOOKUP_ITEM_BODY) / 5xx → non-zero exit +
///     status-code stderr.
///   * Network failure → non-zero exit.
///
/// **Naming decision (deviation).** Ticket prose: `--code=X --label=Y`.
/// DTO is `{codigo, descricao}`. We expose CLI flags as the ticket dictates
/// (`--code`, `--label`) and translate to DTO field names on the wire.
/// This mirrors C03 W2 M1: DTO names dominate the WIRE; CLI flags can be
/// human-friendly. Pin: see body-shape test below — the request body MUST
/// carry `codigo` + `descricao`, NOT `code`/`label`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_create_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kTableName = 'dominio_parentesco';
const String _kNewItemId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kIdResponseJson =
    '{"data":{"id":"$_kNewItemId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('LookupCreateCommand basics', () {
    test('extends Command<int> with name "create"', () {
      final cmd = LookupCreateCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('create'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --code and --label options', () {
      final cmd = LookupCreateCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('code'));
      expect(options, contains('label'));
    });
  });

  group('LookupCreateCommand — happy path', () {
    test(
      'POSTs /lookups/<tableName> with the CreateLookupItemRequest body shape '
      '(DTO field names — codigo/descricao, NOT code/label)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = LookupCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          '--code=MOTHER',
          '--label=Mãe',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
        expect(adapter.lastOptions!.path, equals('/lookups/$_kTableName'));

        final body = _decodeBody(adapter.lastOptions!.data);
        // DTO-as-canon: wire fields are `codigo` and `descricao`.
        expect(body['codigo'], equals('MOTHER'));
        expect(body['descricao'], equals('Mãe'));
        // CLI-friendly names MUST NOT leak onto the wire.
        expect(body.containsKey('code'), isFalse);
        expect(body.containsKey('label'), isFalse);
      },
    );

    test('surfaces the returned item id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=MOTHER',
        '--label=Mãe',
      ]);

      expect(exit, equals(0));
      // The returned id MUST appear somewhere in stdout — formatter or raw,
      // W1 chooses. The contract is: user can see the id of the item they
      // just created.
      expect(stdout.toString(), contains(_kNewItemId));
    });

    test('decodes BFF response as StandardIdResponse '
        '(reads data.id, NOT a flat {id:...})', () async {
      // BFF wire shape `{"data":{"id":...},"meta":{...}}` per
      // `lookup_handler.dart:_respondWithId`. A naive `body['id']` access
      // would fail. Pins envelope traversal via the shared
      // `decodeStandardIdResponse` helper.
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=X',
        '--label=Y',
      ]);

      expect(exit, equals(0));
      expect(stdout.toString(), contains(_kNewItemId));
    });
  });

  group('LookupCreateCommand — failure paths', () {
    test(
      'missing positional table-name → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = LookupCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--code=MOTHER',
          '--label=Mãe',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --code → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kTableName, '--label=Mãe']);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --label → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=MOTHER',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'BFF 400 INVALID_CREATE_LOOKUP_ITEM_BODY → non-zero exit + stderr',
      () async {
        final adapter = _CapturingAdapter(
          '{"error":{"code":"INVALID_CREATE_LOOKUP_ITEM_BODY",'
          '"message":"missing or empty [codigo]"}}',
          status: 400,
        );
        final stderr = StringBuffer();
        final cmd = LookupCreateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: stderr,
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          '--code=MOTHER',
          '--label=Mãe',
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('400'));
      },
    );

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=MOTHER',
        '--label=Mãe',
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
      final cmd = LookupCreateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=MOTHER',
        '--label=Mãe',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupCreateCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--code=MOTHER',
        '--label=Mãe',
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
    final decoded = jsonDecode(raw);
    return decoded as Map<String, Object?>;
  }
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

/// W0 RED — `LookupToggleCommand` orchestration contract (C08).
///
/// **Introduces the PATCH HTTP verb** to the CLI. Up to C07 the BFF client
/// covered GET/POST/PUT/DELETE; toggle is the first PATCH endpoint. The new
/// `BffClient.patch&lt;T&gt;` contract is pinned in `bff_client_test.dart`
/// under "BffClient — patch&lt;T&gt; verb (C08)".
///
/// W1 must create `apps/cli/lib/src/commands/lookup_toggle_command.dart`:
///
/// ```dart
/// class LookupToggleCommand extends Command<int> {
///   LookupToggleCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser.addOption('active',
///         help: 'New active flag (true/false). When omitted, defaults '
///               'to flipping the current state.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'toggle';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `ToggleLookupItemIntent` + `ToggleLookupItemRequest` +
/// `LookupContract.toggleLookupItem`):
///   * Required positionals `<table-name> <item-id>` (item-id is UUID v4).
///   * Body shape per the BFF intent (`toggle_lookup_item_intent.dart:53`):
///     ```json
///     {"active": true|false}
///     ```
///     `active` is required, MUST be a `bool`. The intent rejects missing
///     or type-mismatched values with a const PII-safe error.
///   * `--active` flag accepts `true`/`false`. **Required** when CLI cannot
///     read prior state (no GET-before-PATCH side trip). The ticket prose
///     says "active flip" implying server-side flip but the BFF intent
///     demands an explicit boolean — DTO-as-canon: the CLI MUST pass an
///     explicit `--active=true|false`.
///   * **PATCH** `/lookups/<tableName>/<itemId>/toggle` (NEW verb).
///   * 204 No Content → exit 0.
///   * 400 INVALID_TOGGLE_LOOKUP_ITEM_BODY (missing `active` or UUID failure)
///     / 401 / 5xx → non-zero exit + stderr surfaces status.
///
/// **Naming decision (deviation).** Ticket prose:
/// `lookup toggle &lt;table&gt; &lt;id&gt;` — implies no flag (server flips).
/// DTO+intent require explicit
/// `{active: bool}`. Following DTO-as-canon (C03 W2 M1), CLI must pass
/// `--active=...`. See REPORT.md §"Decisions".
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_toggle_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kTableName = 'dominio_parentesco';
const String _kItemId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('LookupToggleCommand basics', () {
    test('extends Command<int> with name "toggle"', () {
      final cmd = LookupToggleCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('toggle'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --active option', () {
      final cmd = LookupToggleCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('active'));
    });
  });

  group('LookupToggleCommand — happy path', () {
    test(
      'PATCHes /lookups/<tableName>/<itemId>/toggle with {active: bool} body '
      '(NEW PATCH verb wire-method)',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupToggleCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--active=true',
        ]);

        expect(exit, equals(0));
        // **PATCH not PUT** — pin the new wire method explicitly.
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PATCH'));
        expect(
          adapter.lastOptions!.path,
          equals('/lookups/$_kTableName/$_kItemId/toggle'),
        );

        final body = _decodeBody(adapter.lastOptions!.data);
        // BFF intent (`toggle_lookup_item_intent.dart:53`) requires
        // `body['active']` to be a `bool`. Pin that the wire holds the
        // boolean type, not a string `"true"`.
        expect(body['active'], equals(true));
        expect(body['active'], isA<bool>());
      },
    );

    test('--active=false serializes as boolean false on the wire', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupToggleCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--active=false',
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['active'], equals(false));
      expect(body['active'], isA<bool>());
    });

    test('204 No Content → exit 0', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupToggleCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--active=true',
      ]);

      expect(exit, equals(0));
    });
  });

  group('LookupToggleCommand — failure paths', () {
    test(
      'missing positional table-name → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupToggleCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const ['--active=true']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing positional item-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupToggleCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        '--active=true',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'missing --active → non-zero exit (DTO requires explicit bool), no BFF call',
      () async {
        // BFF intent demands `body['active']` be a `bool` — an absent flag
        // would either send no body or send malformed JSON. CLI must fail
        // fast client-side.
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupToggleCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [_kTableName, _kItemId]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      'invalid --active value (not true/false) → usage error, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupToggleCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--active=maybe',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      'BFF 400 INVALID_TOGGLE_LOOKUP_ITEM_BODY → non-zero exit + stderr',
      () async {
        final adapter = _CapturingAdapter(
          '{"error":{"code":"INVALID_TOGGLE_LOOKUP_ITEM_BODY",'
          '"message":"missing or invalid [active]"}}',
          status: 400,
        );
        final stderr = StringBuffer();
        final cmd = LookupToggleCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: stderr,
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--active=true',
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('400'));
      },
    );

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupToggleCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--active=true',
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
      final cmd = LookupToggleCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--active=true',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupToggleCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--active=true',
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

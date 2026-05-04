/// W0 RED — `TeamListCommand` orchestration contract (C09).
///
/// W1 must create `apps/cli/lib/src/commands/team_list_command.dart`:
///
/// ```dart
/// class TeamListCommand extends Command<int> {
///   TeamListCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('role',   help: 'Filter by role code (optional)')
///       ..addOption('active', help: 'Filter by active flag: true|false')
///       ..addOption('search', help: 'Free-text search (optional)');
///   }
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
/// Behavior (per `ListTeamIntent.parseFromQuery` + `TeamContract.listTeam`):
///   * **All 3 filters optional** — first "query-tolerant" intent in the
///     BFF Web canon (cf. `list_team_intent.dart:7-21`). Zero filters →
///     valid call listing everything.
///   * GET `/team` with `queryParameters` map. Path stays clean — query
///     keys ONLY appear when the user passed the matching flag.
///   * `--active` is a string flag with literal `true`/`false` semantics
///     (BFF intent `list_team_intent.dart:65-79` accepts ONLY those two
///     literal strings). The CLI forwards the raw string as-is.
///   * Decoded as `StandardResponse<List<TeamMemberResponse>>`. Format the
///     `data` list via injected formatter, write to stdout.
///   * 401 → `AuthRequiredError` → exit 2 + auth stderr.
///   * 4xx (`INVALID_LIST_TEAM_QUERY`) / 5xx → non-zero exit + status code
///     in stderr.
///   * Network failure → exit 3 + network message.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_list_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kListResponseJson =
    '{"data":['
    '{"id":"11111111-1111-4111-8111-111111111111",'
    '"personId":"22222222-2222-4222-8222-222222222222",'
    '"fullName":"Ana Souza","email":"ana@example.org","phone":null,'
    '"active":true,"primaryRole":"social_worker"}],'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('TeamListCommand basics', () {
    test('extends Command<int> with name "list"', () {
      final cmd = TeamListCommand(
        bffClient: _bff(_CapturingAdapter(_kListResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('list'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --role, --active, --search options', () {
      final cmd = TeamListCommand(
        bffClient: _bff(_CapturingAdapter(_kListResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('role'));
      expect(options, contains('active'));
      expect(options, contains('search'));
    });
  });

  group('TeamListCommand — happy path', () {
    test('GETs /team with NO query params when no flags passed', () async {
      final adapter = _CapturingAdapter(_kListResponseJson, status: 200);
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/team'));

      final qp = adapter.lastOptions!.uri.queryParameters;
      // Per BFF intent `list_team_intent.dart:65-69`: an empty `active`
      // string is treated as null (not malformed). The CLI MUST omit
      // absent flags — it MUST NOT send `role=&active=&search=`.
      expect(qp.containsKey('role'), isFalse);
      expect(qp.containsKey('active'), isFalse);
      expect(qp.containsKey('search'), isFalse);
    });

    test('GETs /team?role=X when only --role is passed', () async {
      final adapter = _CapturingAdapter(_kListResponseJson, status: 200);
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const ['--role=social_worker']);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.path, equals('/team'));

      final qp = adapter.lastOptions!.uri.queryParameters;
      expect(qp['role'], equals('social_worker'));
      expect(qp.containsKey('active'), isFalse);
      expect(qp.containsKey('search'), isFalse);
    });

    test(
      'GETs /team?role=X&active=true&search=Y when all three flags passed',
      () async {
        final adapter = _CapturingAdapter(_kListResponseJson, status: 200);
        final cmd = TeamListCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--role=social_worker',
          '--active=true',
          '--search=Ana',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.path, equals('/team'));

        final qp = adapter.lastOptions!.uri.queryParameters;
        expect(qp['role'], equals('social_worker'));
        // BFF intent `list_team_intent.dart:65-79` accepts literal
        // `true`/`false` only. The CLI forwards as string.
        expect(qp['active'], equals('true'));
        expect(qp['search'], equals('Ana'));
      },
    );

    test('GETs /team?active=false (literal string)', () async {
      final adapter = _CapturingAdapter(_kListResponseJson, status: 200);
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const ['--active=false']);

      expect(exit, equals(0));
      final qp = adapter.lastOptions!.uri.queryParameters;
      expect(qp['active'], equals('false'));
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kListResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const []);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });
  });

  group('TeamListCommand — failure paths', () {
    test('BFF 400 INVALID_LIST_TEAM_QUERY → non-zero exit + stderr', () async {
      // Per BFF handler `team_handler.dart:107-111`: malformed `active`
      // (e.g. `--active=abc`) surfaces as `INVALID_LIST_TEAM_QUERY` 400.
      // The CLI does NOT validate `active` client-side — it forwards the
      // raw string and lets the BFF reject.
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_LIST_TEAM_QUERY",'
        '"message":"[active] must be \\"true\\" or \\"false\\""}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const ['--active=abc']);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('400'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = TeamListCommand(
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
      final cmd = TeamListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = TeamListCommand(
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

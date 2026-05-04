/// W0 RED — `TeamGetCommand` orchestration contract (C09).
///
/// W1 must create `apps/cli/lib/src/commands/team_get_command.dart`:
///
/// ```dart
/// class TeamGetCommand extends Command<int> {
///   TeamGetCommand({
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
/// Behavior (per `GetTeamMemberIntent.parseFromPath` +
/// `TeamContract.getTeamMember`):
///   * Required positional `<member-id>` (UUID v4 — BFF intent gates).
///   * GET `/team/<id>` → decoded as
///     `StandardResponse<TeamMemberDetailResponse>`.
///   * Format the `data` object via injected formatter, write to stdout.
///   * Missing positional → usage error 64, no BFF call.
///   * 400 INVALID_GET_TEAM_MEMBER_PARAMS (UUID failure) / 404 / 401 / 5xx →
///     non-zero exit + status code in stderr.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_get_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kMemberId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kPersonId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kMemberDetailJson =
    '{"data":{"id":"$_kMemberId","personId":"$_kPersonId",'
    '"fullName":"Ana Souza","email":"ana@example.org","phone":null,'
    '"active":true,"roles":[]},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('TeamGetCommand basics', () {
    test('extends Command<int> with name "get"', () {
      final cmd = TeamGetCommand(
        bffClient: _bff(_CapturingAdapter(_kMemberDetailJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('get'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('TeamGetCommand — happy path', () {
    test('GETs /team/<member-id> with the positional id', () async {
      final adapter = _CapturingAdapter(_kMemberDetailJson, status: 200);
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/team/$_kMemberId'));
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kMemberDetailJson, status: 200);
      final stdout = StringBuffer();
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const [_kMemberId]);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });
  });

  group('TeamGetCommand — failure paths', () {
    test('missing positional member-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kMemberDetailJson, status: 200);
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 400 INVALID_GET_TEAM_MEMBER_PARAMS (UUID failure) → '
        'non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_GET_TEAM_MEMBER_PARAMS",'
        '"message":"memberId must be UUID v4"}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('400'));
    });

    test('BFF 404 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"WORKER_NOT_FOUND","message":"member not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('404'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = TeamGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = TeamGetCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

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

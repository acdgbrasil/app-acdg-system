/// W0 RED — `TeamResetPasswordCommand` orchestration contract (C09).
///
/// W1 must create
/// `apps/cli/lib/src/commands/team_reset_password_command.dart`:
///
/// ```dart
/// class TeamResetPasswordCommand extends Command<int> {
///   TeamResetPasswordCommand({
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
///   @override String get name => 'reset-password';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `ResetPasswordIntent.parseFromPath` (path-only) +
/// `TeamContract.resetPassword`):
///   * Required positional `<member-id>` (UUID v4 — BFF intent gates).
///   * **POST + No body** — fire-and-forget per
///     `reset_password_intent.dart:11-12` (Zitadel handles the actual
///     reset email out-of-band). Per BFF handler `team_handler.dart:92`,
///     the route is `r.post('/team/<id>/reset-password')`.
///   * POST `/team/<member-id>/reset-password` → 200/204 → exit 0.
///   * 400 INVALID_RESET_PASSWORD_PARAMS (UUID failure) / 404 / 401 / 5xx →
///     non-zero exit + status code in stderr.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_reset_password_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kMemberId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kVoidResponseJson =
    '{"data":null,"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('TeamResetPasswordCommand basics', () {
    test('extends Command<int> with name "reset-password"', () {
      final cmd = TeamResetPasswordCommand(
        bffClient: _bff(_CapturingAdapter(_kVoidResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('reset-password'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('TeamResetPasswordCommand — happy path', () {
    test('POSTs /team/<id>/reset-password with NO body', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = TeamResetPasswordCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, equals(0));
      // The BFF handler `team_handler.dart:92` routes this as POST
      // (deliberate divergence from PUT-for-status verbs since the
      // operation kicks off an out-of-band side effect).
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(
        adapter.lastOptions!.path,
        equals('/team/$_kMemberId/reset-password'),
      );
      // No body on a path-only POST.
      final raw = adapter.lastOptions!.data;
      expect(
        raw,
        anyOf(isNull, equals(''), equals(<String, Object?>{}), isEmpty),
      );
    });
  });

  group('TeamResetPasswordCommand — failure paths', () {
    test('missing positional member-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = TeamResetPasswordCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 400 INVALID_RESET_PASSWORD_PARAMS (UUID failure) → '
        'non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_RESET_PASSWORD_PARAMS",'
        '"message":"memberId must be UUID v4"}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = TeamResetPasswordCommand(
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
        '{"error":{"code":"WORKER_NOT_FOUND","message":"not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = TeamResetPasswordCommand(
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
      final cmd = TeamResetPasswordCommand(
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
      final cmd = TeamResetPasswordCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kMemberId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = TeamResetPasswordCommand(
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

Future<int> _runWithArgs(Command<int> cmd, List<String> args) async {
  final runner = CommandRunner<int>('test', 'test')..addCommand(cmd);
  try {
    final code = await runner.run([cmd.name, ...args]);
    return code ?? 0;
  } on UsageException {
    return 64;
  }
}

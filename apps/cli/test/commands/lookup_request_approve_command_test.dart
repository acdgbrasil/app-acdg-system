/// W0 RED — `LookupRequestApproveCommand` orchestration contract (C08).
///
/// W1 must create
/// `apps/cli/lib/src/commands/lookup_request_approve_command.dart`:
///
/// ```dart
/// class LookupRequestApproveCommand extends Command<int> {
///   LookupRequestApproveCommand({
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
///   @override String get name => 'approve';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `ApproveLookupRequestIntent` (path-only) +
/// `LookupContract.approveLookupRequest`):
///   * Required positional `<request-id>` (UUID v4 — BFF intent enforces).
///   * **No body** — path-only PUT.
///   * PUT `/lookup-requests/<id>/approve` → 204 No Content → exit 0.
///   * 400 INVALID_APPROVE_LOOKUP_REQUEST_PARAMS (UUID failure) /
///     401 / 5xx → non-zero exit + stderr surfaces status.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_request_approve_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kRequestId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('LookupRequestApproveCommand basics', () {
    test('extends Command<int> with name "approve"', () {
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('approve'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('LookupRequestApproveCommand — happy path', () {
    test('PUTs /lookup-requests/<id>/approve with NO body', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
      expect(
        adapter.lastOptions!.path,
        equals('/lookup-requests/$_kRequestId/approve'),
      );
      // No body on a path-only approve.
      final raw = adapter.lastOptions!.data;
      expect(
        raw,
        anyOf(isNull, equals(''), equals(<String, Object?>{}), isEmpty),
      );
    });

    test('204 No Content → exit 0', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, equals(0));
    });
  });

  group('LookupRequestApproveCommand — failure paths', () {
    test(
      'missing positional request-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupRequestApproveCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const []);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 400 INVALID_APPROVE_LOOKUP_REQUEST_PARAMS (UUID failure) → '
        'non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_APPROVE_LOOKUP_REQUEST_PARAMS",'
        '"message":"requestId must be UUID v4"}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('400'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 404 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"LKR_NOT_FOUND","message":"request not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('404'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupRequestApproveCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

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

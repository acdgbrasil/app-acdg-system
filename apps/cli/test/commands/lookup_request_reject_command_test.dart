/// W0 RED — `LookupRequestRejectCommand` orchestration contract (C08).
///
/// W1 must create
/// `apps/cli/lib/src/commands/lookup_request_reject_command.dart`:
///
/// ```dart
/// class LookupRequestRejectCommand extends Command<int> {
///   LookupRequestRejectCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser.addOption('reason',
///         help: 'Optional rejection reason (free-text). NOTE: not in DTO');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'reject';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `RejectLookupRequestIntent` (path-only) +
/// `LookupContract.rejectLookupRequest`):
///   * Required positional `<request-id>` (UUID v4 — BFF intent enforces).
///   * **Path-only PUT** — `RejectLookupRequestIntent` is path-only with no
///     body parser. The contract method signature
///     (`Future&lt;Result&lt;StandardResponse&lt;void&gt;&gt;&gt;
///     rejectLookupRequest(String requestId)`) carries no payload.
///   * **`--reason` is OPTIONAL CLI sugar.** Ticket prose lists it but no
///     DTO field exists. Two options:
///       (a) Forward it as a body field (BFF currently ignores extra keys
///           because the intent has no body parser).
///       (b) Drop the flag silently or emit a warning.
///     The CLI MUST NOT BREAK if `--reason` is passed — the test below
///     just asserts the path/method are correct. Body, if sent, MAY carry
///     `{reason: ...}` or be empty. See REPORT.md §"Open questions" — W1
///     to decide if reason is forwarded.
///   * PUT `/lookup-requests/<id>/reject` → 204 No Content → exit 0.
///   * 400 INVALID_REJECT_LOOKUP_REQUEST_PARAMS (UUID failure) /
///     401 / 5xx → non-zero exit + stderr surfaces status.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_request_reject_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kRequestId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('LookupRequestRejectCommand basics', () {
    test('extends Command<int> with name "reject"', () {
      final cmd = LookupRequestRejectCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('reject'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --reason option', () {
      final cmd = LookupRequestRejectCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('reason'));
    });
  });

  group('LookupRequestRejectCommand — happy path', () {
    test('PUTs /lookup-requests/<id>/reject', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupRequestRejectCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
      expect(
        adapter.lastOptions!.path,
        equals('/lookup-requests/$_kRequestId/reject'),
      );
    });

    test('204 No Content → exit 0', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupRequestRejectCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, equals(0));
    });

    test(
      'CLI does not break when --reason is passed (W1 may forward or drop)',
      () async {
        // BFF intent is path-only — extra body keys are silently ignored.
        // The CLI MAY forward `--reason` as `{reason: ...}` or drop it.
        // This test only asserts the call still reaches the right path
        // with a 2xx success — no contract on body shape.
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupRequestRejectCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kRequestId,
          '--reason=Duplicado de outra solicitação aprovada.',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
        expect(
          adapter.lastOptions!.path,
          equals('/lookup-requests/$_kRequestId/reject'),
        );
      },
    );
  });

  group('LookupRequestRejectCommand — failure paths', () {
    test(
      'missing positional request-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupRequestRejectCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const []);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 400 INVALID_REJECT_LOOKUP_REQUEST_PARAMS (UUID failure) → '
        'non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_REJECT_LOOKUP_REQUEST_PARAMS",'
        '"message":"requestId must be UUID v4"}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = LookupRequestRejectCommand(
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
      final cmd = LookupRequestRejectCommand(
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
      final cmd = LookupRequestRejectCommand(
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
      final cmd = LookupRequestRejectCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kRequestId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupRequestRejectCommand(
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

/// W0 RED — `PatientWithdrawCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_withdraw_command.dart`:
///
/// ```dart
/// class PatientWithdrawCommand extends Command<int> {
///   PatientWithdrawCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('reason', help: 'Reason for withdraw (required)')
///       ..addOption('notes', help: 'Optional notes');
///   }
///   @override String get name => 'withdraw';
///   @override Future<int> run();
/// }
/// ```
///
/// IMPORTANT — contract divergence with the C03 ticket prose:
///   The ticket marks `--reason` as optional, but the
///   `WithdrawPatientRequest` DTO declares `reason` as REQUIRED. The CLI
///   mirrors the DTO (required), to fail fast in the CLI rather than let
///   the BFF reject with 400. (Flagged in REPORT.)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_withdraw_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('PatientWithdrawCommand basics', () {
    test('extends Command<int> with name "withdraw"', () {
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('withdraw'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares reason / notes options', () {
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('reason'));
      expect(options, contains('notes'));
    });
  });

  group('PatientWithdrawCommand — happy path', () {
    test('POSTs /patients/<id>/withdraw with reason+notes body', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--reason=No-show 3 attempts',
        '--notes=Family unreachable since March',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$_kPatientId/withdraw'),
      );
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['reason'], equals('No-show 3 attempts'));
      expect(body['notes'], equals('Family unreachable since March'));
    });

    test('omits notes from body when not provided', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--reason=No-show',
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['reason'], equals('No-show'));
      expect(body.containsKey('notes') ? body['notes'] : null, isNull);
    });
  });

  group('PatientWithdrawCommand — failure paths', () {
    test('missing positional patient-id → non-zero exit', () async {
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const ['--reason=x']);

      expect(exit, isNot(equals(0)));
    });

    test('missing --reason → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 → non-zero exit', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_STATE","message":"cannot withdraw admitted patient"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId, '--reason=x']);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = PatientWithdrawCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId, '--reason=x']);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
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

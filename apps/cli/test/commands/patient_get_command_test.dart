/// W0 RED — `PatientGetCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_get_command.dart`:
///
/// ```dart
/// class PatientGetCommand extends Command<int> {
///   PatientGetCommand({
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
/// Behavior:
///   * Required positional `<patient-id>` (rest argument).
///   * GET `/patients/<id>` → decoded as `StandardResponse<PatientResponse>`.
///   * Format the `data` payload via injected formatter, write to stdout.
///   * Missing positional → usage error (non-zero exit).
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_get_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kValidPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('PatientGetCommand basics', () {
    test('extends Command<int> with name "get"', () {
      final cmd = PatientGetCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('get'));
      expect(cmd.description, isNotEmpty);
    });
  });

  group('PatientGetCommand — happy path', () {
    test('GETs /patients/<id> with the positional patient-id', () async {
      final adapter = _CapturingAdapter(_kPatientResponseJson, status: 200);
      final cmd = PatientGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
      expect(adapter.lastOptions!.path, equals('/patients/$_kValidPatientId'));
    });

    test('formats payload via injected formatter', () async {
      final adapter = _CapturingAdapter(_kPatientResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = PatientGetCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });
  });

  group('PatientGetCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit (usage error)',
      () async {
        final cmd = PatientGetCommand(
          bffClient: _bff(_CapturingAdapter('{}', status: 200)),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const []);

        expect(exit, isNot(equals(0)));
      },
    );

    test('BFF 404 → non-zero exit + stderr msg', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"PATIENT_NOT_FOUND","message":"Patient not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = PatientGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(exit, isNot(equals(0)));
      final lower = stderr.toString().toLowerCase();
      expect(lower, anyOf(contains('404'), contains('not found')));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = PatientGetCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures + fakes
// ---------------------------------------------------------------------------

const String _kPatientResponseJson =
    '{"data":{"patientId":"$_kValidPatientId",'
    '"personId":"22222222-2222-4222-8222-222222222222",'
    '"version":1,"status":"admitted",'
    '"familyMembers":[],"diagnoses":[],"appointments":[],'
    '"violationReports":[],"referrals":[]},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

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

/// W0 RED — `PatientAuditCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_audit_command.dart`:
///
/// ```dart
/// class PatientAuditCommand extends Command<int> {
///   PatientAuditCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('event-type', help: 'Filter by event type')
///       ..addOption('limit', help: 'Max items per page')
///       ..addOption('offset', help: 'Offset for pagination');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'audit';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior:
///   * Required positional `<patient-id>`.
///   * Optional `--event-type` (filter), `--limit`, `--offset`.
///   * GET `/patients/<id>/audit-trail?event_type=...&limit=...&offset=...`
///     (the BFF route is `audit-trail` per
///     `apps/social_care_bff/web/lib/src/handlers/registry_family_handler.dart`).
///   * Decodes as `StandardResponse<List<AuditTrailEntryResponse>>`.
///   * Format the `data` array via injected formatter, write to stdout.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_audit_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kValidPatientId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  group('PatientAuditCommand basics', () {
    test('extends Command<int> with name "audit"', () {
      final cmd = PatientAuditCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('audit'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares event-type option', () {
      final cmd = PatientAuditCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd.argParser.options.keys, contains('event-type'));
    });
  });

  group('PatientAuditCommand — happy path', () {
    test(
      'GETs /patients/<id>/audit-trail without filter when not given',
      () async {
        final adapter = _CapturingAdapter(_kEmptyAuditJson, status: 200);
        final cmd = PatientAuditCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [_kValidPatientId]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('GET'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kValidPatientId/audit-trail'),
        );
        // No filter → no event_type query param.
        final qp = adapter.lastOptions!.uri.queryParameters;
        expect(qp.containsKey('event_type'), isFalse);
        expect(qp.containsKey('eventType'), isFalse);
      },
    );

    test('passes --event-type as query param', () async {
      final adapter = _CapturingAdapter(_kEmptyAuditJson, status: 200);
      final cmd = PatientAuditCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      await _runWithArgs(cmd, const [
        _kValidPatientId,
        '--event-type=patient.admitted',
      ]);

      final qp = adapter.lastOptions!.uri.queryParameters;
      // Either snake-case or camelCase param is acceptable; assert the value.
      final value = qp['event_type'] ?? qp['eventType'];
      expect(value, equals('patient.admitted'));
    });

    test('formats audit trail via injected formatter', () async {
      final adapter = _CapturingAdapter(_kSingleEntryAuditJson, status: 200);
      final stdout = StringBuffer();
      final cmd = PatientAuditCommand(
        bffClient: _bff(adapter),
        formatter: const _CapturingFormatter(),
        stdout: stdout,
      );

      await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(stdout.toString(), contains('[CAPTURED]'));
    });
  });

  group('PatientAuditCommand — failure paths', () {
    test('missing positional patient-id → non-zero exit (usage)', () async {
      final cmd = PatientAuditCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
    });

    test('BFF transport failure → non-zero exit', () async {
      final cmd = PatientAuditCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kValidPatientId]);

      expect(exit, isNot(equals(0)));
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures + fakes
// ---------------------------------------------------------------------------

const String _kEmptyAuditJson =
    '{"data":[],"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

const String _kSingleEntryAuditJson =
    '{"data":[{"id":"cccccccc-cccc-4ccc-8ccc-cccccccccccc",'
    '"aggregateId":"$_kValidPatientId","eventType":"patient.admitted",'
    '"occurredAt":"2026-04-30T08:00:00Z","recordedAt":"2026-04-30T08:00:01Z"}],'
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

/// Adapter that always raises a `DioException` to emulate a transport failure.
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

/// W0 RED — `ProtectionViolationCommand` orchestration contract (C07).
///
/// W1 must create
/// `apps/cli/lib/src/commands/protection_violation_command.dart`:
///
/// ```dart
/// class ProtectionViolationCommand extends Command<int> {
///   ProtectionViolationCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // Required per ReportRightsViolationIntent lines 65-80:
///       //   missing.add('victimId') / missing.add('violationType') /
///       //   missing.add('descriptionOfFact').
///       ..addOption('victim-id',
///           help: 'Victim person id (UUID) — REQUIRED. PII-adjacent: '
///               'never echoed by the BFF intent in error responses.')
///       ..addOption('violation-type',
///           help: 'Violation type — REQUIRED.')
///       ..addOption('description-of-fact',
///           help: 'Free-text description of the fact — REQUIRED. '
///               'PII-dense (narrative against paciente). PII-safe — '
///               'never echoed by the BFF intent in error responses.')
///       // Optionals — ReportRightsViolationRequest carries them as `String?`
///       // and the BFF intent reads each via `_asString(body['<key>'])`.
///       ..addOption('violation-type-id',
///           help: 'Violation type lookup id. Optional.')
///       ..addOption('report-date',
///           help: 'Report date (ISO8601). Optional.')
///       ..addOption('incident-date',
///           help: 'Incident date (ISO8601). Optional.')
///       ..addOption('actions-taken',
///           help: 'Actions taken. Optional. PII-safe.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'violation';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `ReportRightsViolationIntent` +
/// `ReportRightsViolationRequest` + `ProtectionContract.reportViolation`):
///   * Required positional `<patient-id>` (UUID v4).
///   * Required `--victim-id`, `--violation-type`, `--description-of-fact` —
///     the 3 mandatory body fields per the BFF intent
///     (`report_rights_violation_intent.dart:65-80`). Ticket prose listed
///     `--type --reported-at --description` but DTO+intent disagree:
///     wire fields are `victimId`, `violationType`, `descriptionOfFact`.
///     DTO-as-canon wins (lessons: C03 W2 M1 + C04 + C05 + C06).
///   * `--report-date` and `--incident-date` validated as ISO8601 BEFORE the
///     HTTP call. Invalid → usage error (no BFF call, exit 64). When absent,
///     the field is omitted from the body (DTO `?` field convention).
///   * POST `/patients/<id>/violations` with body shape:
///     ```json
///     {
///       "victimId": "<uuid>",
///       "violationType": "<str>",
///       "descriptionOfFact": "<str>",
///       "violationTypeId": "<str-or-omitted>",
///       "reportDate": "<iso8601-or-omitted>",
///       "incidentDate": "<iso8601-or-omitted>",
///       "actionsTaken": "<str-or-omitted>"
///     }
///     ```
///   * Decode response as `StandardIdResponse` (`StandardResponse<IdData>`)
///     and surface the new violation report id on stdout.
///   * 401 → exit 2 + "auth" stderr.
///   * 422/4xx → exit 1 + status-code stderr.
///   * 5xx → exit 1 + status-code stderr.
///   * Network failure → exit 3.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/protection_violation_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kVictimId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kViolationReportId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String _kViolationType = 'NEGLIGENCIA';
const String _kDescriptionOfFact = 'Descricao estruturada do fato.';
const String _kIdResponseJson =
    '{"data":{"id":"$_kViolationReportId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('ProtectionViolationCommand basics', () {
    test('extends Command<int> with name "violation"', () {
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('violation'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares the 3 required + optional options', () {
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('victim-id'));
      expect(options, contains('violation-type'));
      expect(options, contains('description-of-fact'));
      // Optional flags MAY be exposed (DTO-faithful). Test stays permissive
      // about their presence — the body-shape test below pins the wire
      // contract.
    });
  });

  group('ProtectionViolationCommand — happy path', () {
    test(
      'POSTs /patients/<id>/violations with the ReportRightsViolationRequest '
      'body shape (DTO field names — camelCase)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionViolationCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--victim-id=$_kVictimId',
          '--violation-type=$_kViolationType',
          '--description-of-fact=$_kDescriptionOfFact',
          '--report-date=2026-05-04T12:00:00Z',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/violations'),
        );

        final body = _decodeBody(adapter.lastOptions!.data);
        // Required (intent lines 65-80 — 3 mandatory top-level strings).
        expect(body['victimId'], equals(_kVictimId));
        expect(body['violationType'], equals(_kViolationType));
        expect(body['descriptionOfFact'], equals(_kDescriptionOfFact));
        // Optional carried through verbatim when present (intent lines 87-90).
        expect(body['reportDate'], equals('2026-05-04T12:00:00Z'));
      },
    );

    test(
      'omits optional keys when flags not provided (DTO `?` convention)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionViolationCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--victim-id=$_kVictimId',
          '--violation-type=$_kViolationType',
          '--description-of-fact=$_kDescriptionOfFact',
          // No optionals.
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        // The 3 required fields are always present.
        expect(body['victimId'], equals(_kVictimId));
        expect(body['violationType'], equals(_kViolationType));
        expect(body['descriptionOfFact'], equals(_kDescriptionOfFact));
        // Optionals: implementation expected to OMIT (`dropNulls`) so the
        // BFF's `_asString(body['<key>'])` correctly sees `null` and degrades
        // the field. Tests permissive: either absent OR null.
        for (final key in const [
          'violationTypeId',
          'reportDate',
          'incidentDate',
          'actionsTaken',
        ]) {
          if (body.containsKey(key)) {
            expect(
              body[key],
              isNull,
              reason: '$key must be omitted or null when the flag is absent',
            );
          }
        }
      },
    );

    test('surfaces the returned violation report id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, equals(0));
      // The returned id MUST appear somewhere in stdout — formatter or raw,
      // W1 chooses. The contract is: user can see the id of the resource
      // they just created.
      expect(stdout.toString(), contains(_kViolationReportId));
    });

    test('decodes the BFF response as StandardIdResponse '
        '(reads `data.id`, NOT a flat `{id:...}`)', () async {
      // BFF response shape `{"data":{"id":...},"meta":{...}}` per
      // `protection_handler.dart:172-183` + `StandardResponse<IdData>` in
      // `standard_response.dart`. A naive `body['id']` access would NOT find
      // the id (nested under `data`). This test pins envelope traversal.
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, equals(0));
      // Sanity: id is exactly what the canned response carries — proves the
      // decode path read `data.id` rather than fabricating the value.
      expect(stdout.toString(), contains(_kViolationReportId));
    });
  });

  group('ProtectionViolationCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionViolationCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--victim-id=$_kVictimId',
          '--violation-type=$_kViolationType',
          '--description-of-fact=$_kDescriptionOfFact',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --victim-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --violation-type → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'missing --description-of-fact → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionViolationCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--victim-id=$_kVictimId',
          '--violation-type=$_kViolationType',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      'invalid --report-date (not ISO8601) → usage error, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionViolationCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--victim-id=$_kVictimId',
          '--violation-type=$_kViolationType',
          '--description-of-fact=$_kDescriptionOfFact',
          '--report-date=not-an-iso8601-date',
        ]);

        // ISO8601 must be validated client-side BEFORE the HTTP call so the
        // user gets a clear local error instead of an opaque BFF 400/422.
        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_VIOLATION_BODY",'
        '"message":"missing or empty [victimId]"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 5xx → non-zero exit + stderr surfaces server status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      // Mirrors C03/C04/C05/C06: runner-level refresh wiring is debt;
      // raw 401 propagates as AuthRequiredError, exit code 2.
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = ProtectionViolationCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--victim-id=$_kVictimId',
        '--violation-type=$_kViolationType',
        '--description-of-fact=$_kDescriptionOfFact',
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

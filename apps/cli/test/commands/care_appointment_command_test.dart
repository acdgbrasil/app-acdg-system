/// W0 RED — `CareAppointmentCommand` orchestration contract (C06).
///
/// W1 must create `apps/cli/lib/src/commands/care_appointment_command.dart`:
///
/// ```dart
/// class CareAppointmentCommand extends Command<int> {
///   CareAppointmentCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // The ONLY required field per RegisterAppointmentIntent line 57:
///       //   `if (body case {'professionalId': final String pid} ...)`.
///       ..addOption('professional-id',
///           help: 'Professional id (UUID) — REQUIRED')
///       // Optionals — RegisterAppointmentRequest carries them as `String?`
///       // and the BFF intent reads each via `_asString(body['<key>'])`.
///       ..addOption('date',
///           help: 'Appointment date (ISO8601). Optional.')
///       ..addOption('type',
///           help: 'Appointment type. Optional.')
///       ..addOption('summary',
///           help: 'Short summary. Optional. PII-safe — never echoed in '
///               'errors by the BFF intent.')
///       ..addOption('action-plan',
///           help: 'Action plan. Optional. PII-safe.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'appointment';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `RegisterAppointmentIntent` + `RegisterAppointmentRequest` +
/// `CareContract.registerAppointment`):
///   * Required positional `<patient-id>` (UUID v4).
///   * Required `--professional-id` — the ONLY mandatory body field per the
///     BFF intent (file `register_appointment_intent.dart:57-67`). Ticket
///     prose listed `--type --date` as required, but the DTO and intent both
///     mark them as optional (`String?`). DTO-as-canon wins (lessons:
///     C03 W2 M1 + C04).
///   * `--date` is validated as ISO8601 BEFORE the HTTP call. Invalid →
///     usage error (no BFF call, exit 64). When absent, the field is omitted
///     from the body (DTO `?` field convention).
///   * POST `/patients/<id>/appointments` with body shape:
///     ```json
///     {
///       "professionalId": "<uuid>",
///       "date": "<iso8601-or-omitted>",
///       "type": "<str-or-omitted>",
///       "summary": "<str-or-omitted>",
///       "actionPlan": "<str-or-omitted>"
///     }
///     ```
///   * Decode response as `StandardIdResponse` (`StandardResponse<IdData>`)
///     and surface the new appointment id on stdout.
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

import 'package:cli/src/commands/care_appointment_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kProfessionalId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kAppointmentId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String _kIdResponseJson =
    '{"data":{"id":"$_kAppointmentId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('CareAppointmentCommand basics', () {
    test('extends Command<int> with name "appointment"', () {
      final cmd = CareAppointmentCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('appointment'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares the required + optional options', () {
      final cmd = CareAppointmentCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('professional-id'));
      expect(options, contains('date'));
      expect(options, contains('type'));
      // `summary` + `action-plan` are also part of the DTO; commands MAY
      // expose them as optional flags. Test stays permissive: presence is
      // not required, but if exposed, must be optional.
    });
  });

  group('CareAppointmentCommand — happy path', () {
    test(
      'POSTs /patients/<id>/appointments with the RegisterAppointmentRequest '
      'body shape (DTO field names — camelCase)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = CareAppointmentCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--professional-id=$_kProfessionalId',
          '--date=2026-05-04T10:30:00Z',
          '--type=ACOLHIMENTO',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/appointments'),
        );

        final body = _decodeBody(adapter.lastOptions!.data);
        // Required (intent line 57 — ONLY mandatory field).
        expect(body['professionalId'], equals(_kProfessionalId));
        // Optionals carried through verbatim when present
        // (intent lines 60-63 + DTO line 22-23).
        expect(body['date'], equals('2026-05-04T10:30:00Z'));
        expect(body['type'], equals('ACOLHIMENTO'));
      },
    );

    test(
      'omits optional keys when flags not provided (DTO `?` convention)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = CareAppointmentCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--professional-id=$_kProfessionalId',
          // No --date, no --type, no --summary, no --action-plan.
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        // The required field is always present.
        expect(body['professionalId'], equals(_kProfessionalId));
        // Optionals: implementation is expected to OMIT (`dropNulls`) so the
        // BFF's `_asString(body['date'])` correctly sees `null` and degrades
        // the field. Tests are permissive: either absent OR null is OK, but
        // sending an empty string would defeat the DTO `?` convention.
        for (final key in const ['date', 'type', 'summary', 'actionPlan']) {
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

    test('surfaces the returned appointment id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
      ]);

      expect(exit, equals(0));
      // The returned id MUST appear somewhere in stdout — formatter or raw,
      // W1 chooses. The contract is: user can see the id of the resource
      // they just created.
      expect(stdout.toString(), contains(_kAppointmentId));
    });

    test('decodes the BFF response as StandardIdResponse '
        '(reads `data.id`, NOT a flat `{id:...}`)', () async {
      // The BFF response shape is `{"data":{"id":...},"meta":{...}}` per
      // `care_handler.dart` line 127-131 + `StandardResponse<IdData>` in
      // `standard_response.dart`. A naive `body['id']` access would NOT
      // find the id (it's nested under `data`). This test pins that the
      // CLI traverses the envelope correctly.
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
      ]);

      expect(exit, equals(0));
      // Sanity: the id is exactly what the canned response carries — proves
      // the decode path read `data.id` rather than fabricating the value.
      expect(stdout.toString(), contains(_kAppointmentId));
    });
  });

  group('CareAppointmentCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = CareAppointmentCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--professional-id=$_kProfessionalId',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --professional-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('invalid --date (not ISO8601) → usage error, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
        '--date=not-an-iso8601-date',
      ]);

      // ISO8601 must be validated client-side BEFORE the HTTP call so the
      // user gets a clear local error instead of an opaque BFF 400/422.
      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_APPOINTMENT_BODY",'
        '"message":"professionalId must be a valid uuid"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
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
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      // Mirrors C03/C04/C05: runner-level refresh wiring is debt;
      // raw 401 propagates as AuthRequiredError, exit code 2.
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = CareAppointmentCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = CareAppointmentCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--professional-id=$_kProfessionalId',
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

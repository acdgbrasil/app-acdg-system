/// W0 RED — `CareIntakeCommand` orchestration contract (C06).
///
/// W1 must create `apps/cli/lib/src/commands/care_intake_command.dart`:
///
/// ```dart
/// class CareIntakeCommand extends Command<int> {
///   CareIntakeCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // Required per UpdateIntakeInfoIntent lines 67-69:
///       //   missing.add('ingressTypeId') / missing.add('serviceReason').
///       ..addOption('ingress-type-id',
///           help: 'Ingress type lookup id — REQUIRED')
///       ..addOption('service-reason',
///           help: 'Service reason — REQUIRED. PII-safe: never echoed by '
///               'the BFF intent in error responses.')
///       // Optionals — RegisterIntakeInfoRequest carries them as `String?`
///       // (originName, originContact). `linkedSocialPrograms` is List;
///       // omitted when empty.
///       ..addOption('origin-name',
///           help: 'Origin name. Optional. PII-safe.')
///       ..addOption('origin-contact',
///           help: 'Origin contact. Optional. PII-safe.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'intake';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `UpdateIntakeInfoIntent` + `RegisterIntakeInfoRequest` +
/// `CareContract.updateIntakeInfo`):
///   * Required positional `<patient-id>` (UUID v4).
///   * Required `--ingress-type-id` and `--service-reason` — both per the
///     BFF intent (`update_intake_info_intent.dart:55-69`). Ticket prose
///     listed `--reason --intake-at` but the DTO and intent disagree:
///     the wire fields are `ingressTypeId` (lookup id) + `serviceReason`
///     (free-text). DTO-as-canon wins (lessons: C03 W2 M1 + C04 + C05).
///   * PUT `/patients/<id>/intake` with body shape:
///     ```json
///     {
///       "ingressTypeId": "<uuid-or-lookup-id>",
///       "serviceReason": "<text>",
///       "originName": "<str-or-omitted>",
///       "originContact": "<str-or-omitted>",
///       "linkedSocialPrograms": []   // optional; omitted by the CLI here
///     }
///     ```
///   * 200/204 → exit 0. (BFF returns `{data: null, meta: {...}}` on success
///     per `care_handler.dart` lines 138-145; no body parsing required by
///     the CLI for the void-returning verb.)
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

import 'package:cli/src/commands/care_intake_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kIngressTypeId = '11111111-1111-4111-8111-111111111111';
const String _kServiceReason = 'Encaminhamento via CRAS';
const String _kVoidResponseJson =
    '{"data":null,"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('CareIntakeCommand basics', () {
    test('extends Command<int> with name "intake"', () {
      final cmd = CareIntakeCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('intake'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares the required + optional options', () {
      final cmd = CareIntakeCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('ingress-type-id'));
      expect(options, contains('service-reason'));
      // origin-name + origin-contact are optional. Implementation MAY expose
      // them as flags. Test stays permissive: not required at the schema
      // level — the body-shape test below pins the wire contract.
    });
  });

  group('CareIntakeCommand — happy path', () {
    test('PUTs /patients/<id>/intake with the RegisterIntakeInfoRequest '
        'body shape (DTO field names — camelCase)', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$_kPatientId/intake'),
      );

      final body = _decodeBody(adapter.lastOptions!.data);
      // Required fields (intent lines 55-69).
      expect(body['ingressTypeId'], equals(_kIngressTypeId));
      expect(body['serviceReason'], equals(_kServiceReason));
    });

    test(
      'omits optional keys when flags not provided (DTO `?` convention)',
      () async {
        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = CareIntakeCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--ingress-type-id=$_kIngressTypeId',
          '--service-reason=$_kServiceReason',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        // Required fields always present.
        expect(body['ingressTypeId'], equals(_kIngressTypeId));
        expect(body['serviceReason'], equals(_kServiceReason));
        // Optionals omitted-or-null (intent lines 75-79 use `_asString` which
        // tolerates absent + null + non-string).
        for (final key in const ['originName', 'originContact']) {
          if (body.containsKey(key)) {
            expect(
              body[key],
              isNull,
              reason: '$key must be omitted or null when the flag is absent',
            );
          }
        }
        // `linkedSocialPrograms` defaults to `[]` per the DTO ctor; if the
        // CLI sends it, must be a List. If absent, the BFF coerces it to
        // empty per intent lines 94-99.
        if (body.containsKey('linkedSocialPrograms')) {
          expect(body['linkedSocialPrograms'], isA<List<Object?>>());
        }
      },
    );

    test('200 with envelope `{data:null}` → exit 0', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, equals(0));
      // Stay permissive on stdout content — the verb returns void on the
      // wire. Implementation MAY emit a brief confirmation. The contract
      // is "exit 0", not exact wording.
      expect(stdout.toString(), isNotNull);
    });

    test('204 No Content → exit 0', () async {
      // Defensive: even if the BFF returns 204 (rather than 200 with the
      // void envelope), the CLI must still exit 0.
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, equals(0));
    });
  });

  group('CareIntakeCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = CareIntakeCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--ingress-type-id=$_kIngressTypeId',
          '--service-reason=$_kServiceReason',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --ingress-type-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --service-reason → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_INTAKE_BODY",'
        '"message":"missing or empty [ingressTypeId]"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
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
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = CareIntakeCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = CareIntakeCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--ingress-type-id=$_kIngressTypeId',
        '--service-reason=$_kServiceReason',
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

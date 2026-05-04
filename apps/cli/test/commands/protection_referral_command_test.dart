/// W0 RED — `ProtectionReferralCommand` orchestration contract (C07).
///
/// W1 must create
/// `apps/cli/lib/src/commands/protection_referral_command.dart`:
///
/// ```dart
/// class ProtectionReferralCommand extends Command<int> {
///   ProtectionReferralCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // Required per CreateReferralIntent lines 53-71:
///       //   missing.add('referredPersonId') /
///       //   missing.add('destinationService') / missing.add('reason').
///       ..addOption('referred-person-id',
///           help: 'Referred person id (UUID) — REQUIRED. PII-adjacent.')
///       ..addOption('destination-service',
///           help: 'Destination service / institution name — REQUIRED. '
///               'PII-safe — never echoed by the BFF intent in errors.')
///       ..addOption('reason',
///           help: 'Reason for the referral — REQUIRED. Free-text '
///               'case-history narrative. PII-safe — never echoed.')
///       // Optionals — CreateReferralRequest carries them as `String?`.
///       ..addOption('professional-id',
///           help: 'Professional id (UUID). Optional.')
///       ..addOption('date',
///           help: 'Referral date (ISO8601). Optional.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'referral';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `CreateReferralIntent` + `CreateReferralRequest` +
/// `ProtectionContract.createReferral`):
///   * Required positional `<patient-id>` (UUID v4).
///   * Required `--referred-person-id`, `--destination-service`, `--reason` —
///     the 3 mandatory body fields per the BFF intent
///     (`create_referral_intent.dart:53-71`). Ticket prose listed
///     `--institution --reason --referred-at` but DTO+intent disagree:
///     wire fields are `referredPersonId`, `destinationService`, `reason`.
///     DTO-as-canon wins (lessons: C03 W2 M1 + C04 + C05 + C06).
///   * `--date` validated as ISO8601 BEFORE the HTTP call. Invalid →
///     usage error (no BFF call, exit 64). When absent, the field is
///     omitted from the body (DTO `?` field convention).
///   * POST `/patients/<id>/referrals` with body shape:
///     ```json
///     {
///       "referredPersonId": "<uuid>",
///       "destinationService": "<str>",
///       "reason": "<str>",
///       "professionalId": "<uuid-or-omitted>",
///       "date": "<iso8601-or-omitted>"
///     }
///     ```
///   * Decode response as `StandardIdResponse` (`StandardResponse<IdData>`)
///     and surface the new referral id on stdout.
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

import 'package:cli/src/commands/protection_referral_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kReferredPersonId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kReferralId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const String _kDestinationService = 'CRAS Centro';
const String _kReason = 'Encaminhamento para acompanhamento social.';
const String _kIdResponseJson =
    '{"data":{"id":"$_kReferralId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('ProtectionReferralCommand basics', () {
    test('extends Command<int> with name "referral"', () {
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('referral'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares the 3 required + optional options', () {
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('referred-person-id'));
      expect(options, contains('destination-service'));
      expect(options, contains('reason'));
      // Optional flags MAY be exposed (DTO-faithful). Test stays permissive
      // about their presence — the body-shape test below pins the wire
      // contract.
    });
  });

  group('ProtectionReferralCommand — happy path', () {
    test('POSTs /patients/<id>/referrals with the CreateReferralRequest '
        'body shape (DTO field names — camelCase)', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
        '--date=2026-05-04T12:00:00Z',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$_kPatientId/referrals'),
      );

      final body = _decodeBody(adapter.lastOptions!.data);
      // Required (intent lines 53-71 — 3 mandatory top-level strings).
      expect(body['referredPersonId'], equals(_kReferredPersonId));
      expect(body['destinationService'], equals(_kDestinationService));
      expect(body['reason'], equals(_kReason));
      // Optional carried through verbatim (intent lines 77-78).
      expect(body['date'], equals('2026-05-04T12:00:00Z'));
    });

    test(
      'omits optional keys when flags not provided (DTO `?` convention)',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionReferralCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--referred-person-id=$_kReferredPersonId',
          '--destination-service=$_kDestinationService',
          '--reason=$_kReason',
          // No optionals.
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        // The 3 required fields are always present.
        expect(body['referredPersonId'], equals(_kReferredPersonId));
        expect(body['destinationService'], equals(_kDestinationService));
        expect(body['reason'], equals(_kReason));
        // Optionals: `dropNulls` semantics — either absent OR null.
        for (final key in const ['professionalId', 'date']) {
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

    test('surfaces the returned referral id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
      ]);

      expect(exit, equals(0));
      // The returned id MUST appear somewhere in stdout — formatter or raw,
      // W1 chooses. The contract is: user can see the id of the resource
      // they just created.
      expect(stdout.toString(), contains(_kReferralId));
    });

    test('decodes the BFF response as StandardIdResponse '
        '(reads `data.id`, NOT a flat `{id:...}`)', () async {
      // BFF response shape `{"data":{"id":...},"meta":{...}}` per
      // `protection_handler.dart:172-183`. Naive `body['id']` would NOT
      // find the id (nested under `data`). This pins envelope traversal.
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
      ]);

      expect(exit, equals(0));
      expect(stdout.toString(), contains(_kReferralId));
    });
  });

  group('ProtectionReferralCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionReferralCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--referred-person-id=$_kReferredPersonId',
          '--destination-service=$_kDestinationService',
          '--reason=$_kReason',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --referred-person-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'missing --destination-service → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = ProtectionReferralCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--referred-person-id=$_kReferredPersonId',
          '--reason=$_kReason',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --reason → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('invalid --date (not ISO8601) → usage error, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
        '--date=not-an-iso8601-date',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_REFERRAL_BODY",'
        '"message":"missing or empty [reason]"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
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
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = ProtectionReferralCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--referred-person-id=$_kReferredPersonId',
        '--destination-service=$_kDestinationService',
        '--reason=$_kReason',
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

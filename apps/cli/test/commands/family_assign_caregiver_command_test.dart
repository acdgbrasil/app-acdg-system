/// W0 RED — `FamilyAssignCaregiverCommand` orchestration contract (C04).
///
/// W1 must create
/// `apps/cli/lib/src/commands/family_assign_caregiver_command.dart`:
///
/// ```dart
/// class FamilyAssignCaregiverCommand extends Command<int> {
///   FamilyAssignCaregiverCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser.addOption('member-id',
///         help: 'Family member id to mark as primary caregiver (required)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'assign-caregiver';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `AssignPrimaryCaregiverIntent` + `AssignPrimaryCaregiverRequest`):
///   * Required positional `<patient-id>`.
///   * Required `--member-id` (UI-friendly flag name; mapped to wire-format
///     `memberPersonId` per the BFF intent — see W0 REPORT §"Wire format").
///   * PUT `/patients/<id>/primary-caregiver` body shape:
///     ```json
///     {"memberPersonId": "<uuid>"}
///     ```
///   * 204 No Content → exit 0.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_assign_caregiver_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kMemberId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  group('FamilyAssignCaregiverCommand basics', () {
    test('extends Command<int> with name "assign-caregiver"', () {
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('assign-caregiver'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --member-id option', () {
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('member-id'));
    });
  });

  group('FamilyAssignCaregiverCommand — happy path', () {
    test(
      'PUTs /patients/<id>/primary-caregiver with {"memberPersonId": ...} body',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyAssignCaregiverCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--member-id=$_kMemberId',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/primary-caregiver'),
        );

        final body = _decodeBody(adapter.lastOptions!.data);
        // Wire format: BFF reads `body['memberPersonId']` per
        // assign_primary_caregiver_intent.dart line 39.
        expect(body['memberPersonId'], equals(_kMemberId));
      },
    );
  });

  group('FamilyAssignCaregiverCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyAssignCaregiverCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const ['--member-id=$_kMemberId']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --member-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_PRIMARY_CAREGIVER_BODY",'
        '"message":"member not found"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--member-id=$_kMemberId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--member-id=$_kMemberId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = FamilyAssignCaregiverCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--member-id=$_kMemberId',
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

/// W0 RED — `TeamRoleAssignCommand` orchestration contract (C09).
///
/// W1 must create `apps/cli/lib/src/commands/team_role_assign_command.dart`:
///
/// ```dart
/// class TeamRoleAssignCommand extends Command<int> {
///   TeamRoleAssignCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // 2 required fields per AssignRoleRequest DTO:
///       ..addOption('system',
///           help: 'Target system, e.g. "social_care" / "analytics_bi" '
///                 '(required)')
///       ..addOption('role-id',
///           help: 'Role identifier within the system, e.g. "social_worker" '
///                 '(required)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'assign';
///   @override Future<int> run();
/// }
/// ```
///
/// **Naming decision (deviation from ticket prose).** Ticket prose shows
/// `acdg team role assign <member-id> --role-id --system=Y` but reading
/// the BFF DTO `AssignRoleRequest`
/// (`apps/social_care_bff/contracts/lib/src/contract/dto/requests/people/`
/// `assign_role_request.dart:8`) shows the body fields are:
///   * `system: String` (required)
///   * `role: String`   (required)
///
/// The DTO does NOT have `roleId` — only `role`. The ticket's `--role-id`
/// is CLI-friendly sugar that maps to wire field `role`. We pin the wire
/// body MUST carry `role` (not `roleId`) per C03 W2 M1 + C08 D2 precedent
/// (DTO-as-canon).
///
/// Behavior (per `AssignRoleIntent.parseFromBody` +
/// `TeamContract.assignRole`):
///   * Required positional `<member-id>` (UUID v4 — BFF intent gates).
///   * Required `--system`.
///   * Required `--role-id` (CLI-flag) → wire field `role`.
///   * POST `/team/<member-id>/roles` with body shape:
///     ```json
///     {"system": "<system>", "role": "<role-id>"}
///     ```
///   * Decode response as `StandardIdResponse` — surface the new role
///     assignment id on stdout (uses shared `decodeStandardIdResponse`).
///   * 400 INVALID_ASSIGN_ROLE_BODY (missing `system`/`role`) /
///     400 UUID failure / 401 / 5xx → non-zero exit + status code in
///     stderr.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_role_assign_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kMemberId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kAssignmentId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kIdResponseJson =
    '{"data":{"id":"$_kAssignmentId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('TeamRoleAssignCommand basics', () {
    test('extends Command<int> with name "assign"', () {
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('assign'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --system and --role-id options', () {
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('system'));
      expect(options, contains('role-id'));
    });
  });

  group('TeamRoleAssignCommand — happy path', () {
    test('POSTs /team/<member-id>/roles with the AssignRoleRequest body shape '
        '(DTO field names — system/role, NOT system/role-id)', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
        '--role-id=social_worker',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(adapter.lastOptions!.path, equals('/team/$_kMemberId/roles'));

      final body = _decodeBody(adapter.lastOptions!.data);
      // DTO-as-canon: wire fields are `system` and `role` per
      // `AssignRoleRequest` (cross-cited above).
      expect(body['system'], equals('social_care'));
      expect(body['role'], equals('social_worker'));
      // CLI-friendly kebab name MUST NOT leak onto the wire.
      expect(body.containsKey('role-id'), isFalse);
      expect(body.containsKey('roleId'), isFalse);
    });

    test(
      'surfaces the returned assignment id on stdout (StandardIdResponse)',
      () async {
        // BFF wire shape `{"data":{"id":...},"meta":{...}}` per
        // `team_handler.dart:_respondWithId` (line 247-249 / 323-334).
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final stdout = StringBuffer();
        final cmd = TeamRoleAssignCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: stdout,
        );

        final exit = await _runWithArgs(cmd, const [
          _kMemberId,
          '--system=social_care',
          '--role-id=social_worker',
        ]);

        expect(exit, equals(0));
        // The user MUST be able to see the new role-assignment id.
        expect(stdout.toString(), contains(_kAssignmentId));
      },
    );
  });

  group('TeamRoleAssignCommand — failure paths', () {
    test('missing positional member-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--system=social_care',
        '--role-id=social_worker',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --system → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--role-id=social_worker',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --role-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 400 INVALID_ASSIGN_ROLE_BODY → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_ASSIGN_ROLE_BODY",'
        '"message":"missing or empty [role]"}}',
        status: 400,
      );
      final stderr = StringBuffer();
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
        '--role-id=social_worker',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('400'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
        '--role-id=social_worker',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + stderr surfaces status', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
        '--role-id=social_worker',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = TeamRoleAssignCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kMemberId,
        '--system=social_care',
        '--role-id=social_worker',
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

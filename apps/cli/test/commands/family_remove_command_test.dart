/// W0 RED — `FamilyRemoveCommand` orchestration contract (C04).
///
/// W1 must create `apps/cli/lib/src/commands/family_remove_command.dart`:
///
/// ```dart
/// class FamilyRemoveCommand extends Command<int> {
///   FamilyRemoveCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser.addOption('member-id',
///         help: 'Family member id (UUID v4, required)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'remove';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `RemoveFamilyMemberIntent`):
///   * Required positional `<patient-id>`.
///   * Required `--member-id`.
///   * DELETE `/patients/<id>/family-members/<memberId>` — **NO BODY**.
///   * Successful 204 No Content → exit 0.
///   * 404 → non-zero exit, stderr surfaces "not found"-style message.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_remove_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kMemberId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  group('FamilyRemoveCommand basics', () {
    test('extends Command<int> with name "remove"', () {
      final cmd = FamilyRemoveCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('remove'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --member-id option', () {
      final cmd = FamilyRemoveCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('member-id'));
    });
  });

  group('FamilyRemoveCommand — happy path', () {
    test(
      'DELETEs /patients/<id>/family-members/<memberId> with no body',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyRemoveCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--member-id=$_kMemberId',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('DELETE'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/family-members/$_kMemberId'),
        );
        // NO body on a DELETE — Dio passes either null or an empty value.
        final raw = adapter.lastOptions!.data;
        expect(
          raw,
          anyOf(isNull, equals(''), equals(<String, Object?>{}), isEmpty),
        );
      },
    );

    test('204 No Content → exit 0 with brief stdout confirmation', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final stdout = StringBuffer();
      final cmd = FamilyRemoveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--member-id=$_kMemberId',
      ]);

      expect(exit, equals(0));
      // The command MAY print a short "removed" confirmation. Stay
      // permissive — the contract is "exit 0", not the exact wording.
      // Implementation should write *something* on stdout for human UX.
      expect(stdout.toString(), isNotNull);
    });
  });

  group('FamilyRemoveCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyRemoveCommand(
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
      final cmd = FamilyRemoveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 404 → non-zero exit + stderr surfaces 404', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"NOT_FOUND","message":"Family member not found"}}',
        status: 404,
      );
      final stderr = StringBuffer();
      final cmd = FamilyRemoveCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--member-id=$_kMemberId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('404'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = FamilyRemoveCommand(
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

    test('Network failure → non-zero exit + stderr', () async {
      final cmd = FamilyRemoveCommand(
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

Future<int> _runWithArgs(Command<int> cmd, List<String> args) async {
  final runner = CommandRunner<int>('test', 'test')..addCommand(cmd);
  try {
    final code = await runner.run([cmd.name, ...args]);
    return code ?? 0;
  } on UsageException {
    return 64;
  }
}

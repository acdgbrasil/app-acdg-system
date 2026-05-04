/// W0 RED — `FamilyUpdateIdentityCommand` orchestration contract (C04).
///
/// W1 must create
/// `apps/cli/lib/src/commands/family_update_identity_command.dart`:
///
/// ```dart
/// class FamilyUpdateIdentityCommand extends Command<int> {
///   FamilyUpdateIdentityCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('type-id',
///           help: 'Social identity type id (UUID v4, required)')
///       ..addOption('description', help: 'Optional free-form description');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'update-identity';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `UpdateSocialIdentityIntent` + `UpdateSocialIdentityRequest`):
///   * Required positional `<patient-id>`.
///   * Required `--type-id` (BFF intent line 40 demands `typeId`/non-empty).
///   * Optional `--description` (free-form text). Omitted from body when absent.
///   * PUT `/patients/<id>/social-identity` body shape:
///     ```json
///     {"typeId": "<uuid>", "description"?: "..."}
///     ```
///   * 204 No Content → exit 0.
///
/// **Divergence from C04 ticket prose:** the ticket says
/// `--gender=X --pronoun=Y` but the canonical DTO is `{typeId, description?}`.
/// Following the C03 `DTO-as-canon` decision (W0 §"Decisions taken"), the
/// CLI exposes `--type-id` + `--description`. See REPORT.md §"Decisions".
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_update_identity_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kTypeId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

void main() {
  group('FamilyUpdateIdentityCommand basics', () {
    test('extends Command<int> with name "update-identity"', () {
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('update-identity'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --type-id and --description options', () {
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('type-id'));
      expect(options, contains('description'));
    });
  });

  group('FamilyUpdateIdentityCommand — happy path', () {
    test(
      'PUTs /patients/<id>/social-identity with {typeId, description} body',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyUpdateIdentityCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--type-id=$_kTypeId',
          '--description=Self-identifies as non-binary',
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/social-identity'),
        );

        final body = _decodeBody(adapter.lastOptions!.data);
        expect(body['typeId'], equals(_kTypeId));
        expect(body['description'], equals('Self-identifies as non-binary'));
      },
    );

    test(
      'omits "description" key when --description flag not provided',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyUpdateIdentityCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--type-id=$_kTypeId',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        expect(body['typeId'], equals(_kTypeId));
        // BFF intent line 60 (`_asNullableString`) collapses empty/missing
        // to null on the request DTO. The CLI MUST NOT send a literal
        // "description": null — DTO conventions are "omit the key" rather
        // than "send null". Same dropNulls pattern as C03 _patient_helpers.
        expect(body.containsKey('description'), isFalse);
      },
    );
  });

  group('FamilyUpdateIdentityCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyUpdateIdentityCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const ['--type-id=$_kTypeId']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --type-id → non-zero exit, no BFF call', () async {
      // BFF intent line 40 requires non-empty typeId; CLI must fail fast.
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--description=anything',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'no fields set at all (only patient-id) → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyUpdateIdentityCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [_kPatientId]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 422 → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_SOCIAL_IDENTITY_BODY",'
        '"message":"typeId not in lookup"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--type-id=$_kTypeId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--type-id=$_kTypeId',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = FamilyUpdateIdentityCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--type-id=$_kTypeId',
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

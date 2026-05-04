/// W0 RED — `TeamRegisterCommand` orchestration contract (C09).
///
/// W1 must create `apps/cli/lib/src/commands/team_register_command.dart`:
///
/// ```dart
/// class TeamRegisterCommand extends Command<int> {
///   TeamRegisterCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // 3 required fields per RegisterPersonWithLoginRequest DTO.
///       ..addOption('full-name',
///           help: 'Full name (required)')
///       ..addOption('birth-date',
///           help: 'Birth date YYYY-MM-DD (required)')
///       ..addOption('email',
///           help: 'Email (required)')
///       // 2 optional fields per the DTO.
///       ..addOption('cpf',
///           help: 'CPF (optional)')
///       ..addOption('initial-password',
///           help: 'Initial password (optional)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'register';
///   @override Future<int> run();
/// }
/// ```
///
/// **Naming decision (deviation from ticket prose).** The ticket prose
/// shows `acdg team register --cpf=X --first-name=Y --role=Z` but the BFF
/// DTO `RegisterPersonWithLoginRequest`
/// (`apps/social_care_bff/contracts/lib/src/contract/dto/requests/people/`
/// `register_person_with_login_request.dart:8-14`) is:
///   * `fullName: String`     (required)
///   * `birthDate: String`    (required)
///   * `email: String`        (required)
///   * `cpf: String?`         (optional)
///   * `initialPassword: String?` (optional)
///
/// There is NO `firstName` and NO `role` field on this DTO. Initial role
/// assignment happens internally inside the BFF saga (cf.
/// `register_worker_use_case.dart` orchestration: PeopleContext.register
/// + Team.createWorker + Team.assignRole), but on the WIRE the only POST
/// body is the 3 required + 2 optional `RegisterPersonWithLoginRequest`
/// fields. The ticket prose flags are CLI-sugar only and do NOT reach the
/// BFF.
///
/// We follow C03 W2 M1 / C08 D2 precedent: **DTO-as-canon — the wire body
/// MUST carry the DTO field names**. CLI flags map to DTO names:
///   * `--full-name` → `fullName`
///   * `--birth-date` → `birthDate`
///   * `--email` → `email` (verbatim)
///   * `--cpf` → `cpf` (verbatim, optional)
///   * `--initial-password` → `initialPassword` (optional)
///
/// `--first-name` and `--role` from the ticket prose are NOT supported at
/// this layer. If the user wants an initial role, they call
/// `acdg team register` then `acdg team role assign <new-id>` — two
/// commands, two saga boundaries. (Open question for W1: whether to add
/// `--initial-role` as a CLI-sugar flag that fires a follow-up
/// `assignRole` POST. RED tests do NOT require this — the W1 implementer
/// can decide.)
///
/// Behavior (per `RegisterWorkerIntent.parseFromBody` +
/// `TeamContract.registerWorker`):
///   * Required: `--full-name`, `--birth-date`, `--email`. Missing any →
///     usage error 64, no BFF call.
///   * Optional: `--cpf`, `--initial-password`. When absent, MUST be
///     omitted from the JSON body (DTO convention `String?` ≡ omit-key).
///   * POST `/team` with body shape `{fullName, birthDate, email, cpf?,
///     initialPassword?}`.
///   * Decode response as `StandardIdResponse`
///     (`{"data": {"id": "<uuid>"}, "meta": {...}}`) — the new worker's
///     id surfaces on stdout (uses shared `decodeStandardIdResponse`).
///   * 5xx — saga edge case (PeopleContext rollback failed, etc). The CLI
///     does NOT enforce saga rollback (BFF responsibility per
///     `register_worker_use_case.dart`); it only surfaces a clear stderr
///     message with the 500 status so the operator can investigate.
///   * 400 INVALID_REGISTER_WORKER_BODY / 401 / generic 4xx → non-zero
///     exit + status code in stderr.
///   * Network failure → exit 3 + network message.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/team_register_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kNewWorkerId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kIdResponseJson =
    '{"data":{"id":"$_kNewWorkerId"},'
    '"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('TeamRegisterCommand basics', () {
    test('extends Command<int> with name "register"', () {
      final cmd = TeamRegisterCommand(
        bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('register'));
      expect(cmd.description, isNotEmpty);
    });

    test(
      'argParser declares the 3 required + 2 optional DTO-aligned options',
      () {
        final cmd = TeamRegisterCommand(
          bffClient: _bff(_CapturingAdapter(_kIdResponseJson, status: 200)),
          formatter: const JsonFormatter(),
        );
        final options = cmd.argParser.options.keys.toSet();
        expect(options, contains('full-name'));
        expect(options, contains('birth-date'));
        expect(options, contains('email'));
        expect(options, contains('cpf'));
        expect(options, contains('initial-password'));
      },
    );
  });

  group('TeamRegisterCommand — happy path', () {
    test('POSTs /team with the RegisterPersonWithLoginRequest body shape '
        '(DTO field names — fullName/birthDate/email)', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(adapter.lastOptions!.path, equals('/team'));

      final body = _decodeBody(adapter.lastOptions!.data);
      // DTO-as-canon: wire fields are camelCase per
      // `RegisterPersonWithLoginRequest` (cross-cited above).
      expect(body['fullName'], equals('Ana Souza'));
      expect(body['birthDate'], equals('1985-04-12'));
      expect(body['email'], equals('ana@example.org'));
      // CLI-friendly kebab names MUST NOT leak onto the wire.
      expect(body.containsKey('full-name'), isFalse);
      expect(body.containsKey('birth-date'), isFalse);
    });

    test('omits cpf/initialPassword when not provided (DTO ?-field)', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);
      // BFF intent `register_worker_intent.dart:61-62` only forwards
      // `cpf`/`initialPassword` when the body carries them as String.
      // Frontend convention `dropNulls`: omit absent optionals.
      expect(body.containsKey('cpf'), isFalse);
      expect(body.containsKey('initialPassword'), isFalse);
    });

    test('forwards --cpf and --initial-password when provided', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
        '--cpf=12345678900',
        '--initial-password=Temp@2026',
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['cpf'], equals('12345678900'));
      // DTO field is `initialPassword` — the kebab `--initial-password`
      // flag MUST be translated.
      expect(body['initialPassword'], equals('Temp@2026'));
      // The kebab form MUST NOT leak.
      expect(body.containsKey('initial-password'), isFalse);
    });

    test(
      'surfaces the returned worker id on stdout (StandardIdResponse decode)',
      () async {
        // BFF wire shape `{"data":{"id":...},"meta":{...}}` per
        // `team_handler.dart:_respondWithId` (lines 323-334). A naive
        // `body['id']` access would fail. Pins envelope traversal via
        // the shared `decodeStandardIdResponse` helper.
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final stdout = StringBuffer();
        final cmd = TeamRegisterCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: stdout,
        );

        final exit = await _runWithArgs(cmd, const [
          '--full-name=Ana Souza',
          '--birth-date=1985-04-12',
          '--email=ana@example.org',
        ]);

        expect(exit, equals(0));
        // The user MUST be able to see the new worker id they just
        // registered — formatter or raw is W1's choice.
        expect(stdout.toString(), contains(_kNewWorkerId));
      },
    );
  });

  group('TeamRegisterCommand — failure paths', () {
    test('missing --full-name → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --birth-date → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--email=ana@example.org',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --email → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'BFF 400 INVALID_REGISTER_WORKER_BODY → non-zero exit + stderr',
      () async {
        final adapter = _CapturingAdapter(
          '{"error":{"code":"INVALID_REGISTER_WORKER_BODY",'
          '"message":"missing or empty [email]"}}',
          status: 400,
        );
        final stderr = StringBuffer();
        final cmd = TeamRegisterCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: stderr,
        );

        final exit = await _runWithArgs(cmd, const [
          '--full-name=Ana Souza',
          '--birth-date=1985-04-12',
          '--email=ana@example.org',
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('400'));
      },
    );

    test('BFF 5xx (saga edge case — PeopleContext rollback) → non-zero exit '
        '+ stderr surfaces server status', () async {
      // The CLI does NOT enforce saga rollback (BFF responsibility per
      // `register_worker_use_case.dart`). It only surfaces a clear error
      // so the operator can investigate. Test asserts user sees the 500.
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = TeamRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = TeamRegisterCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--full-name=Ana Souza',
        '--birth-date=1985-04-12',
        '--email=ana@example.org',
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

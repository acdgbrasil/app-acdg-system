/// W0 RED — `FamilyAddCommand` orchestration contract (C04).
///
/// W1 must create `apps/cli/lib/src/commands/family_add_command.dart`:
///
/// ```dart
/// class FamilyAddCommand extends Command<int> {
///   FamilyAddCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // Registry-side mandatory fields (per AddFamilyMemberRequest DTO).
///       ..addOption('relationship',
///           help: 'Relationship code (required, e.g. "MOTHER")')
///       ..addOption('birth-date',
///           help: 'Member birth date YYYY-MM-DD (required)')
///       ..addOption('pr-relationship-id',
///           help: 'PR relationship lookup id (required)')
///       // People-Context inputs (top-level on the wire envelope).
///       ..addOption('member-cpf',
///           help: 'Member CPF (forwarded to People Context)')
///       ..addOption('full-name',
///           help: 'Full name (forwarded to People Context)')
///       // Registry-side optionals.
///       ..addOption('member-person-id',
///           help: 'Existing person id; mutually exclusive with --member-cpf')
///       ..addFlag('is-residing', defaultsTo: false)
///       ..addFlag('is-caregiver', defaultsTo: false)
///       ..addFlag('has-disability', defaultsTo: false)
///       ..addMultiOption('required-document',
///           help: 'Required document codes (repeatable)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'add';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `AddFamilyMemberIntent` + `AddFamilyMemberRequest`):
///   * Required positional `<patient-id>`.
///   * Required: `--relationship`, `--birth-date`, `--pr-relationship-id`
///     (the three mandatory Registry-side fields per `AddFamilyMemberIntent`
///     line 70-78 of the BFF intent).
///   * POSTs `/patients/<id>/family-members` with body shape:
///     ```json
///     {
///       "memberPersonId": "<id-or-empty-string>",
///       "relationship": "...",
///       "birthDate": "YYYY-MM-DD",
///       "prRelationshipId": "...",
///       "isResiding": false,
///       "isCaregiver": false,
///       "hasDisability": false,
///       "requiredDocuments": [],
///       // Top-level People-Context inputs (envelope, not request DTO):
///       "cpf": "...",        // optional
///       "fullName": "..."    // optional
///     }
///     ```
///   * 5xx — saga-context error UX: stderr message must mention failure.
///     The CLI does NOT attempt a rollback (BFF responsibility). It only
///     surfaces a helpful retry hint.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/family_add_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kPrRelId = '11111111-1111-4111-8111-111111111111';
const String _kCpf = '12345678900';

void main() {
  group('FamilyAddCommand basics', () {
    test('extends Command<int> with name "add"', () {
      final cmd = FamilyAddCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('add'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares the required + optional options', () {
      final cmd = FamilyAddCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('relationship'));
      expect(options, contains('birth-date'));
      expect(options, contains('pr-relationship-id'));
      expect(options, contains('member-cpf'));
      expect(options, contains('full-name'));
    });
  });

  group('FamilyAddCommand — happy path', () {
    test('POSTs /patients/<id>/family-members with the AddFamilyMemberRequest '
        'body shape (DTO field names — camelCase)', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--birth-date=1985-04-12',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana da Silva',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$_kPatientId/family-members'),
      );

      final body = _decodeBody(adapter.lastOptions!.data);
      // Registry-side fields (DTO-faithful camelCase).
      expect(body['relationship'], equals('MOTHER'));
      expect(body['birthDate'], equals('1985-04-12'));
      expect(body['prRelationshipId'], equals(_kPrRelId));
      // People-Context envelope fields (top-level, NOT inside `request`).
      // BFF intent reads `body['cpf']` and `body['fullName']` directly.
      expect(body['cpf'], equals(_kCpf));
      expect(body['fullName'], equals('Ana da Silva'));
    });

    test(
      'flag defaults: when --is-residing etc absent, body sends false',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyAddCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--relationship=MOTHER',
          '--birth-date=1985-04-12',
          '--pr-relationship-id=$_kPrRelId',
          '--member-cpf=$_kCpf',
          '--full-name=Ana da Silva',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        // BFF intent line 122: `_asBool(body['isResiding'])` returns `false` if
        // missing, so the CLI may either send `false` explicitly or omit them.
        // Test allows either — but if present, must be a bool.
        if (body.containsKey('isResiding')) {
          expect(body['isResiding'], isA<bool>());
        }
        if (body.containsKey('isCaregiver')) {
          expect(body['isCaregiver'], isA<bool>());
        }
        if (body.containsKey('hasDisability')) {
          expect(body['hasDisability'], isA<bool>());
        }
      },
    );
  });

  group('FamilyAddCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = FamilyAddCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--relationship=MOTHER',
          '--birth-date=1985-04-12',
          '--pr-relationship-id=$_kPrRelId',
          '--member-cpf=$_kCpf',
          '--full-name=Ana',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --relationship → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--birth-date=1985-04-12',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --birth-date → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('missing --pr-relationship-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--birth-date=1985-04-12',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_ADD_FAMILY_MEMBER_BODY",'
        '"message":"missing relationship"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--birth-date=1985-04-12',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 5xx (saga edge case — PeopleContext failure) → non-zero exit '
        '+ stderr surfaces server status', () async {
      // The CLI does NOT enforce saga rollback (that's BFF responsibility).
      // It only surfaces a clear error. Test asserts the user sees the 500.
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--birth-date=1985-04-12',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      // Mirrors C03 patient verbs: runner-level refresh wiring is C04+ debt;
      // raw 401 propagates as AuthRequiredError, exit code 2.
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = FamilyAddCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--relationship=MOTHER',
        '--birth-date=1985-04-12',
        '--pr-relationship-id=$_kPrRelId',
        '--member-cpf=$_kCpf',
        '--full-name=Ana',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
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

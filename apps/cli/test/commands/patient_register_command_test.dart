/// W0 RED — `PatientRegisterCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_register_command.dart`:
///
/// ```dart
/// class PatientRegisterCommand extends Command<int> {
///   PatientRegisterCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,   // String path -> Future<String> contents
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('from-yaml',
///           help: 'Path to a YAML payload (composite B1).')
///       // Flag-based simple-case shortcuts:
///       ..addOption('person-id', help: 'Existing person id (required if no from-yaml)')
///       ..addOption('pr-relationship-id', help: 'Primary responsible relationship id')
///       ..addOption('first-name')
///       ..addOption('last-name')
///       ..addOption('mother-name')
///       ..addOption('nationality')
///       ..addOption('sex')
///       ..addOption('birth-date')
///       ..addOption('cpf')
///       ..addOption('cns')
///       ..addOption('nis')
///       ..addOption('icd-code',
///           help: 'Initial ICD code; one allowed via this flag.')
///       ..addOption('diagnosis-date')
///       ..addOption('diagnosis-description');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final Future<String> Function(String path) fileReader;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'register';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (ticket §Detalhes — register == B1 composite endpoint):
///   * `--from-yaml=path`: read file, parse YAML, deserialize into the JSON
///     shape of `RegisterPatientRequest`, POST `/patients`.
///   * No `--from-yaml`: build a `RegisterPatientRequest` from the simple
///     flag set (--person-id + --pr-relationship-id + --icd-code +
///     --diagnosis-date + --diagnosis-description + optional personalData
///     fields + optional civilDocuments fields).
///   * Mutually exclusive: passing both flag set + `--from-yaml` → usage error.
///   * POST `/patients` with the request body.
///   * Decode response as `StandardIdResponse` (`StandardResponse<IdData>`);
///     surface the new id on stdout.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_register_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPersonId = '11111111-1111-4111-8111-111111111111';
const String _kPrRelId = '22222222-2222-4222-8222-222222222222';
const String _kNewPatientId = '33333333-3333-4333-8333-333333333333';
const String _kIdResponseJson =
    '{"data":{"id":"$_kNewPatientId"},"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

void main() {
  group('PatientRegisterCommand basics', () {
    test('extends Command<int> with name "register"', () {
      final cmd = PatientRegisterCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('register'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares both flag-based + --from-yaml options', () {
      final cmd = PatientRegisterCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('from-yaml'));
      expect(options, contains('person-id'));
      expect(options, contains('pr-relationship-id'));
      expect(options, contains('first-name'));
      expect(options, contains('cpf'));
      expect(options, contains('icd-code'));
    });
  });

  group('PatientRegisterCommand — flag-based happy path', () {
    test(
      'POSTs /patients with the assembled RegisterPatientRequest body',
      () async {
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = PatientRegisterCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: _failingReader,
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--person-id=$_kPersonId',
          '--pr-relationship-id=$_kPrRelId',
          '--icd-code=Q90',
          '--diagnosis-date=2026-04-30',
          '--diagnosis-description=Síndrome de Down',
          '--first-name=Maria',
          '--last-name=Silva',
          '--mother-name=Ana Silva',
          '--nationality=BR',
          '--sex=female',
          '--birth-date=2010-04-12',
        ]);

        expect(exit, equals(0));
        final captured = adapter.lastOptions!;
        expect(captured.method.toUpperCase(), equals('POST'));
        expect(captured.path, equals('/patients'));

        final body = _decodeBody(captured.data);
        expect(body['personId'], equals(_kPersonId));
        expect(body['prRelationshipId'], equals(_kPrRelId));
        expect(body['initialDiagnoses'], isA<List<Object?>>());
        final diagnoses = body['initialDiagnoses']! as List<Object?>;
        expect(diagnoses, hasLength(1));
        final d0 = diagnoses.first! as Map<String, Object?>;
        expect(d0['icdCode'], equals('Q90'));
        expect(d0['date'], equals('2026-04-30'));
        expect(d0['description'], equals('Síndrome de Down'));

        expect(body['personalData'], isA<Map<String, Object?>>());
        final personal = body['personalData']! as Map<String, Object?>;
        expect(personal['firstName'], equals('Maria'));
        expect(personal['lastName'], equals('Silva'));
        expect(personal['sex'], equals('female'));
      },
    );

    test('surfaces the returned id on stdout', () async {
      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final stdout = StringBuffer();
      final cmd = PatientRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
        stdout: stdout,
      );

      final exit = await _runWithArgs(cmd, const [
        '--person-id=$_kPersonId',
        '--pr-relationship-id=$_kPrRelId',
        '--icd-code=Q90',
        '--diagnosis-date=2026-04-30',
        '--diagnosis-description=Síndrome de Down',
      ]);

      expect(exit, equals(0));
      expect(stdout.toString(), contains(_kNewPatientId));
    });
  });

  group('PatientRegisterCommand — --from-yaml happy path', () {
    test('reads file, parses YAML, POSTs /patients with payload', () async {
      const yamlBody =
          '''
personId: $_kPersonId
prRelationshipId: $_kPrRelId
initialDiagnoses:
  - icdCode: Q90
    date: "2026-04-30"
    description: "Trissomia do 21"
personalData:
  firstName: Maria
  lastName: Silva
  motherName: Ana Silva
  nationality: BR
  sex: female
  birthDate: "2010-04-12"
''';
      String? lastReadPath;
      Future<String> reader(String path) async {
        lastReadPath = path;
        return yamlBody;
      }

      final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
      final cmd = PatientRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
      );

      final exit = await _runWithArgs(cmd, const [
        '--from-yaml=/tmp/payload.yaml',
      ]);

      expect(exit, equals(0));
      expect(lastReadPath, equals('/tmp/payload.yaml'));
      expect(adapter.lastOptions!.path, equals('/patients'));
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['personId'], equals(_kPersonId));
      expect(body['initialDiagnoses'], isA<List<Object?>>());
    });
  });

  group('PatientRegisterCommand — failure paths', () {
    test('missing required flags AND no --from-yaml → usage error', () async {
      final cmd = PatientRegisterCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
    });

    test(
      'flag set + --from-yaml together → usage error (mutually exclusive)',
      () async {
        Future<String> reader(String _) async => 'personId: $_kPersonId\n';
        final adapter = _CapturingAdapter(_kIdResponseJson, status: 200);
        final cmd = PatientRegisterCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: reader,
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--from-yaml=/tmp/payload.yaml',
          '--person-id=$_kPersonId',
          '--pr-relationship-id=$_kPrRelId',
          '--icd-code=Q90',
          '--diagnosis-date=2026-04-30',
          '--diagnosis-description=x',
        ]);

        expect(exit, isNot(equals(0)));
        // BFF must NOT have been called when input is contradictory.
        expect(adapter.lastOptions, isNull);
      },
    );

    test('--from-yaml pointing to unreadable file → non-zero exit', () async {
      Future<String> reader(String _) async =>
          throw const _NoSuchFileException('no such file');
      final cmd = PatientRegisterCommand(
        bffClient: _bff(_CapturingAdapter('{}', status: 200)),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        '--from-yaml=/does/not/exist.yaml',
      ]);

      expect(exit, isNot(equals(0)));
    });

    test('BFF 422 → non-zero exit + stderr msg', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID","message":"CPF invalid"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = PatientRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        '--person-id=$_kPersonId',
        '--pr-relationship-id=$_kPrRelId',
        '--icd-code=Q90',
        '--diagnosis-date=2026-04-30',
        '--diagnosis-description=x',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = PatientRegisterCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        '--person-id=$_kPersonId',
        '--pr-relationship-id=$_kPrRelId',
        '--icd-code=Q90',
        '--diagnosis-date=2026-04-30',
        '--diagnosis-description=x',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures + fakes
// ---------------------------------------------------------------------------

Future<String> _failingReader(String path) async =>
    throw StateError('fileReader should not be called: $path');

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

/// Standalone "no such file" exception (no `dart:io` import — keeps the
/// test suite pure). Production paths use `dart:io`'s real
/// `FileSystemException`; the command must propagate any `Exception`
/// from the injected reader as a non-zero exit.
class _NoSuchFileException implements Exception {
  const _NoSuchFileException(this.message);
  final String message;
  @override
  String toString() => 'NoSuchFileException: $message';
}

/// Decodes the Dio request body into a Map regardless of whether Dio
/// passed the raw `Map` through or already serialized it to a JSON string.
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

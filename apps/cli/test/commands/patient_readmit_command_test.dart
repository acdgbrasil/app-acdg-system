/// W0 RED — `PatientReadmitCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_readmit_command.dart`:
///
/// ```dart
/// class PatientReadmitCommand extends Command<int> {
///   PatientReadmitCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser.addOption('notes', help: 'Optional notes');
///   }
///   @override String get name => 'readmit';
///   @override Future<int> run();
/// }
/// ```
///
/// IMPORTANT — contract divergence with the C03 ticket prose:
///   The ticket allows `--reason`, but the actual `ReadmitPatientRequest`
///   DTO accepts ONLY `{notes?}`. The CLI mirrors the DTO. (Flagged in
///   REPORT — W1 may either drop `--reason` from the parser entirely or
///   keep it as a deprecated no-op flag.)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_readmit_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('PatientReadmitCommand basics', () {
    test('extends Command<int> with name "readmit"', () {
      final cmd = PatientReadmitCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('readmit'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares notes option', () {
      final cmd = PatientReadmitCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd.argParser.options.keys, contains('notes'));
    });
  });

  group('PatientReadmitCommand — happy path', () {
    test('POSTs /patients/<id>/readmit with notes when provided', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = PatientReadmitCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--notes=After hospital discharge',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('POST'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$_kPatientId/readmit'),
      );
      final body = _decodeBody(adapter.lastOptions!.data);
      expect(body['notes'], equals('After hospital discharge'));
    });

    test(
      'POSTs /patients/<id>/readmit with empty body when no flags',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = PatientReadmitCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [_kPatientId]);

        expect(exit, equals(0));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/readmit'),
        );
        final body = _decodeBody(adapter.lastOptions!.data);
        // Either the map is empty, or `notes` is explicitly null —
        // both encode "no notes provided".
        expect(body.containsKey('notes') ? body['notes'] : null, isNull);
      },
    );
  });

  group('PatientReadmitCommand — failure paths', () {
    test('missing positional patient-id → non-zero exit', () async {
      final cmd = PatientReadmitCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
    });

    test('BFF 409 → non-zero exit', () async {
      final adapter = _CapturingAdapter(
        '{"error":{"code":"CONFLICT","message":"Patient not in dischargeable state"}}',
        status: 409,
      );
      final stderr = StringBuffer();
      final cmd = PatientReadmitCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('409'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = PatientReadmitCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

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
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded as Map<String, Object?>;
  }
  if (raw == null) return const {};
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

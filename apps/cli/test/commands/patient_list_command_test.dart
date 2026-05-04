/// W0 RED — `PatientListCommand` orchestration contract (C03).
///
/// W1 must create `apps/cli/lib/src/commands/patient_list_command.dart`:
///
/// ```dart
/// class PatientListCommand extends Command<int> {
///   PatientListCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('search', help: 'Search by name / CPF / patientId')
///       ..addOption('status', help: 'Filter by lifecycle status')
///       ..addOption('cursor', help: 'Pagination cursor (opaque)')
///       ..addOption('limit', help: 'Max items per page');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'list';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (ticket §Escopo / §Detalhes):
/// 1. Parse args → query params on the GET request.
/// 2. Call `bffClient.get<...>(...)` against
///    `/patients?search=...&status=...&cursor=...&limit=...`.
/// 3. Format the page payload (data array of summaries) via the injected
///    [OutputFormatter] and write to stdout.
/// 4. If the response carries `meta.nextCursor`, surface it on stderr (or
///    after the table) so the caller can paginate.
/// 5. Failures: BffClient `Failure(...)` → write error to stderr, return
///    non-zero exit.
///
/// Tests use the real [BffClient] wired to a fake Dio [HttpClientAdapter]
/// (the C02 convention) — `BffClient` is `final class` and cannot be
/// implemented; we capture the wire-level `RequestOptions` instead.
library;

import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/patient_list_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/formatters/table_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

void main() {
  group('PatientListCommand basics', () {
    test('extends Command<int> with name "list"', () {
      final cmd = PatientListCommand(
        bffClient: _bff(_okAdapter('{}')),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('list'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares search/status/cursor/limit options', () {
      final cmd = PatientListCommand(
        bffClient: _bff(_okAdapter('{}')),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('search'));
      expect(options, contains('status'));
      expect(options, contains('cursor'));
      expect(options, contains('limit'));
    });
  });

  group('PatientListCommand — happy path', () {
    test(
      'GETs /patients with search+status+cursor+limit query params',
      () async {
        final adapter = _CapturingAdapter(_emptyPageJson, status: 200);
        final cmd = PatientListCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stdout: StringBuffer(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--search=maria',
          '--status=admitted',
          '--cursor=opaque-123',
          '--limit=20',
        ]);

        expect(exit, equals(0));
        final captured = adapter.lastOptions!;
        expect(captured.method.toUpperCase(), equals('GET'));
        expect(captured.path, startsWith('/patients'));

        final fullPath =
            captured.path +
            (captured.uri.query.isEmpty ? '' : '?${captured.uri.query}');
        expect(fullPath, contains('search=maria'));
        expect(fullPath, contains('status=admitted'));
        expect(fullPath, contains('cursor=opaque-123'));
        expect(fullPath, contains('limit=20'));
      },
    );

    test(
      'formats payload via injected formatter and writes to stdout',
      () async {
        final adapter = _CapturingAdapter(_singlePageJson, status: 200);
        final stdout = StringBuffer();
        final cmd = PatientListCommand(
          bffClient: _bff(adapter),
          formatter: const _CapturingFormatter(),
          stdout: stdout,
        );

        final exit = await _runWithArgs(cmd, const []);

        expect(exit, equals(0));
        expect(stdout.toString(), contains('[CAPTURED]'));
      },
    );

    test('omits empty options from query string', () async {
      final adapter = _CapturingAdapter(_emptyPageJson, status: 200);
      final cmd = PatientListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
      );

      await _runWithArgs(cmd, const []);

      final captured = adapter.lastOptions!;
      final qp = captured.uri.queryParameters;
      // No search / status / cursor / limit set → query map empty (or all null).
      expect(qp.containsKey('search'), isFalse);
      expect(qp.containsKey('status'), isFalse);
      expect(qp.containsKey('cursor'), isFalse);
      expect(qp.containsKey('limit'), isFalse);
    });

    test('surfaces nextCursor when present (so caller can paginate)', () async {
      final adapter = _CapturingAdapter(_pageWithCursorJson, status: 200);
      final stdout = StringBuffer();
      final stderr = StringBuffer();
      final cmd = PatientListCommand(
        bffClient: _bff(adapter),
        formatter: const TableFormatter(),
        stdout: stdout,
        stderr: stderr,
      );

      await _runWithArgs(cmd, const []);

      final emitted = stdout.toString() + stderr.toString();
      expect(emitted, contains('opaque-cursor-XYZ'));
    });
  });

  group('PatientListCommand — failure paths', () {
    test('BFF 503 (network-class) → non-zero exit + stderr message', () async {
      final adapter = _CapturingAdapter('upstream offline', status: 503);
      final stderr = StringBuffer();
      final cmd = PatientListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), isNotEmpty);
    });

    test('BFF 401 (no token client wired) → non-zero exit', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = PatientListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('BFF 500 → non-zero exit + status surfaced', () async {
      final adapter = _CapturingAdapter('upstream BFF failure', status: 500);
      final stderr = StringBuffer();
      final cmd = PatientListCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const []);

      expect(exit, isNot(equals(0)));
      // The status code or message must appear on stderr so the user sees it.
      final lower = stderr.toString().toLowerCase();
      expect(lower, anyOf(contains('500'), contains('upstream')));
    });
  });
}

// ---------------------------------------------------------------------------
// Fixtures + fakes
// ---------------------------------------------------------------------------

const String _emptyPageJson =
    '{"data":[],"meta":{"pageSize":20,"totalCount":0,"hasMore":false}}';

const String _singlePageJson =
    '{"data":[{"patientId":"11111111-1111-4111-8111-111111111111",'
    '"personId":"22222222-2222-4222-8222-222222222222",'
    '"firstName":"Maria","lastName":"Silva","fullName":"Maria Silva",'
    '"primaryDiagnosis":"Q90","memberCount":3,"status":"admitted"}],'
    '"meta":{"pageSize":20,"totalCount":1,"hasMore":false}}';

const String _pageWithCursorJson =
    '{"data":[{"patientId":"33333333-3333-4333-8333-333333333333",'
    '"personId":"44444444-4444-4444-8444-444444444444",'
    '"fullName":"João Souza","memberCount":1,"status":"admitted"}],'
    '"meta":{"pageSize":20,"totalCount":100,"hasMore":true,'
    '"nextCursor":"opaque-cursor-XYZ"}}';

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

/// Captures the last `RequestOptions` Dio sent. Returns a fixed body+status.
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

HttpClientAdapter _okAdapter(String body) =>
    _CapturingAdapter(body, status: 200);

class _CapturingFormatter implements OutputFormatter {
  const _CapturingFormatter();
  @override
  String format(Object? data) => '[CAPTURED]\n';
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

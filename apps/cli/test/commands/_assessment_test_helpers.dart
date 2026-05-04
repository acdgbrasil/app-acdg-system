/// Shared fakes + parametrized test factory for the seven C05
/// `acdg assessment <verb>` commands.
///
/// All seven verbs share the same shape:
///   * Required positional `<patient-id>` (UUID v4).
///   * `--from-yaml=path` accepted as a full payload override.
///   * `--from-yaml` is mutually exclusive with field flags.
///   * PUT `/patients/<id>/assessment/<verb-kebab>` with the
///     `Update<X>Request.toJson()` body.
///   * 200/204 → exit 0; 401 → exit 2 + "auth" stderr; 5xx → exit 1 +
///     status-code stderr; 422 → exit 1 + "422" stderr; network → exit 3.
///
/// W0 (test-writer) references symbols that do NOT yet exist; the analyzer
/// is expected to flag those as errors so this file compiles only after W1
/// turns the suite GREEN.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

/// Canonical UUID v4 fixture used across every assessment-command test.
const String kAssessmentPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

/// Builds a [BffClient] wired to [adapter] for testing. Mirrors the family
/// command tests verbatim — no live network, no real credential store.
BffClient buildBff(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
    ..httpClientAdapter = adapter;
  return BffClient(
    baseUrl: 'http://localhost:3000',
    credentialStore: NullCredStore(),
    dio: dio,
  );
}

/// In-memory `CredentialStore` that always reports "not logged in" so the
/// CLI propagates 401 responses without a recursive refresh attempt.
final class NullCredStore implements CredentialStore {
  @override
  Future<OidcSession?> read() async => null;

  @override
  Future<void> write(OidcSession session) async {}

  @override
  Future<void> clear() async {}
}

/// Captures the last `RequestOptions` Dio sent, so the test can assert on
/// HTTP method, path, and body. Returns the canned [body] / [status] for
/// every request — there's no per-request matching here; per-test instances
/// keep that decoupled.
final class CapturingAdapter implements HttpClientAdapter {
  CapturingAdapter(this._body, {required this.status});

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

/// Throws a Dio connection-error so the CLI surfaces a NetworkError.
final class ThrowingAdapter implements HttpClientAdapter {
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

/// Decodes a Dio request body into a `Map<String, Object?>` regardless of
/// whether the production code passed the raw map through or pre-serialized
/// it to a JSON string.
Map<String, Object?> decodeBody(Object? raw) {
  if (raw is Map<String, Object?>) return raw;
  if (raw is String) {
    final decoded = jsonDecode(raw);
    return decoded as Map<String, Object?>;
  }
  fail('Unexpected request body shape: ${raw.runtimeType}');
}

/// Reader callback that fails with a clear test-time error if invoked. Used
/// when a test does NOT exercise the `--from-yaml` path; the CLI must not
/// touch the file-system unless the flag is present.
Future<String> failingReader(String path) async =>
    throw StateError('fileReader should not be called: $path');

/// Runs [cmd] with [args] under a one-off `CommandRunner<int>`. Maps
/// `UsageException` to exit-code `64` (sysexits EX_USAGE) so tests can assert
/// `isNot(equals(0))` consistently, mirroring `cli_runner.dart`.
Future<int> runWithArgs(Command<int> cmd, List<String> args) async {
  final runner = CommandRunner<int>('test', 'test')..addCommand(cmd);
  try {
    final code = await runner.run([cmd.name, ...args]);
    return code ?? 0;
  } on UsageException {
    return 64;
  }
}

/// Standalone "no such file" exception (no `dart:io` import — keeps the test
/// suite pure). Production paths surface real `FileSystemException`.
class NoSuchFileException implements Exception {
  const NoSuchFileException(this.message);
  final String message;
  @override
  String toString() => 'NoSuchFileException: $message';
}

/// Per-ficha factory that, given a wired [BffClient] + a `fileReader` + an
/// optional pair of `StringSink`s, returns the `Command<int>` under test.
///
/// Each ficha test builds an instance of its concrete command class
/// (`AssessmentHousingCommand`, `AssessmentHealthCommand`, etc.) inside the
/// closure and passes a real `JsonFormatter()` — the helper does not need to
/// know the formatter type, which keeps the contract uniform across fichas
/// regardless of any future formatter-resolver changes.
typedef AssessmentCommandFactory =
    Command<int> Function({
      required BffClient bffClient,
      required Future<String> Function(String path) fileReader,
      StringSink? stdout,
      StringSink? stderr,
    });

/// Cross-cutting test factory that exercises the contract every assessment
/// verb shares: HTTP method, path shape, missing positional, --from-yaml
/// happy path + mutually-exclusive guard + unreadable-file failure, 401,
/// 5xx, 422, network failure.
///
/// Each ficha's `*_test.dart` calls this once + adds its own ficha-specific
/// happy-path tests for the fields unique to that DTO (the parts the factory
/// can't generically know — body shape per `Update<X>Request`).
///
/// **Why a factory and not a `for` loop over a list:**
///   * Each ficha has its OWN required-flag set (e.g. housing has 15
///     mandatory scalar fields, social-health-summary has 3). The factory
///     takes a callback that returns the minimum legal `args` list for that
///     ficha, so the parent can drive the cross-cutting happy-path test
///     without hardcoding flag names.
///   * `--from-yaml` payload is per-ficha (different DTO shape per verb),
///     so [yamlBody] is also per-ficha.
///   * Body assertion can't be generic enough to catch every camelCase key,
///     so per-ficha body shape is asserted in each ficha's own file.
void runAssessmentCommandContract({
  required String verbName,
  required String pathSuffix,
  required AssessmentCommandFactory build,
  required List<String> Function() minimalArgs,
  required String yamlBody,
}) {
  group('$verbName basics', () {
    test('extends Command<int> with name "$verbName"', () {
      final cmd = build(
        bffClient: buildBff(CapturingAdapter('', status: 204)),
        fileReader: failingReader,
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals(verbName));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --from-yaml', () {
      final cmd = build(
        bffClient: buildBff(CapturingAdapter('', status: 204)),
        fileReader: failingReader,
      );
      // ignore: avoid_dynamic_calls — test asserts cross-ficha argParser API.
      final options =
          (cmd as dynamic).argParser.options.keys.toSet() as Set<dynamic>;
      expect(options, contains('from-yaml'));
    });
  });

  group(
    '$verbName — happy path (PUT /patients/<id>/assessment/$pathSuffix)',
    () {
      test('PUT with the correct method + path', () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = build(
          bffClient: buildBff(adapter),
          fileReader: failingReader,
          stdout: StringBuffer(),
        );

        final exit = await runWithArgs(cmd, [
          kAssessmentPatientId,
          ...minimalArgs(),
        ]);

        expect(exit, equals(0));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$kAssessmentPatientId/assessment/$pathSuffix'),
        );
      });
    },
  );

  group('$verbName — --from-yaml happy path', () {
    test('reads file via fileReader, PUTs the resulting payload', () async {
      String? lastReadPath;
      Future<String> reader(String path) async {
        lastReadPath = path;
        return yamlBody;
      }

      final adapter = CapturingAdapter('', status: 204);
      final cmd = build(
        bffClient: buildBff(adapter),
        fileReader: reader,
        stdout: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        '--from-yaml=/tmp/payload.yaml',
      ]);

      expect(exit, equals(0));
      expect(lastReadPath, equals('/tmp/payload.yaml'));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
      expect(
        adapter.lastOptions!.path,
        equals('/patients/$kAssessmentPatientId/assessment/$pathSuffix'),
      );
    });
  });

  group('$verbName — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call',
      () async {
        final adapter = CapturingAdapter('', status: 204);
        final cmd = build(
          bffClient: buildBff(adapter),
          fileReader: failingReader,
          stderr: StringBuffer(),
        );

        // minimalArgs() supplies all required field flags but NO positional.
        final exit = await runWithArgs(cmd, minimalArgs());

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('--from-yaml together with field flags → usage error '
        '(mutually exclusive)', () async {
      Future<String> reader(String _) async => yamlBody;
      final adapter = CapturingAdapter('', status: 204);
      final cmd = build(
        bffClient: buildBff(adapter),
        fileReader: reader,
        stderr: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        '--from-yaml=/tmp/payload.yaml',
        ...minimalArgs(),
      ]);

      expect(exit, isNot(equals(0)));
      // Contradictory input ⇒ BFF must NOT be called.
      expect(adapter.lastOptions, isNull);
    });

    test('--from-yaml pointing to unreadable file → non-zero exit', () async {
      Future<String> reader(String _) async =>
          throw const NoSuchFileException('no such file');
      final adapter = CapturingAdapter('', status: 204);
      final cmd = build(
        bffClient: buildBff(adapter),
        fileReader: reader,
        stderr: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        '--from-yaml=/does/not/exist.yaml',
      ]);

      expect(exit, isNot(equals(0)));
      // No BFF call when the file cannot be read.
      expect(adapter.lastOptions, isNull);
    });

    test(
      'BFF 422 (validation) → non-zero exit + stderr surfaces 422',
      () async {
        final adapter = CapturingAdapter(
          '{"error":{"code":"INVALID_BODY",'
          '"message":"missing or malformed required fields"}}',
          status: 422,
        );
        final stderr = StringBuffer();
        final cmd = build(
          bffClient: buildBff(adapter),
          fileReader: failingReader,
          stderr: stderr,
        );

        final exit = await runWithArgs(cmd, [
          kAssessmentPatientId,
          ...minimalArgs(),
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('422'));
      },
    );

    test('BFF 5xx → non-zero exit + stderr surfaces server status', () async {
      final adapter = CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = build(
        bffClient: buildBff(adapter),
        fileReader: failingReader,
        stderr: stderr,
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        ...minimalArgs(),
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = build(
        bffClient: buildBff(adapter),
        fileReader: failingReader,
        stderr: stderr,
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        ...minimalArgs(),
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = build(
        bffClient: buildBff(ThrowingAdapter()),
        fileReader: failingReader,
        stderr: StringBuffer(),
      );

      final exit = await runWithArgs(cmd, [
        kAssessmentPatientId,
        ...minimalArgs(),
      ]);

      expect(exit, isNot(equals(0)));
    });
  });
}

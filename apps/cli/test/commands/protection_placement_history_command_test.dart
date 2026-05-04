/// W0 RED — `ProtectionPlacementHistoryCommand` orchestration contract (C07).
///
/// W1 must create
/// `apps/cli/lib/src/commands/protection_placement_history_command.dart`:
///
/// ```dart
/// class ProtectionPlacementHistoryCommand extends Command<int> {
///   ProtectionPlacementHistoryCommand({
///     required this.bffClient,
///     required this.formatter,
///     required this.fileReader,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       // YAML-ONLY per ticket §Detalhes: "exigir `--from-yaml` por padrão".
///       // The DTO is a tree (List<RegistryDraftDto> with nested
///       // memberId/startDate/reason tuples + 2 optional sub-DTOs) that does
///       // not flatten to flag-friendly scalars. No field-flag fallback —
///       // the only way to drive this verb is `--from-yaml=<path>`.
///       ..addOption('from-yaml',
///           help: 'Path to a YAML payload (REQUIRED). The file must match '
///               'UpdatePlacementHistoryRequest schema.');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final Future<String> Function(String path) fileReader;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'placement-history';
///   @override Future<int> run();
/// }
/// ```
///
/// **Flag naming decision:** ticket prose wrote `--history-yaml=path/...` but
/// for symmetry with C03 patient register + C05 assessment fichas (both use
/// `--from-yaml`), this command uses `--from-yaml=path`. Documented in
/// REPORT §4.
///
/// Behavior (per `UpdatePlacementHistoryIntent` +
/// `UpdatePlacementHistoryRequest` +
/// `ProtectionContract.updatePlacementHistory`):
///   * Required positional `<patient-id>` (UUID v4).
///   * Required `--from-yaml=<path>`. Without it → usage error (exit 64),
///     no BFF call. NO field-flag fallback (per ticket "exigir `--from-yaml`
///     por padrão").
///   * Reads file via injected `fileReader`. Filesystem errors / YAML parse
///     errors → InvalidArgError → exit non-zero, no BFF call.
///   * PUT `/patients/<id>/placement-history` with the parsed YAML payload
///     as the JSON body. The body shape mirrors
///     `UpdatePlacementHistoryRequest.toJson()`:
///     ```json
///     {
///       "registries": [
///         {
///           "memberId": "<uuid>",
///           "startDate": "<iso8601>",
///           "reason": "<text>",
///           "endDate": "<iso8601-or-omitted>"
///         }
///       ],
///       "collectiveSituations": {
///         "homeLossReport": "<str-or-omitted>",
///         "thirdPartyGuardReport": "<str-or-omitted>"
///       },
///       "separationChecklist": {
///         "adultInPrison": <bool>,
///         "adolescentInInternment": <bool>
///       }
///     }
///     ```
///     * `registries` defaults to `[]` (DTO line 9). Required tuple per
///       `RegistryDraftDto` (DTO lines 33-37): `memberId`, `startDate`,
///       `reason` non-empty.
///     * `collectiveSituations` + `separationChecklist` are optional sub-
///       DTOs.
///     * `separationChecklist.adultInPrison` /
///       `.adolescentInInternment` default to `false`.
///   * 200 envelope `{data:null,meta:...}` OR 204 → exit 0.
///   * 401 → exit 2 + "auth" stderr.
///   * 422/4xx → exit 1 + status-code stderr.
///   * 5xx → exit 1 + status-code stderr.
///   * Network failure → exit 3.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/protection_placement_history_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kPatientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const String _kMemberId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const String _kVoidResponseJson =
    '{"data":null,"meta":{"timestamp":"2026-05-04T12:00:00Z"}}';

/// Minimal-but-realistic YAML payload exercising:
///   * one entry in `registries` with the required tuple (memberId, startDate,
///     reason) — verifying nested DTO parsing through the YAML→JSON pipeline.
///   * `collectiveSituations` with both optional fields.
///   * `separationChecklist` with explicit booleans.
const String _kYamlBody =
    '''
registries:
  - memberId: "$_kMemberId"
    startDate: "2026-01-15"
    reason: "Acolhimento institucional após violência."
    endDate: "2026-04-30"
collectiveSituations:
  homeLossReport: "Família perdeu moradia em enchente."
  thirdPartyGuardReport: "Avó materna assumiu guarda."
separationChecklist:
  adultInPrison: false
  adolescentInInternment: true
''';

void main() {
  group('ProtectionPlacementHistoryCommand basics', () {
    test('extends Command<int> with name "placement-history"', () {
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('placement-history'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --from-yaml (the ONLY way to drive the verb)', () {
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('from-yaml'));
    });
  });

  group('ProtectionPlacementHistoryCommand — --from-yaml happy path', () {
    test(
      'reads file via fileReader, PUTs /patients/<id>/placement-history with '
      'the parsed YAML payload',
      () async {
        String? lastReadPath;
        Future<String> reader(String path) async {
          lastReadPath = path;
          return _kYamlBody;
        }

        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = ProtectionPlacementHistoryCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: reader,
          stdout: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--from-yaml=/tmp/placement.yaml',
        ]);

        expect(exit, equals(0));
        expect(lastReadPath, equals('/tmp/placement.yaml'));
        expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
        expect(
          adapter.lastOptions!.path,
          equals('/patients/$_kPatientId/placement-history'),
        );
      },
    );

    test('PUT body matches UpdatePlacementHistoryRequest.toJson() shape — '
        'registries list with nested RegistryDraftDto + sub-DTOs', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, equals(0));
      final body = _decodeBody(adapter.lastOptions!.data);

      // Top-level: 3 optional sub-DTOs (registries default `[]`).
      expect(body['registries'], isA<List<Object?>>());
      final registries = body['registries']! as List<Object?>;
      expect(registries, hasLength(1));

      final entry = registries.first! as Map<String, Object?>;
      // Required tuple per RegistryDraftDto (DTO lines 33-37).
      expect(entry['memberId'], equals(_kMemberId));
      expect(entry['startDate'], equals('2026-01-15'));
      expect(
        entry['reason'],
        equals('Acolhimento institucional após violência.'),
      );
      // Optional endDate carried through.
      expect(entry['endDate'], equals('2026-04-30'));

      final collective = body['collectiveSituations']! as Map<String, Object?>;
      expect(
        collective['homeLossReport'],
        equals('Família perdeu moradia em enchente.'),
      );
      expect(
        collective['thirdPartyGuardReport'],
        equals('Avó materna assumiu guarda.'),
      );

      final separation = body['separationChecklist']! as Map<String, Object?>;
      expect(separation['adultInPrison'], equals(false));
      expect(separation['adolescentInInternment'], equals(true));
    });

    test('200 with envelope `{data:null}` → exit 0', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, equals(0));
    });

    test('204 No Content → exit 0', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, equals(0));
    });
  });

  group('ProtectionPlacementHistoryCommand — failure paths', () {
    test(
      'missing positional patient-id → non-zero exit, no BFF call, no read',
      () async {
        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = ProtectionPlacementHistoryCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: _failingReader,
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          '--from-yaml=/tmp/placement.yaml',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing --from-yaml → usage error (NO field-flag fallback per '
        '"exigir --from-yaml por padrão")', () async {
      final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: _failingReader,
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kPatientId]);

      expect(exit, isNot(equals(0)));
      // No BFF call when no payload source is provided.
      expect(adapter.lastOptions, isNull);
    });

    test(
      '--from-yaml pointing to unreadable file → non-zero exit, no BFF call',
      () async {
        Future<String> reader(String _) async =>
            throw const _NoSuchFileException('no such file');
        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = ProtectionPlacementHistoryCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: reader,
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--from-yaml=/does/not/exist.yaml',
        ]);

        expect(exit, isNot(equals(0)));
        // No BFF call when the file cannot be read.
        expect(adapter.lastOptions, isNull);
      },
    );

    test(
      '--from-yaml with malformed YAML → non-zero exit, no BFF call',
      () async {
        // Top-level scalar — `_yaml_helpers.readYamlBody` rejects (must be map).
        Future<String> reader(String _) async => 'just a scalar string';
        final adapter = _CapturingAdapter(_kVoidResponseJson, status: 200);
        final cmd = ProtectionPlacementHistoryCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          fileReader: reader,
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kPatientId,
          '--from-yaml=/tmp/bad.yaml',
        ]);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('BFF 422 (validation) → non-zero exit + stderr', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INVALID_PLACEMENT_HISTORY_BODY",'
        '"message":"missing or malformed required fields"}}',
        status: 422,
      );
      final stderr = StringBuffer();
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('422'));
    });

    test('BFF 5xx → non-zero exit + stderr surfaces server status', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter(
        '{"error":{"code":"INTERNAL","message":"Internal server error"}}',
        status: 500,
      );
      final stderr = StringBuffer();
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString().toLowerCase(), contains('auth'));
    });

    test('Network failure → non-zero exit', () async {
      Future<String> reader(String _) async => _kYamlBody;
      final cmd = ProtectionPlacementHistoryCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        fileReader: reader,
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kPatientId,
        '--from-yaml=/tmp/placement.yaml',
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

Future<String> _failingReader(String path) async =>
    throw StateError('fileReader should not be called: $path');

class _NoSuchFileException implements Exception {
  const _NoSuchFileException(this.message);
  final String message;
  @override
  String toString() => 'NoSuchFileException: $message';
}

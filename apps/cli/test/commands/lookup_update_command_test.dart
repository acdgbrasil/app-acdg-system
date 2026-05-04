/// W0 RED — `LookupUpdateCommand` orchestration contract (C08).
///
/// W1 must create `apps/cli/lib/src/commands/lookup_update_command.dart`:
///
/// ```dart
/// class LookupUpdateCommand extends Command<int> {
///   LookupUpdateCommand({
///     required this.bffClient,
///     required this.formatter,
///     this.stdout,
///     this.stderr,
///   }) {
///     argParser
///       ..addOption('code', help: 'New code (optional, partial update)')
///       ..addOption('label', help: 'New description (optional)')
///       ..addOption('active', help: 'New active flag (optional)');
///   }
///
///   final BffClient bffClient;
///   final OutputFormatter formatter;
///   final StringSink? stdout;
///   final StringSink? stderr;
///
///   @override String get name => 'update';
///   @override Future<int> run();
/// }
/// ```
///
/// Behavior (per `UpdateLookupItemIntent` + `UpdateLookupItemRequest` +
/// `LookupContract.updateLookupItem`):
///   * Required positionals `<table-name> <item-id>` (item-id is UUID v4).
///   * All flags are OPTIONAL — the BFF DTO is partial:
///     `UpdateLookupItemRequest({this.codigo, this.descricao})`.
///   * The BFF intent (`update_lookup_item_intent.dart`) is "P2-tolerant":
///     missing/null fields collapse to `null`, never produce a parse error.
///   * Map CLI → DTO field names (DTO-as-canon):
///     - `--code` → `codigo` (omitted when absent)
///     - `--label` → `descricao` (omitted when absent)
///     - `--active` → ticket includes this flag, but the canonical
///       `UpdateLookupItemRequest` DTO does not carry `active`. The dedicated
///       `lookup toggle` verb owns that. CLI may still expose `--active` for
///       UX continuity but the wire body MUST NOT carry an `active` key.
///       See `lookup_toggle_command_test.dart` for the toggle path.
///   * PUT `/lookups/<tableName>/<itemId>` body shape:
///     ```json
///     {"codigo"?: "...", "descricao"?: "..."}
///     ```
///   * 204 No Content → exit 0.
///   * 400 INVALID_UPDATE_LOOKUP_ITEM_BODY (UUID failure) / 401 / 5xx →
///     non-zero exit + stderr.
///
/// **Naming decision (deviation).** Ticket prose: `--code=X --label=Y
/// --active=true`. DTO is `{codigo?, descricao?}` (partial). CLI flags stay
/// human-friendly; wire follows DTO. `--active=true` belongs to `toggle` —
/// see Decisions in REPORT.md.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'package:cli/src/commands/lookup_update_command.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/session/bff_client.dart';
import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

const String _kTableName = 'dominio_parentesco';
const String _kItemId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  group('LookupUpdateCommand basics', () {
    test('extends Command<int> with name "update"', () {
      final cmd = LookupUpdateCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      expect(cmd, isA<Command<int>>());
      expect(cmd.name, equals('update'));
      expect(cmd.description, isNotEmpty);
    });

    test('argParser declares --code and --label options', () {
      final cmd = LookupUpdateCommand(
        bffClient: _bff(_CapturingAdapter('', status: 204)),
        formatter: const JsonFormatter(),
      );
      final options = cmd.argParser.options.keys.toSet();
      expect(options, contains('code'));
      expect(options, contains('label'));
    });
  });

  group('LookupUpdateCommand — happy path', () {
    test('PUTs /lookups/<tableName>/<itemId> with partial body — '
        'DTO field names (codigo/descricao)', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupUpdateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--code=NEW-CODE',
        '--label=Nova Descrição',
      ]);

      expect(exit, equals(0));
      expect(adapter.lastOptions!.method.toUpperCase(), equals('PUT'));
      expect(
        adapter.lastOptions!.path,
        equals('/lookups/$_kTableName/$_kItemId'),
      );

      final body = _decodeBody(adapter.lastOptions!.data);
      // DTO-faithful field names on the wire.
      expect(body['codigo'], equals('NEW-CODE'));
      expect(body['descricao'], equals('Nova Descrição'));
      // CLI-friendly names MUST NOT leak.
      expect(body.containsKey('code'), isFalse);
      expect(body.containsKey('label'), isFalse);
    });

    test(
      'partial body: with only --code present, --label is omitted (DTO `?`)',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupUpdateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--code=NEW-CODE',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        expect(body['codigo'], equals('NEW-CODE'));
        // `descricao` MUST be omitted (DTO ? convention; helper drops nulls).
        if (body.containsKey('descricao')) {
          expect(
            body['descricao'],
            isNull,
            reason: 'descricao must be omitted or null when --label is absent',
          );
        }
      },
    );

    test(
      'partial body: with only --label present, --code is omitted',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupUpdateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--label=Nova',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        expect(body['descricao'], equals('Nova'));
        if (body.containsKey('codigo')) {
          expect(body['codigo'], isNull);
        }
      },
    );

    test(
      'wire body MUST NOT carry an `active` key (toggle is a separate verb)',
      () async {
        // Ticket prose says `update --active=true`, but the DTO is
        // `UpdateLookupItemRequest({codigo?, descricao?})`. `active` belongs
        // exclusively to `lookup toggle` (PATCH). Ensure the CLI does not
        // smuggle `active` onto the update body.
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupUpdateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
        );

        // Even if the CLI exposes --active for UX continuity, it MUST NOT
        // serialize it on the wire — otherwise `parseFromBody` ignores it
        // silently. We pass --code only here; --active is asserted out
        // regardless of presence.
        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--code=NEW-CODE',
        ]);

        expect(exit, equals(0));
        final body = _decodeBody(adapter.lastOptions!.data);
        expect(
          body.containsKey('active'),
          isFalse,
          reason:
              'update body MUST NOT carry `active`; that is `toggle` territory',
        );
      },
    );

    test('204 No Content → exit 0', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupUpdateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stdout: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--code=X',
      ]);

      expect(exit, equals(0));
    });
  });

  group('LookupUpdateCommand — failure paths', () {
    test(
      'missing positional table-name → non-zero exit, no BFF call',
      () async {
        final adapter = _CapturingAdapter('', status: 204);
        final cmd = LookupUpdateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: StringBuffer(),
        );

        final exit = await _runWithArgs(cmd, const ['--code=X']);

        expect(exit, isNot(equals(0)));
        expect(adapter.lastOptions, isNull);
      },
    );

    test('missing positional item-id → non-zero exit, no BFF call', () async {
      final adapter = _CapturingAdapter('', status: 204);
      final cmd = LookupUpdateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [_kTableName, '--code=X']);

      expect(exit, isNot(equals(0)));
      expect(adapter.lastOptions, isNull);
    });

    test(
      'BFF 400 INVALID_UPDATE_LOOKUP_ITEM_BODY (UUID failure) → non-zero exit',
      () async {
        // BFF intent UUID-validates `itemId` (path-only). A non-UUID id can
        // surface as 400. Test: client MAY validate locally OR forward —
        // either way, non-zero exit is the contract here.
        final adapter = _CapturingAdapter(
          '{"error":{"code":"INVALID_UPDATE_LOOKUP_ITEM_BODY",'
          '"message":"itemId must be UUID v4"}}',
          status: 400,
        );
        final stderr = StringBuffer();
        final cmd = LookupUpdateCommand(
          bffClient: _bff(adapter),
          formatter: const JsonFormatter(),
          stderr: stderr,
        );

        final exit = await _runWithArgs(cmd, const [
          _kTableName,
          _kItemId,
          '--code=X',
        ]);

        expect(exit, isNot(equals(0)));
        expect(stderr.toString(), contains('400'));
      },
    );

    test('BFF 401 → non-zero exit + auth-related stderr', () async {
      final adapter = _CapturingAdapter('unauthorized', status: 401);
      final stderr = StringBuffer();
      final cmd = LookupUpdateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--code=X',
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
      final cmd = LookupUpdateCommand(
        bffClient: _bff(adapter),
        formatter: const JsonFormatter(),
        stderr: stderr,
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--code=X',
      ]);

      expect(exit, isNot(equals(0)));
      expect(stderr.toString(), contains('500'));
    });

    test('Network failure → non-zero exit', () async {
      final cmd = LookupUpdateCommand(
        bffClient: _bff(_ThrowingAdapter()),
        formatter: const JsonFormatter(),
        stderr: StringBuffer(),
      );

      final exit = await _runWithArgs(cmd, const [
        _kTableName,
        _kItemId,
        '--code=X',
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
    if (raw.isEmpty) return const <String, Object?>{};
    final decoded = jsonDecode(raw);
    return decoded as Map<String, Object?>;
  }
  if (raw == null) return const <String, Object?>{};
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

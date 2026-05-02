import 'dart:convert';

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/handlers/lookup_handler.dart';
import 'package:social_care_web/src/use_cases/approve_lookup_request_use_case.dart';
import 'package:social_care_web/src/use_cases/create_lookup_item_use_case.dart';
import 'package:social_care_web/src/use_cases/create_lookup_request_use_case.dart';
import 'package:social_care_web/src/use_cases/get_lookup_requests_use_case.dart';
import 'package:social_care_web/src/use_cases/get_lookup_table_use_case.dart';
import 'package:social_care_web/src/use_cases/get_lookups_batch_use_case.dart';
import 'package:social_care_web/src/use_cases/reject_lookup_request_use_case.dart';
import 'package:social_care_web/src/use_cases/toggle_lookup_item_use_case.dart';
import 'package:social_care_web/src/use_cases/update_lookup_item_use_case.dart';

import '../_test_uuids.dart';

/// A [LookupContract] variant that forces every mutation / query to fail with
/// a well-known [BackendError]. Used to validate failure-path status codes.
class _FailingLookup extends FakeLookupBff {
  _FailingLookup(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<LookupItemResponse>>>> getLookupTable(
    String tableName,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<LookupsBatchResponse>>> getLookupsBatch(
    List<String> tables,
  ) async => Failure(error);

  @override
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> updateLookupItem(
    String tableName,
    String itemId,
    UpdateLookupItemRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> toggleLookupItem(
    String tableName,
    String itemId,
    ToggleLookupItemRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<List<LookupRequestResponse>>>>
  getLookupRequests() async => Failure(error);

  @override
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> approveLookupRequest(
    String requestId,
  ) async => Failure(error);

  @override
  Future<Result<StandardResponse<void>>> rejectLookupRequest(
    String requestId,
  ) async => Failure(error);
}

/// A [LookupContract] variant that explodes with a raw [Exception] wrapped in
/// [Failure]. Used to validate the 500 sanitization path.
class _ExplodingLookup extends FakeLookupBff {
  @override
  Future<Result<StandardIdResponse>> createLookupItem(
    String tableName,
    CreateLookupItemRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));

  @override
  Future<Result<StandardIdResponse>> createLookupRequest(
    CreateLookupRequestRequest request,
  ) async => Failure(Exception('internal leak marker xyz'));

  @override
  Future<Result<StandardResponse<void>>> approveLookupRequest(
    String requestId,
  ) async => Failure(Exception('internal leak marker xyz'));
}

LookupHandler _buildHandler({LookupContract? lookup}) {
  final l = lookup ?? FakeLookupBff();
  return LookupHandler(
    getLookupTable: GetLookupTableUseCase(lookup: l),
    getLookupsBatch: GetLookupsBatchUseCase(lookup: l),
    createLookupItem: CreateLookupItemUseCase(lookup: l),
    updateLookupItem: UpdateLookupItemUseCase(lookup: l),
    toggleLookupItem: ToggleLookupItemUseCase(lookup: l),
    getLookupRequests: GetLookupRequestsUseCase(lookup: l),
    createLookupRequest: CreateLookupRequestUseCase(lookup: l),
    approveLookupRequest: ApproveLookupRequestUseCase(lookup: l),
    rejectLookupRequest: RejectLookupRequestUseCase(lookup: l),
  );
}

void _seedItem(
  FakeLookupBff fake, {
  required String tableName,
  required String id,
  String codigo = 'COD',
  String descricao = 'Desc',
}) {
  fake.store.addItem(
    tableName,
    LookupItemResponse(id: id, codigo: codigo, descricao: descricao),
  );
}

void _seedRequest(
  FakeLookupBff fake, {
  required String id,
  String status = 'pending',
}) {
  fake.store.addRequest(
    LookupRequestResponse(
      id: id,
      tableName: 'dominio_diagnostico',
      codigo: 'WILLIAMS',
      descricao: 'Sindrome de Williams',
      justificativa: 'raro',
      status: status,
      createdAt: '2026-04-17T10:00:00Z',
      requestedBy: 'user-42',
    ),
  );
}

Map<String, dynamic> _validCreateItemBody() => {
  'codigo': 'MAE',
  'descricao': 'Mae',
};

Map<String, dynamic> _validToggleBody({bool active = true}) => {
  'active': active,
};

Map<String, dynamic> _validCreateRequestBody() => {
  'tableName': 'dominio_diagnostico',
  'codigo': 'WILLIAMS',
  'descricao': 'Sindrome de Williams',
  'justificativa': 'Necessario adicionar este diagnostico raro',
};

void main() {
  group('LookupHandler (thin handler — UseCase orchestration)', () {
    // ── GET /lookups/<tableName> ────────────────────────────────────────────

    group('GET /lookups/<tableName>', () {
      test('returns 200 with empty list when table is unseeded', () async {
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<List<dynamic>>());
        expect(body['data'] as List, isEmpty);
        expect(body['meta'], isA<Map<String, dynamic>>());
      });

      test('returns 200 with seeded items', () async {
        final fake = FakeLookupBff();
        _seedItem(
          fake,
          tableName: 'dominio_parentesco',
          id: '1',
          codigo: 'MAE',
          descricao: 'Mae',
        );
        _seedItem(
          fake,
          tableName: 'dominio_parentesco',
          id: '2',
          codigo: 'PAI',
          descricao: 'Pai',
        );

        final handler = _buildHandler(lookup: fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'] as List, hasLength(2));
      });

      test('returns upstream status when getLookupTable fails', () async {
        final failing = _FailingLookup(
          const BackendError(
            id: 'err-1',
            code: 'LOOKUP_UNAVAILABLE',
            message: 'upstream down',
            http: 502,
          ),
        );
        final handler = _buildHandler(lookup: failing);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
      });
    });

    // ── POST /lookups/<tableName> ───────────────────────────────────────────

    group('POST /lookups/<tableName>', () {
      test('returns 200 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
          body: jsonEncode(_validCreateItemBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<Map<String, dynamic>>());
        expect((body['data'] as Map)['id'], isNotEmpty);
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test(
        'returns 400 (INVALID_CREATE_LOOKUP_ITEM_BODY) when codigo is missing',
        () async {
          final handler = _buildHandler();

          final body = _validCreateItemBody()..remove('codigo');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookups/dominio_parentesco'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_CREATE_LOOKUP_ITEM_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_CREATE_LOOKUP_ITEM_BODY) when descricao is missing',
        () async {
          final handler = _buildHandler();

          final body = _validCreateItemBody()..remove('descricao');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookups/dominio_parentesco'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_CREATE_LOOKUP_ITEM_BODY'),
          );
        },
      );

      test(
        'returns upstream status when createLookupItem fails with BackendError',
        () async {
          final failing = _FailingLookup(
            const BackendError(
              id: 'err-1',
              code: 'DUPLICATE_CODE',
              message: 'codigo already exists',
              http: 409,
            ),
          );
          final handler = _buildHandler(lookup: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookups/dominio_parentesco'),
            body: jsonEncode(_validCreateItemBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(409));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(lookup: _ExplodingLookup());

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookups/dominio_parentesco'),
          body: jsonEncode(_validCreateItemBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });
    });

    // ── PUT /lookups/<tableName>/<id> ───────────────────────────────────────

    group('PUT /lookups/<tableName>/<id>', () {
      test(
        'returns 200 with null data on happy path (all fields present)',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
            body: jsonEncode(const {
              'codigo': 'NEW_CODE',
              'descricao': 'New description',
            }),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, lessThan(300));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(body.containsKey('data'), isTrue);
          expect(body['data'], isNull);
          expect(body['meta'], isA<Map<String, dynamic>>());
        },
      );

      test(
        'returns 200 with empty {} body (P2-tolerant — no required fields)',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
            body: jsonEncode(const <String, dynamic>{}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, lessThan(300));
        },
      );

      test(
        'returns 200 with partial body (P2-tolerant — only codigo)',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
            body: jsonEncode(const {'codigo': 'NEW_CODE'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, lessThan(300));
        },
      );

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test(
        'NO INVALID_UPDATE_LOOKUP_ITEM_BODY code — parse is total (P2-tolerant)',
        () async {
          // P2-tolerant: the parser NEVER fails for a decoded Map. The only
          // 400 code emitted for this route is INVALID_JSON (handled above).
          // This test pins the absence of a dedicated body-validation code by
          // showing that even a body with type-mismatched values lands on the
          // happy path.
          final handler = _buildHandler();

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
            body: jsonEncode(const <String, dynamic>{
              'codigo': 42,
              'descricao': true,
            }),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          // Tolerant parse collapses to null; UseCase runs as no-op update.
          expect(response.statusCode, lessThan(300));
        },
      );

      test(
        'returns upstream status when updateLookupItem fails with BackendError',
        () async {
          final failing = _FailingLookup(
            const BackendError(
              id: 'err-1',
              code: 'ITEM_NOT_FOUND',
              message: 'item does not exist',
              http: 404,
            ),
          );
          final handler = _buildHandler(lookup: failing);

          final request = Request(
            'PUT',
            Uri.parse('http://localhost/lookups/dominio_parentesco/$kLookupItemUuid'),
            body: jsonEncode(const {'codigo': 'X'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(404));
        },
      );
    });

    // ── PATCH /lookups/<tableName>/<id>/toggle ──────────────────────────────

    group('PATCH /lookups/<tableName>/<id>/toggle', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PATCH',
          Uri.parse(
            'http://localhost/lookups/dominio_parentesco/$kLookupItemUuid/toggle',
          ),
          body: jsonEncode(_validToggleBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body.containsKey('data'), isTrue);
        expect(body['data'], isNull);
        expect(body['meta'], isA<Map<String, dynamic>>());
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'PATCH',
          Uri.parse(
            'http://localhost/lookups/dominio_parentesco/$kLookupItemUuid/toggle',
          ),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test(
        'returns 400 (INVALID_TOGGLE_LOOKUP_ITEM_BODY) when active is missing',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PATCH',
            Uri.parse(
              'http://localhost/lookups/dominio_parentesco/$kLookupItemUuid/toggle',
            ),
            body: jsonEncode(const <String, dynamic>{}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_TOGGLE_LOOKUP_ITEM_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_TOGGLE_LOOKUP_ITEM_BODY) when active is not a bool',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'PATCH',
            Uri.parse(
              'http://localhost/lookups/dominio_parentesco/$kLookupItemUuid/toggle',
            ),
            body: jsonEncode(const {'active': 'true'}),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_TOGGLE_LOOKUP_ITEM_BODY'),
          );
        },
      );

      test(
        'returns upstream status when toggleLookupItem fails with BackendError',
        () async {
          final failing = _FailingLookup(
            const BackendError(
              id: 'err-1',
              code: 'ITEM_NOT_FOUND',
              message: 'item does not exist',
              http: 404,
            ),
          );
          final handler = _buildHandler(lookup: failing);

          final request = Request(
            'PATCH',
            Uri.parse(
              'http://localhost/lookups/dominio_parentesco/$kLookupItemUuid/toggle',
            ),
            body: jsonEncode(_validToggleBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(404));
        },
      );
    });

    // ── GET /lookup-requests ────────────────────────────────────────────────

    group('GET /lookup-requests', () {
      test('returns 200 with empty list when nothing is stored', () async {
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookup-requests'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<List<dynamic>>());
        expect(body['data'] as List, isEmpty);
      });

      test('returns 200 with seeded requests', () async {
        final fake = FakeLookupBff();
        _seedRequest(fake, id: 'r-1');
        _seedRequest(fake, id: 'r-2');

        final handler = _buildHandler(lookup: fake);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookup-requests'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'] as List, hasLength(2));
      });

      test('returns upstream status when getLookupRequests fails', () async {
        final failing = _FailingLookup(
          const BackendError(
            id: 'err-1',
            code: 'LOOKUP_UNAVAILABLE',
            message: 'upstream down',
            http: 502,
          ),
        );
        final handler = _buildHandler(lookup: failing);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/lookup-requests'),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
      });
    });

    // ── POST /lookup-requests ───────────────────────────────────────────────

    group('POST /lookup-requests', () {
      test('returns 200 with { id } on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookup-requests'),
          body: jsonEncode(_validCreateRequestBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['data'], isA<Map<String, dynamic>>());
        expect((body['data'] as Map)['id'], isNotEmpty);
      });

      test('returns 400 (INVALID_JSON) when body is invalid JSON', () async {
        final handler = _buildHandler();

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookup-requests'),
          body: 'not json',
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect((body['error'] as Map)['code'], equals('INVALID_JSON'));
      });

      test(
        'returns 400 (INVALID_CREATE_LOOKUP_REQUEST_BODY) when tableName is missing',
        () async {
          final handler = _buildHandler();

          final body = _validCreateRequestBody()..remove('tableName');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookup-requests'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_CREATE_LOOKUP_REQUEST_BODY'),
          );
        },
      );

      test(
        'returns 400 (INVALID_CREATE_LOOKUP_REQUEST_BODY) when codigo is missing',
        () async {
          final handler = _buildHandler();

          final body = _validCreateRequestBody()..remove('codigo');
          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookup-requests'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final decoded =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          expect(
            (decoded['error'] as Map)['code'],
            equals('INVALID_CREATE_LOOKUP_REQUEST_BODY'),
          );
        },
      );

      test(
        'returns upstream status when createLookupRequest fails with BackendError',
        () async {
          final failing = _FailingLookup(
            const BackendError(
              id: 'err-1',
              code: 'DUPLICATE_REQUEST',
              message: 'already exists',
              http: 409,
            ),
          );
          final handler = _buildHandler(lookup: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookup-requests'),
            body: jsonEncode(_validCreateRequestBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(409));
        },
      );

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(lookup: _ExplodingLookup());

        final request = Request(
          'POST',
          Uri.parse('http://localhost/lookup-requests'),
          body: jsonEncode(_validCreateRequestBody()),
          headers: {'content-type': 'application/json'},
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });

      test(
        '400 response does NOT echo raw justificativa (PII — CRITICAL)',
        () async {
          final handler = _buildHandler();

          // missing tableName → INVALID_CREATE_LOOKUP_REQUEST_BODY
          final body = {
            'codigo': 'X',
            'descricao': 'Y',
            'justificativa': 'Preciso pois minha filha de 5 anos tem Williams',
          };
          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookup-requests'),
            body: jsonEncode(body),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final dumped = await response.readAsString();

          expect(response.statusCode, equals(400));
          expect(dumped, isNot(contains('filha de 5 anos')));
          expect(dumped, isNot(contains('Williams')));
          expect(dumped, isNot(contains('Preciso pois')));
        },
      );
    });

    // ── PUT /lookup-requests/<id>/approve ───────────────────────────────────

    group('PUT /lookup-requests/<id>/approve', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/lookup-requests/'
            '660e8400-e29b-41d4-a716-446655440001/approve',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body.containsKey('data'), isTrue);
        expect(body['data'], isNull);
      });

      test('returns upstream status when approveLookupRequest fails', () async {
        final failing = _FailingLookup(
          const BackendError(
            id: 'err-1',
            code: 'REQUEST_NOT_FOUND',
            message: 'not found',
            http: 404,
          ),
        );
        final handler = _buildHandler(lookup: failing);

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/lookup-requests/'
            '660e8400-e29b-41d4-a716-446655440001/approve',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(404));
      });

      test('500 response body sanitizes raw Exception / stack trace', () async {
        final handler = _buildHandler(lookup: _ExplodingLookup());

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/lookup-requests/'
            '660e8400-e29b-41d4-a716-446655440001/approve',
          ),
        );
        final response = await handler.router.call(request);
        final body = await response.readAsString();

        expect(response.statusCode, equals(500));
        expect(body, isNot(contains('leak marker')));
        expect(body, isNot(contains('Exception:')));
        expect(body, isNot(contains('#0')));
      });
    });

    // ── PUT /lookup-requests/<id>/reject ────────────────────────────────────

    group('PUT /lookup-requests/<id>/reject', () {
      test('returns 200 with null data on happy path', () async {
        final handler = _buildHandler();

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/lookup-requests/'
            '660e8400-e29b-41d4-a716-446655440001/reject',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, lessThan(300));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body.containsKey('data'), isTrue);
        expect(body['data'], isNull);
      });

      test('returns upstream status when rejectLookupRequest fails', () async {
        final failing = _FailingLookup(
          const BackendError(
            id: 'err-1',
            code: 'REQUEST_NOT_FOUND',
            message: 'not found',
            http: 404,
          ),
        );
        final handler = _buildHandler(lookup: failing);

        final request = Request(
          'PUT',
          Uri.parse(
            'http://localhost/lookup-requests/'
            '660e8400-e29b-41d4-a716-446655440001/reject',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(404));
      });
    });

    // ── State matrix (P1) — sanitized error body ────────────────────────────

    group('State matrix (P1) — sanitized error body', () {
      test(
        'BackendError.message surfaces but Dart stack traces do not',
        () async {
          final failing = _FailingLookup(
            const BackendError(
              id: 'err-1',
              code: 'DUPLICATE_CODE',
              message: 'curated upstream message',
              http: 409,
            ),
          );
          final handler = _buildHandler(lookup: failing);

          final request = Request(
            'POST',
            Uri.parse('http://localhost/lookups/dominio_parentesco'),
            body: jsonEncode(_validCreateItemBody()),
            headers: {'content-type': 'application/json'},
          );
          final response = await handler.router.call(request);
          final body = await response.readAsString();

          expect(body, isNot(contains('#0')), reason: 'stack traces leak');
          expect(body, isNot(contains('Exception:')));
        },
      );
    });

    // ── GET /lookups (batch via query string) ─────────────────────────────

    group('GET /lookups (batch via query string)', () {
      test('returns 200 with empty lists for unseeded tables', () async {
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/lookups?tables=dominio_parentesco,dominio_tipo_identidade',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        final tables = (body['data'] as Map<String, dynamic>)['tables']
            as Map<String, dynamic>;
        expect(tables.keys, containsAll(<String>[
          'dominio_parentesco',
          'dominio_tipo_identidade',
        ]));
        expect(tables['dominio_parentesco'] as List, isEmpty);
        expect(tables['dominio_tipo_identidade'] as List, isEmpty);
      });

      test('returns 200 with seeded items keyed by table name', () async {
        final fake = FakeLookupBff();
        _seedItem(
          fake,
          tableName: 'dominio_parentesco',
          id: '1',
          codigo: 'MAE',
          descricao: 'Mae',
        );
        _seedItem(
          fake,
          tableName: 'dominio_tipo_identidade',
          id: '10',
          codigo: 'RG',
          descricao: 'RG',
        );

        final handler = _buildHandler(lookup: fake);

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/lookups?tables=dominio_parentesco,dominio_tipo_identidade',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        final tables = (body['data'] as Map<String, dynamic>)['tables']
            as Map<String, dynamic>;
        expect(tables['dominio_parentesco'] as List, hasLength(1));
        expect(tables['dominio_tipo_identidade'] as List, hasLength(1));
      });

      test('tolerates whitespace and empty tokens in the CSV', () async {
        final handler = _buildHandler();

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/lookups?tables=%20a%20,,b%20,',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(200));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        final tables = (body['data'] as Map<String, dynamic>)['tables']
            as Map<String, dynamic>;
        expect(tables.keys, equals(<String>{'a', 'b'}));
      });

      test(
        'returns 400 INVALID_LOOKUPS_BATCH_QUERY when tables is missing',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'GET',
            Uri.parse('http://localhost/lookups'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_LOOKUPS_BATCH_QUERY'));
        },
      );

      test(
        'returns 400 INVALID_LOOKUPS_BATCH_QUERY when tables is empty',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'GET',
            Uri.parse('http://localhost/lookups?tables='),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_LOOKUPS_BATCH_QUERY'));
        },
      );

      test(
        'returns 400 INVALID_LOOKUPS_BATCH_QUERY when tables only has commas',
        () async {
          final handler = _buildHandler();

          final request = Request(
            'GET',
            Uri.parse('http://localhost/lookups?tables=,,,'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
        },
      );

      test(
        'returns 400 INVALID_LOOKUPS_BATCH_QUERY when count exceeds 20',
        () async {
          final handler = _buildHandler();
          final tables = List.generate(21, (i) => 't$i').join(',');

          final request = Request(
            'GET',
            Uri.parse('http://localhost/lookups?tables=$tables'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(400));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          final error = body['error'] as Map<String, dynamic>;
          expect(error['code'], equals('INVALID_LOOKUPS_BATCH_QUERY'));
        },
      );

      test('returns upstream status when getLookupsBatch fails', () async {
        final failing = _FailingLookup(
          const BackendError(
            id: 'err-1',
            code: 'LOOKUP_UNAVAILABLE',
            message: 'upstream down',
            http: 502,
          ),
        );
        final handler = _buildHandler(lookup: failing);

        final request = Request(
          'GET',
          Uri.parse(
            'http://localhost/lookups?tables=dominio_parentesco',
          ),
        );
        final response = await handler.router.call(request);

        expect(response.statusCode, equals(502));
        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        final error = body['error'] as Map<String, dynamic>;
        expect(error['code'], equals('LOOKUP_UNAVAILABLE'));
      });

      test(
        'does not match GET /lookups/<tableName> (route specificity preserved)',
        () async {
          // Sanity check: the new /lookups (no path segment) must NOT
          // hijack the existing path-only route. Both endpoints coexist.
          final fake = FakeLookupBff();
          _seedItem(
            fake,
            tableName: 'dominio_parentesco',
            id: '1',
            codigo: 'MAE',
            descricao: 'Mae',
          );
          final handler = _buildHandler(lookup: fake);

          final request = Request(
            'GET',
            Uri.parse('http://localhost/lookups/dominio_parentesco'),
          );
          final response = await handler.router.call(request);

          expect(response.statusCode, equals(200));
          final body =
              jsonDecode(await response.readAsString()) as Map<String, dynamic>;
          // Single-table response shape (NOT batch shape):
          expect(body['data'], isA<List<dynamic>>());
        },
      );
    });
  });
}

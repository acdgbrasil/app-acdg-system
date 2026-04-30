/// RED-phase tests for `LookupRemote` (A16-v2).
///
/// `LookupRemote implements LookupContract`. Eight methods.
///
/// Backend route base: `/api/v1/dominios/...` (see Swift
/// `LookupController.swift` — uses Portuguese term "dominios", not
/// English "lookups"). The Hono web BFF translates `/lookups/*` →
/// backend `/api/v1/dominios/*`; the desktop has no BFF in front of it,
/// so the wire path IS `/api/v1/dominios/*`.
///
/// ── Item queries (2) ────────────────────────────────────────────────
///   * `getLookupTable(tableName)`
///       → `GET /api/v1/dominios/{tableName}` (returns
///         `StandardResponse<List<LookupItemResponse>>`)
///   * `getLookupsBatch(tables)`
///       → REGRA #2 AMBIGUITY (see test group below).
///         The Swift backend has NO batch endpoint; the contract was
///         introduced in A14 as a BFF-side aggregator. Tests below
///         assert the canonical "fan-out and aggregate" behavior:
///         N parallel `GET /api/v1/dominios/{name}` calls, results
///         assembled into `LookupsBatchResponse`. The implementer is
///         free to choose a single-call optimized path IF the backend
///         later exposes one — but at that point the test must be
///         updated and the change documented.
///
/// ── Item admin (3) ──────────────────────────────────────────────────
///   * `createLookupItem(tableName, req)`
///       → `POST /api/v1/dominios/{tableName}` (returns
///         `StandardIdResponse`)
///   * `updateLookupItem(tableName, itemId, req)`
///       → `PUT /api/v1/dominios/{tableName}/{itemId}` (returns
///         `StandardResponse<void>`)
///   * `toggleLookupItem(tableName, itemId, req)`
///       → `PATCH /api/v1/dominios/{tableName}/{itemId}/toggle`
///         with body `{"active": bool}` from
///         `ToggleLookupItemRequest.toJson()` (returns
///         `StandardResponse<void>`)
///
/// ── Governance requests (3) ─────────────────────────────────────────
///   * `getLookupRequests()`
///       → `GET /api/v1/dominios/requests` (returns
///         `StandardResponse<List<LookupRequestResponse>>`)
///   * `createLookupRequest(req)`
///       → `POST /api/v1/dominios/requests` (returns
///         `StandardIdResponse`)
///   * `approveLookupRequest(requestId)`
///       → `PUT /api/v1/dominios/requests/{requestId}/approve`
///         (returns `StandardResponse<void>`)
///   * `rejectLookupRequest(requestId)`
///       → `PUT /api/v1/dominios/requests/{requestId}/reject`
///         (returns `StandardResponse<void>`)
///
/// REGRA #2 note (return shapes): the new sub-contract returns
/// `StandardResponse<void>` for `updateLookupItem`, `toggleLookupItem`,
/// `approveLookupRequest`, `rejectLookupRequest` — different from the
/// legacy `Result<void>`. The Swift backend returns 204 No Content
/// (empty body) for these. We test that the remote synthesizes a
/// `StandardResponse<void>(data: null, meta: ResponseMeta(timestamp: <now-ish>))`
/// on 204 even when the body is empty. If the backend later returns a
/// `meta` envelope, the implementer should prefer that over a
/// synthesized one — but the "synthesize on empty" behavior is the
/// minimum viable contract.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:social_care_desktop/src/remote/lookup_remote.dart';
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_mock_dio.dart';

void main() {
  group('LookupRemote', () {
    late MockDio dio;
    late LookupRemote remote;

    setUp(() {
      dio = MockDio();
      remote = LookupRemote(dio: dio);
    });

    test('implements LookupContract', () {
      expect(remote, isA<LookupContract>());
    });

    // ── getLookupTable ────────────────────────────────────────────────
    group('getLookupTable', () {
      test('hits GET /api/v1/dominios/<tableName>', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        await remote.getLookupTable('dominio_parentesco');

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/api/v1/dominios/dominio_parentesco'));
      });

      test('parses LookupItemResponse list on 200', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': kLookupItemUuid,
              'codigo': 'mae',
              'descricao': 'Mãe',
            },
          ],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        final result = await remote.getLookupTable('dominio_parentesco');

        switch (result) {
          case Success(:final value):
            expect(value.data, hasLength(1));
            expect(value.data.first.id, equals(kLookupItemUuid));
            expect(value.data.first.codigo, equals('mae'));
          case Failure():
            fail('Expected Success on 200');
        }
      });

      test(
        'maps 404 with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-404',
            message: 'unknown table',
            http: 404,
          );

          final result = await remote.getLookupTable('dominio_inexistente');

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
              expect(
                (error as BackendErrorResponse).error.code,
                equals('LKP-404'),
              );
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.getLookupTable('dominio_parentesco');

        expect(
          result,
          isA<Failure<StandardResponse<List<LookupItemResponse>>>>(),
        );
      });
    });

    // ── getLookupsBatch ───────────────────────────────────────────────
    //
    // REGRA #2 AMBIGUITY documented in REPORT.md.
    // Tests below assume the implementer fans out N parallel
    // `GET /api/v1/dominios/{name}` requests and aggregates them. If a
    // backend batch endpoint is introduced later, both the impl and
    // these tests must be updated together.
    group('getLookupsBatch', () {
      test(
        'on success aggregates per-table responses into LookupsBatchResponse',
        () async {
          // The MockDio returns the same `nextResponseData` for every
          // call, so we assert the aggregator yields one entry per
          // requested table — even if both tables come back with the
          // same items. This proves the fan-out shape.
          dio.nextStatusCode = 200;
          dio.nextResponseData = <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': kLookupItemUuid,
                'codigo': 'a',
                'descricao': 'Alpha',
              },
            ],
            'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
          };

          final result = await remote.getLookupsBatch(<String>[
            'dominio_parentesco',
            'dominio_tipo_identidade',
          ]);

          switch (result) {
            case Success(:final value):
              expect(
                value.data.tables.keys,
                containsAll(<String>[
                  'dominio_parentesco',
                  'dominio_tipo_identidade',
                ]),
              );
              expect(value.data.tables['dominio_parentesco'], hasLength(1));
            case Failure():
              fail('Expected Success when all per-table fetches succeed');
          }
        },
      );

      test(
        'returns Failure if any per-table fetch fails (short-circuit)',
        () async {
          // The first call already triggers the throw — `_maybeThrow`
          // resets `nextThrow` after firing, so the second call would
          // succeed. The aggregator should still surface a `Failure`
          // because at least one fetch failed.
          dio.nextThrow = Exception('table fetch failed');

          final result = await remote.getLookupsBatch(<String>[
            'dominio_parentesco',
            'dominio_tipo_identidade',
          ]);

          expect(
            result,
            isA<Failure<StandardResponse<LookupsBatchResponse>>>(),
          );
        },
      );
    });

    // ── createLookupItem ──────────────────────────────────────────────
    group('createLookupItem', () {
      const request = CreateLookupItemRequest(codigo: 'avo', descricao: 'Avó');

      test('hits POST /api/v1/dominios/<tableName> with body', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kLookupItemUuid);

        await remote.createLookupItem('dominio_parentesco', request);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/dominios/dominio_parentesco'));
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kLookupItemUuid);

        final result = await remote.createLookupItem(
          'dominio_parentesco',
          request,
        );

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kLookupItemUuid));
          case Failure():
            fail('Expected Success on 201');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 409;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-409',
            message: 'duplicate codigo',
            http: 409,
          );

          final result = await remote.createLookupItem(
            'dominio_parentesco',
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 409');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.createLookupItem(
          'dominio_parentesco',
          request,
        );

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });

    // ── updateLookupItem ──────────────────────────────────────────────
    group('updateLookupItem', () {
      const request = UpdateLookupItemRequest(descricao: 'Avó (atualizado)');

      test(
        'hits PUT /api/v1/dominios/<tableName>/<itemId> with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.updateLookupItem(
            'dominio_parentesco',
            kLookupItemUuid,
            request,
          );

          expect(dio.lastMethod, equals('PUT'));
          expect(
            dio.lastPath,
            equals('/api/v1/dominios/dominio_parentesco/$kLookupItemUuid'),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('synthesizes StandardResponse on 204 (empty body)', () async {
        // REGRA #2 note: see file-level docstring.
        dio.nextStatusCode = 204;

        final result = await remote.updateLookupItem(
          'dominio_parentesco',
          kLookupItemUuid,
          request,
        );

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-404',
            message: 'item not found',
            http: 404,
          );

          final result = await remote.updateLookupItem(
            'dominio_parentesco',
            kLookupItemUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.updateLookupItem(
          'dominio_parentesco',
          kLookupItemUuid,
          request,
        );

        expect(result, isA<Failure<StandardResponse<void>>>());
      });
    });

    // ── toggleLookupItem ──────────────────────────────────────────────
    group('toggleLookupItem', () {
      const request = ToggleLookupItemRequest(active: false);

      test(
        'hits PATCH /api/v1/dominios/<tableName>/<itemId>/toggle with body',
        () async {
          dio.nextStatusCode = 204;

          await remote.toggleLookupItem(
            'dominio_parentesco',
            kLookupItemUuid,
            request,
          );

          expect(dio.lastMethod, equals('PATCH'));
          expect(
            dio.lastPath,
            equals(
              '/api/v1/dominios/dominio_parentesco/$kLookupItemUuid/toggle',
            ),
          );
          expect(dio.lastBody, equals(request.toJson()));
        },
      );

      test('forwards active=true correctly', () async {
        dio.nextStatusCode = 204;
        const reactivate = ToggleLookupItemRequest(active: true);

        await remote.toggleLookupItem(
          'dominio_parentesco',
          kLookupItemUuid,
          reactivate,
        );

        expect((dio.lastBody as Map<String, dynamic>?)?['active'], isTrue);
      });

      test('synthesizes StandardResponse on 204 (empty body)', () async {
        dio.nextStatusCode = 204;

        final result = await remote.toggleLookupItem(
          'dominio_parentesco',
          kLookupItemUuid,
          request,
        );

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-404',
            message: 'item not found',
            http: 404,
          );

          final result = await remote.toggleLookupItem(
            'dominio_parentesco',
            kLookupItemUuid,
            request,
          );

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.toggleLookupItem(
          'dominio_parentesco',
          kLookupItemUuid,
          request,
        );

        expect(result, isA<Failure<StandardResponse<void>>>());
      });
    });

    // ── getLookupRequests ─────────────────────────────────────────────
    group('getLookupRequests', () {
      test('hits GET /api/v1/dominios/requests', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        await remote.getLookupRequests();

        expect(dio.lastMethod, equals('GET'));
        expect(dio.lastPath, equals('/api/v1/dominios/requests'));
      });

      test('parses LookupRequestResponse list on 200', () async {
        dio.nextStatusCode = 200;
        dio.nextResponseData = <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': kLookupRequestUuid,
              'tableName': 'dominio_parentesco',
              'codigo': 'tio',
              'descricao': 'Tio',
              'justificativa': 'caso real',
              'status': 'pending',
              'createdAt': '2026-04-29T09:00:00.000Z',
              'requestedBy': kPersonUuid,
            },
          ],
          'meta': <String, dynamic>{'timestamp': '2026-04-29T10:00:00.000Z'},
        };

        final result = await remote.getLookupRequests();

        switch (result) {
          case Success(:final value):
            expect(value.data, hasLength(1));
            expect(value.data.first.id, equals(kLookupRequestUuid));
            expect(value.data.first.status, equals('pending'));
          case Failure():
            fail('Expected Success on 200');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 403;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-403',
            message: 'forbidden',
            http: 403,
          );

          final result = await remote.getLookupRequests();

          switch (result) {
            case Success():
              fail('Expected Failure on 403');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.getLookupRequests();

        expect(
          result,
          isA<Failure<StandardResponse<List<LookupRequestResponse>>>>(),
        );
      });
    });

    // ── createLookupRequest ───────────────────────────────────────────
    group('createLookupRequest', () {
      const request = CreateLookupRequestRequest(
        tableName: 'dominio_parentesco',
        codigo: 'tio',
        descricao: 'Tio',
        justificativa: 'caso real',
      );

      test('hits POST /api/v1/dominios/requests with body', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kLookupRequestUuid);

        await remote.createLookupRequest(request);

        expect(dio.lastMethod, equals('POST'));
        expect(dio.lastPath, equals('/api/v1/dominios/requests'));
        expect(dio.lastBody, equals(request.toJson()));
      });

      test('parses StandardIdResponse on 201', () async {
        dio.nextStatusCode = 201;
        dio.nextResponseData = kIdResponseBody(kLookupRequestUuid);

        final result = await remote.createLookupRequest(request);

        switch (result) {
          case Success(:final value):
            expect(value.data.id, equals(kLookupRequestUuid));
          case Failure():
            fail('Expected Success on 201');
        }
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 422;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-422',
            message: 'invalid table',
            http: 422,
          );

          final result = await remote.createLookupRequest(request);

          switch (result) {
            case Success():
              fail('Expected Failure on 422');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.createLookupRequest(request);

        expect(result, isA<Failure<StandardIdResponse>>());
      });
    });

    // ── approveLookupRequest ──────────────────────────────────────────
    group('approveLookupRequest', () {
      test('hits PUT /api/v1/dominios/requests/<id>/approve', () async {
        dio.nextStatusCode = 204;

        await remote.approveLookupRequest(kLookupRequestUuid);

        expect(dio.lastMethod, equals('PUT'));
        expect(
          dio.lastPath,
          equals('/api/v1/dominios/requests/$kLookupRequestUuid/approve'),
        );
      });

      test('synthesizes StandardResponse on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.approveLookupRequest(kLookupRequestUuid);

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-404',
            message: 'request not found',
            http: 404,
          );

          final result = await remote.approveLookupRequest(kLookupRequestUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('reset');

        final result = await remote.approveLookupRequest(kLookupRequestUuid);

        expect(result, isA<Failure<StandardResponse<void>>>());
      });
    });

    // ── rejectLookupRequest ───────────────────────────────────────────
    group('rejectLookupRequest', () {
      test('hits PUT /api/v1/dominios/requests/<id>/reject', () async {
        dio.nextStatusCode = 204;

        await remote.rejectLookupRequest(kLookupRequestUuid);

        expect(dio.lastMethod, equals('PUT'));
        expect(
          dio.lastPath,
          equals('/api/v1/dominios/requests/$kLookupRequestUuid/reject'),
        );
      });

      test('synthesizes StandardResponse on 204', () async {
        dio.nextStatusCode = 204;

        final result = await remote.rejectLookupRequest(kLookupRequestUuid);

        expect(result, isA<Success<StandardResponse<void>>>());
      });

      test(
        'maps non-2xx with error body to Failure(BackendErrorResponse)',
        () async {
          dio.nextStatusCode = 404;
          dio.nextResponseData = kBackendErrorBody(
            code: 'LKP-404',
            message: 'request not found',
            http: 404,
          );

          final result = await remote.rejectLookupRequest(kLookupRequestUuid);

          switch (result) {
            case Success():
              fail('Expected Failure on 404');
            case Failure(:final error):
              expect(error, isA<BackendErrorResponse>());
          }
        },
      );

      test('returns Failure when Dio throws', () async {
        dio.nextThrow = Exception('boom');

        final result = await remote.rejectLookupRequest(kLookupRequestUuid);

        expect(result, isA<Failure<StandardResponse<void>>>());
      });
    });
  });
}

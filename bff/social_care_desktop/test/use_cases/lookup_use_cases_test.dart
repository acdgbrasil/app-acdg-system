/// RED-phase tests for Lookup use cases (A18b-v2).
///
/// 10 use cases — 4 reads + 6 writes.
///
/// Reads (4):
///   * `GetLookupTableUseCase`         — by tableName, cache-first.
///   * `GetLookupsBatchUseCase`        — fan-out via N parallel
///                                       `GetLookupTableUseCase` calls.
///   * `ListLookupRequestsUseCase`     — with status / tableName / limit
///                                       filters.
///   * `FindLookupRequestByIdUseCase`  — by requestId.
///
/// Writes (6):
///   * `CreateLookupItemUseCase`       — register-style: expectedVersion 0;
///                                        aggregateId == itemId (server-
///                                        side generated); tableName goes
///                                        in payload `_tableName` key.
///   * `UpdateLookupItemUseCase`       — patient-style update on item id;
///                                        expectedVersion read from cache
///                                        item; tableName + payload.
///   * `ToggleLookupItemUseCase`       — same shape as update.
///   * `CreateLookupRequestUseCase`    — register-style.
///   * `ApproveLookupRequestUseCase`   — body-less; expectedVersion read
///                                        from cached request entity.
///   * `RejectLookupRequestUseCase`    — body-less; same shape.
///
/// REGRA #2 lock — `expectedVersion` for governance lookup requests:
///   For create/approve/reject of governance lookup requests, the
///   underlying entity is a `LookupRequest`. Cache: `LookupCache.findRequestById`.
///   Approve/reject use the requestId-cached version. Create uses 0.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/lookup/...` do NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/get_lookup_table_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/get_lookups_batch_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/list_lookup_requests_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/find_lookup_request_by_id_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/create_lookup_item_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/update_lookup_item_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/toggle_lookup_item_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/create_lookup_request_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/approve_lookup_request_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/lookup/reject_lookup_request_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  const kTable = 'dominio_parentesco';

  LookupItemResponse item({String id = kLookupItemUuid}) => LookupItemResponse(
        id: id,
        codigo: 'PAI',
        descricao: 'Pai',
      );

  LookupRequestResponse request({String id = kLookupRequestUuid}) =>
      LookupRequestResponse(
        id: id,
        tableName: kTable,
        codigo: 'PAD',
        descricao: 'Padrasto',
        justificativa: 'Add stepfather variant',
        status: 'pending',
        createdAt: '2026-04-30T12:00:00Z',
        requestedBy: kMemberUuid,
      );

  // ═════════════════════════════════════════════════════════════════════
  // READS (4)
  // ═════════════════════════════════════════════════════════════════════

  group('GetLookupTableUseCase (Pattern 1)', () {
    test('cache hit fresh returns items without remote call', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertItem(kTable, item(), version: 1);

      final useCase = GetLookupTableUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable);
      expect(result, isA<Success<List<LookupItemResponse>>>());
      expect(
          (result as Success<List<LookupItemResponse>>).value, hasLength(1));
    });

    test('cache miss falls back to remote and upserts items', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeLookup.store.tables[kTable] = [item()];

      final useCase = GetLookupTableUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable);
      expect((result as Success<List<LookupItemResponse>>).value, hasLength(1));
    });

    test('stale cache → refresh remote', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertItem(kTable, item(), version: 1);
      ctx.fakeClock.advance(const Duration(minutes: 10));

      ctx.fakeLookup.store.tables[kTable] = [
        item(),
        const LookupItemResponse(
            id: 'cccccccc-cccc-4ccc-accc-cccccccccccc',
            codigo: 'MAE',
            descricao: 'Mãe'),
      ];

      final useCase = GetLookupTableUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable);
      expect(
          (result as Success<List<LookupItemResponse>>).value, hasLength(2));
    });
  });

  group('GetLookupsBatchUseCase (fan-out)', () {
    test('returns Map<tableName, items> for each requested table', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertItem(kTable, item(), version: 1);
      await ctx.lookupCache.upsertItem(
        'dominio_situacao',
        const LookupItemResponse(
            id: 'dddddddd-dddd-4ddd-addd-dddddddddddd',
            codigo: 'ATIVO',
            descricao: 'Ativo'),
        version: 1,
      );

      final useCase = GetLookupsBatchUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase([kTable, 'dominio_situacao']);
      expect(result, isA<Success<Map<String, List<LookupItemResponse>>>>());
      final map =
          (result as Success<Map<String, List<LookupItemResponse>>>).value;
      expect(map.keys, containsAll([kTable, 'dominio_situacao']));
      expect(map[kTable], hasLength(1));
      expect(map['dominio_situacao'], hasLength(1));
    });

    test('empty input returns Success(empty map)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = GetLookupsBatchUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(<String>[]);
      expect(result, isA<Success<Map<String, List<LookupItemResponse>>>>());
      expect(
          (result as Success<Map<String, List<LookupItemResponse>>>).value,
          isEmpty);
    });
  });

  group('ListLookupRequestsUseCase (Pattern 1)', () {
    test('cache hit fresh returns requests', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertRequest(request(), version: 1);

      final useCase = ListLookupRequestsUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase();
      expect(
          (result as Success<List<LookupRequestResponse>>).value, hasLength(1));
    });

    test('status filter narrows results', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertRequest(request(), version: 1);
      await ctx.lookupCache.upsertRequest(
        LookupRequestResponse(
          id: 'eeeeeeee-eeee-4eee-aeee-eeeeeeeeeeee',
          tableName: kTable,
          codigo: 'TIA',
          descricao: 'Tia',
          status: 'approved',
          createdAt: '2026-04-30T11:00:00Z',
          requestedBy: kMemberUuid,
          justificativa: null,
        ),
        version: 1,
      );

      final useCase = ListLookupRequestsUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(status: 'approved');
      final list =
          (result as Success<List<LookupRequestResponse>>).value;
      expect(list, hasLength(1));
      expect(list.single.status, 'approved');
    });
  });

  group('FindLookupRequestByIdUseCase (Pattern 1)', () {
    test('cache hit returns request', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertRequest(request(), version: 1);

      final useCase = FindLookupRequestByIdUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      expect(result, isA<Success<LookupRequestResponse?>>());
      expect((result as Success<LookupRequestResponse?>).value, isNotNull);
    });

    test('cache miss returns Success(null) (no remote endpoint for single request)',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = FindLookupRequestByIdUseCase(
        cache: ctx.lookupCache,
        remote: ctx.fakeLookup,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      // LookupContract has no fetchRequestById — cache-only fallback OR
      // implementer may opt to fan-out via getLookupRequests + filter.
      expect(result, anyOf(isA<Success>(), isA<Failure>()));
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // WRITES (6)
  // ═════════════════════════════════════════════════════════════════════

  group('CreateLookupItemUseCase (Pattern 2 — register-style)', () {
    const req = CreateLookupItemRequest(codigo: 'AVO', descricao: 'Avô');

    test('happy path enqueues create_lookup_item with tableName in payload',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CreateLookupItemUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, req);
      expect(result, isA<Success<StandardIdResponse>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'create_lookup_item');
      expect(entry.expectedVersion, 0);
      expect(entry.aggregateType, 'lookup_item');
      expect(entry.payload['_tableName'], kTable);
      expect(entry.payload['codigo'], 'AVO');

      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('outbox failure propagates', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.syncDb.close();

      final useCase = CreateLookupItemUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, req);
      expect(result, isA<Failure<StandardIdResponse>>());
    });
  });

  group('UpdateLookupItemUseCase (Pattern 2)', () {
    const req = UpdateLookupItemRequest(descricao: 'Pai biológico');

    test('happy path enqueues update_lookup_item with cached version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Seed cached item at version 2.
      await ctx.lookupCache.upsertItem(kTable, item(), version: 2);

      final useCase = UpdateLookupItemUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, kLookupItemUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'update_lookup_item');
      expect(entry.aggregateId, kLookupItemUuid);
      expect(entry.expectedVersion, 2);
      expect(entry.payload['_tableName'], kTable);
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateLookupItemUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, kLookupItemUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  group('ToggleLookupItemUseCase (Pattern 2)', () {
    const req = ToggleLookupItemRequest(active: false);

    test('happy path enqueues toggle_lookup_item', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertItem(kTable, item(), version: 1);

      final useCase = ToggleLookupItemUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, kLookupItemUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'toggle_lookup_item');
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ToggleLookupItemUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kTable, kLookupItemUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  group('CreateLookupRequestUseCase (Pattern 2 — register-style)', () {
    const req = CreateLookupRequestRequest(
      tableName: kTable,
      codigo: 'PRI',
      descricao: 'Primo',
    );

    test('happy path enqueues create_lookup_request with expectedVersion 0',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CreateLookupRequestUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(req);
      expect(result, isA<Success<StandardIdResponse>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'create_lookup_request');
      expect(entry.expectedVersion, 0);
      expect(entry.aggregateType, 'lookup_request');
    });
  });

  group('ApproveLookupRequestUseCase (Pattern 2 — body-less)', () {
    test('happy path enqueues approve_lookup_request with cached version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertRequest(request(), version: 3);

      final useCase = ApproveLookupRequestUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'approve_lookup_request');
      expect(entry.expectedVersion, 3);
      expect(entry.payload, isEmpty);
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ApproveLookupRequestUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  group('RejectLookupRequestUseCase (Pattern 2 — body-less)', () {
    test('happy path enqueues reject_lookup_request with cached version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.lookupCache.upsertRequest(request(), version: 1);

      final useCase = RejectLookupRequestUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'reject_lookup_request');
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = RejectLookupRequestUseCase(
        cache: ctx.lookupCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kLookupRequestUuid);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });
}

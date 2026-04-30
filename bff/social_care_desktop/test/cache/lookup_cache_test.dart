/// RED-phase tests for `LookupCache` (A17-v2).
///
/// `LookupCache` covers two governance entities: lookup tables (each
/// keyed by `tableName`) and lookup change requests. The tableName has
/// FTS5 search to enable typeahead UX (e.g. "type 'civil' to find
/// civil_status table"); the codigo/descricao of items inside a table
/// are NOT indexed (consumers can iterate the small in-memory list).
///
/// ── Surface under test ────────────────────────────────────────────────
/// Lookup items (per tableName, multiple rows):
///   * `findItemById(String tableName, String itemId)`
///       → `Future<Result<LookupItemResponse?>>`
///   * `listItems(String tableName)`
///       → `Future<Result<List<LookupItemResponse>>>` (B-Tree on tableName)
///   * `listAllTables()`
///       → `Future<Result<List<String>>>` (distinct tableNames cached)
///   * `searchTables(String term)`
///       → `Future<Result<List<String>>>` (FTS5 on tableName)
///   * `upsertItem(String tableName, LookupItemResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deleteItem(String tableName, String itemId)` → `Future<Result<void>>`
///   * `clearTable(String tableName)` → `Future<Result<void>>`
///
/// Lookup requests (governance approval workflow):
///   * `findRequestById(String requestId)`
///       → `Future<Result<LookupRequestResponse?>>`
///   * `listRequests({String? status, String? tableName, int? limit})`
///       → `Future<Result<List<LookupRequestResponse>>>`
///   * `upsertRequest(LookupRequestResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deleteRequest(String requestId)` → `Future<Result<void>>`
///
/// Cross-cutting:
///   * `clear()` — wipes both tables.
///
/// IMPORTANT (RED phase): `LookupCache` and `DriftLookupCache` do NOT
/// exist yet. `import` lines fail — that is the intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/contracts/lookup_cache.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/impls/drift_lookup_cache.dart';

import '../_test_uuids.dart';
import '_test_db.dart';

void main() {
  group('LookupCache (Drift, in-memory)', () {
    late LookupCache cache;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemoryDatabase();
      cache = DriftLookupCache(database);
    });

    tearDown(() async {
      await safeClose(database);
    });

    LookupItemResponse item({
      String id = kLookupItemUuid,
      String codigo = 'BR',
      String descricao = 'Brasileiro',
    }) {
      return LookupItemResponse(id: id, codigo: codigo, descricao: descricao);
    }

    LookupRequestResponse request({
      String id = kLookupRequestUuid,
      String tableName = 'nationalities',
      String status = 'pending',
    }) {
      return LookupRequestResponse(
        id: id,
        tableName: tableName,
        codigo: 'NEW',
        descricao: 'New nationality',
        justificativa: 'Patient is dual-citizen',
        status: status,
        createdAt: '2026-04-15T10:00:00.000Z',
        requestedBy: kMemberUuid,
      );
    }

    test('implements LookupCache contract', () {
      expect(cache, isA<LookupCache>());
    });

    // ── Lookup items ───────────────────────────────────────────────────
    group('Items', () {
      test('upsert + findItemById round-trip', () async {
        final dto = item();

        final upsert = await cache.upsertItem('nationalities', dto, version: 1);
        expect(upsert, isA<Success<void>>());

        final found = await cache.findItemById(
          'nationalities',
          kLookupItemUuid,
        );

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kLookupItemUuid));
            expect(value.codigo, equals('BR'));
            expect(value.descricao, equals('Brasileiro'));
          case Failure():
            fail('expected Success');
        }
      });

      test('findItemById returns Success(null) when missing', () async {
        final found = await cache.findItemById(
          'nationalities',
          kLookupItemUuid,
        );
        expect((found as Success).value, isNull);
      });

      test(
        'listItems returns only items for the requested tableName',
        () async {
          await cache.upsertItem('nationalities', item(), version: 1);
          await cache.upsertItem(
            'civil_status',
            item(
              id: 'a9b0e1f2-a3b4-4567-989a-bcdef0123456',
              codigo: 'SOLT',
              descricao: 'Solteiro(a)',
            ),
            version: 1,
          );

          final result = await cache.listItems('nationalities');

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(1));
              expect(value.first.codigo, equals('BR'));
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('listAllTables returns distinct cached tableNames', () async {
        await cache.upsertItem('nationalities', item(), version: 1);
        await cache.upsertItem(
          'civil_status',
          item(id: 'a9b0e1f2-a3b4-4567-989a-bcdef0123456'),
          version: 1,
        );

        final result = await cache.listAllTables();

        switch (result) {
          case Success(:final value):
            expect(value.toSet(), equals({'nationalities', 'civil_status'}));
          case Failure():
            fail('expected Success');
        }
      });

      test('deleteItem removes the row', () async {
        await cache.upsertItem('nationalities', item(), version: 1);

        await cache.deleteItem('nationalities', kLookupItemUuid);

        final found = await cache.findItemById(
          'nationalities',
          kLookupItemUuid,
        );
        expect((found as Success).value, isNull);
      });

      test('clearTable wipes only the requested tableName', () async {
        await cache.upsertItem('nationalities', item(), version: 1);
        await cache.upsertItem(
          'civil_status',
          item(id: 'a9b0e1f2-a3b4-4567-989a-bcdef0123456'),
          version: 1,
        );

        final clear = await cache.clearTable('nationalities');
        expect(clear, isA<Success<void>>());

        expect(
          ((await cache.listItems('nationalities')) as Success).value,
          isEmpty,
        );
        expect(
          ((await cache.listItems('civil_status')) as Success).value,
          hasLength(1),
        );
      });
    });

    // ── searchTables (FTS5) ────────────────────────────────────────────
    group('searchTables (FTS5)', () {
      setUp(() async {
        await cache.upsertItem('civil_status', item(), version: 1);
        await cache.upsertItem(
          'civil_marriage_regime',
          item(id: 'a9b0e1f2-a3b4-4567-989a-bcdef0123456'),
          version: 1,
        );
        await cache.upsertItem(
          'nationalities',
          item(id: 'b9b0e1f2-a3b4-4567-989a-bcdef0123456'),
          version: 1,
        );
      });

      test('exact token match returns the table name', () async {
        final result = await cache.searchTables('nationalities');

        switch (result) {
          case Success(:final value):
            expect(value, contains('nationalities'));
            expect(value, hasLength(1));
          case Failure():
            fail('expected Success');
        }
      });

      test(
        'prefix match (civil*) returns both civil_status and civil_marriage_regime',
        () async {
          final result = await cache.searchTables('civil');

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(2));
              expect(
                value.toSet(),
                equals({'civil_status', 'civil_marriage_regime'}),
              );
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('no-match returns empty list', () async {
        final result = await cache.searchTables('xyzzyfoo');

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });

      test(
        'FTS5 syncs after deleteItem (if last item per tableName)',
        () async {
          await cache.clearTable('nationalities');

          final result = await cache.searchTables('nationalities');

          switch (result) {
            case Success(:final value):
              expect(value, isEmpty);
            case Failure():
              fail('expected Success');
          }
        },
      );
    });

    // ── Lookup requests ────────────────────────────────────────────────
    group('Requests', () {
      test('upsert + findRequestById round-trip', () async {
        final dto = request();

        final upsert = await cache.upsertRequest(dto, version: 1);
        expect(upsert, isA<Success<void>>());

        final found = await cache.findRequestById(kLookupRequestUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kLookupRequestUuid));
            expect(value.tableName, equals('nationalities'));
            expect(value.codigo, equals('NEW'));
            expect(value.justificativa, equals('Patient is dual-citizen'));
            expect(value.status, equals('pending'));
            expect(value.requestedBy, equals(kMemberUuid));
          case Failure():
            fail('expected Success');
        }
      });

      test('findRequestById returns Success(null) when missing', () async {
        final found = await cache.findRequestById(kLookupRequestUuid);
        expect((found as Success).value, isNull);
      });

      test('listRequests with no filters returns all', () async {
        await cache.upsertRequest(request(), version: 1);
        await cache.upsertRequest(
          request(
            id: 'd1e1f2a3-b4c5-4678-9a9b-cdef01234567',
            tableName: 'civil_status',
            status: 'approved',
          ),
          version: 1,
        );

        final result = await cache.listRequests();

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
          case Failure():
            fail('expected Success');
        }
      });

      test('listRequests filters by status', () async {
        await cache.upsertRequest(request(status: 'pending'), version: 1);
        await cache.upsertRequest(
          request(
            id: 'd1e1f2a3-b4c5-4678-9a9b-cdef01234567',
            status: 'approved',
          ),
          version: 1,
        );

        final result = await cache.listRequests(status: 'approved');

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.status, equals('approved'));
          case Failure():
            fail('expected Success');
        }
      });

      test('listRequests filters by tableName', () async {
        await cache.upsertRequest(
          request(tableName: 'nationalities'),
          version: 1,
        );
        await cache.upsertRequest(
          request(
            id: 'd1e1f2a3-b4c5-4678-9a9b-cdef01234567',
            tableName: 'civil_status',
          ),
          version: 1,
        );

        final result = await cache.listRequests(tableName: 'civil_status');

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.tableName, equals('civil_status'));
          case Failure():
            fail('expected Success');
        }
      });

      test('deleteRequest removes the row', () async {
        await cache.upsertRequest(request(), version: 1);

        await cache.deleteRequest(kLookupRequestUuid);

        final found = await cache.findRequestById(kLookupRequestUuid);
        expect((found as Success).value, isNull);
      });
    });

    // ── clear (top-level) ──────────────────────────────────────────────
    group('clear', () {
      test('wipes both lookup items and lookup requests', () async {
        await cache.upsertItem('nationalities', item(), version: 1);
        await cache.upsertRequest(request(), version: 1);

        final clear = await cache.clear();
        expect(clear, isA<Success<void>>());

        expect(
          ((await cache.listItems('nationalities')) as Success).value,
          isEmpty,
        );
        expect(((await cache.listRequests()) as Success).value, isEmpty);
      });
    });

    // ── DB-failure path ────────────────────────────────────────────────
    group('DB failure', () {
      test('returns Failure when underlying database is closed', () async {
        await database.close();

        final result = await cache.findItemById(
          'nationalities',
          kLookupItemUuid,
        );

        expect(result, isA<Failure<LookupItemResponse?>>());
      });
    });
  });
}

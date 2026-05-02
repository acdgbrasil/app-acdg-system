/// RED-phase tests for `AuditCache` (A17-v2).
///
/// `AuditCache` is the desktop-only Drift-backed Read Model for audit
/// trail entries scoped to a patient. Filtering by `eventType` is
/// supported via a B-Tree index. `limit`/`offset` provide pagination.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `findById(String entryId)`
///       → `Future<Result<AuditTrailEntryResponse?>>`
///   * `listByPatient(String patientId, {String? eventType, int? limit, int? offset})`
///       → `Future<Result<List<AuditTrailEntryResponse>>>` (B-Tree index)
///   * `upsert(String patientId, AuditTrailEntryResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `delete(String entryId)` → `Future<Result<void>>`
///   * `clear()` → `Future<Result<void>>`
///
/// `patientId` here is the cache scope (== aggregateId for registry-level
/// audits), but the audit DTO already carries `aggregateId` of its own
/// — they happen to match for patient-scoped audits. The cache stores
/// `patientId` as a separate column so we can index/filter; the full
/// DTO including `aggregateId` round-trips inside the JSON blob.
///
/// REGRA #2 note: `AuditTrailEntryResponse.payload` is a
/// `Map<String, dynamic>?` whose value-type is `dynamic`. Equatable's
/// equality does NOT recurse through dynamic — strict DTO equality on
/// payload fails for nested maps. Our tests assert field-by-field
/// roundtrip on the `payload` map (using `expect(map, equals(map))`,
/// which compares reference for nested values). If that proves flaky
/// in the implementer's hands they MUST flag rather than silently weaken.
///
/// IMPORTANT (RED phase): `AuditCache` and `DriftAuditCache` do NOT
/// exist yet. `import` lines fail — that is the intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/contracts/audit_cache.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/impls/drift_audit_cache.dart';

import '../_test_uuids.dart';
import '_test_db.dart';

void main() {
  group('AuditCache (Drift, in-memory)', () {
    late AuditCache cache;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemoryDatabase();
      cache = DriftAuditCache(database);
    });

    tearDown(() async {
      await safeClose(database);
    });

    AuditTrailEntryResponse entry({
      String id = kAuditUuid,
      String aggregateId = kPatientUuid,
      String eventType = 'PatientRegistered',
      String occurredAt = '2026-04-15T10:00:00.000Z',
      String recordedAt = '2026-04-15T10:00:01.000Z',
      Map<String, dynamic>? payload,
    }) {
      return AuditTrailEntryResponse(
        id: id,
        aggregateId: aggregateId,
        eventType: eventType,
        actorId: kMemberUuid,
        payload: payload ?? {'reason': 'initial'},
        occurredAt: occurredAt,
        recordedAt: recordedAt,
      );
    }

    test('implements AuditCache contract', () {
      expect(cache, isA<AuditCache>());
    });

    // ── upsert + findById ──────────────────────────────────────────────
    group('upsert + findById', () {
      test('round-trips full AuditTrailEntryResponse via JSON blob', () async {
        final dto = entry(
          payload: {'reason': 'admitted', 'sourceModule': 'registry'},
        );

        final upsert = await cache.upsert(kPatientUuid, dto, version: 1);
        expect(upsert, isA<Success<void>>());

        final found = await cache.findById(kAuditUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kAuditUuid));
            expect(value.aggregateId, equals(kPatientUuid));
            expect(value.eventType, equals('PatientRegistered'));
            expect(value.actorId, equals(kMemberUuid));
            expect(value.occurredAt, equals('2026-04-15T10:00:00.000Z'));
            expect(value.recordedAt, equals('2026-04-15T10:00:01.000Z'));
            expect(value.payload?['reason'], equals('admitted'));
            expect(value.payload?['sourceModule'], equals('registry'));
          case Failure():
            fail('expected Success');
        }
      });

      test('returns Success(null) when entry is missing', () async {
        final found = await cache.findById(kAuditUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNull);
          case Failure():
            fail('missing rows must be Success(null), not Failure');
        }
      });
    });

    // ── listByPatient ──────────────────────────────────────────────────
    group('listByPatient', () {
      test('returns empty list when no entries are cached', () async {
        final result = await cache.listByPatient(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });

      test('returns only entries for the requested patient', () async {
        await cache.upsert(kPatientUuid, entry(), version: 1);
        await cache.upsert(
          kPatientUuidAlt,
          entry(
            id: 'b5b5d6e7-f8a9-4012-bef0-123456789012',
            aggregateId: kPatientUuidAlt,
          ),
          version: 1,
        );

        final result = await cache.listByPatient(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.id, equals(kAuditUuid));
          case Failure():
            fail('expected Success');
        }
      });

      test(
        'filters by eventType (B-Tree index) — only matching rows',
        () async {
          await cache.upsert(
            kPatientUuid,
            entry(eventType: 'PatientRegistered'),
            version: 1,
          );
          await cache.upsert(
            kPatientUuid,
            entry(
              id: 'c5c5d6e7-f8a9-4012-bef0-123456789012',
              eventType: 'PatientDischarged',
            ),
            version: 1,
          );

          final result = await cache.listByPatient(
            kPatientUuid,
            eventType: 'PatientDischarged',
          );

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(1));
              expect(value.first.eventType, equals('PatientDischarged'));
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('honours `limit` parameter', () async {
        for (var i = 0; i < 5; i++) {
          await cache.upsert(
            kPatientUuid,
            entry(id: 'b4c5d6e7-f8a9-4012-bef0-12345678901$i'),
            version: 1,
          );
        }

        final result = await cache.listByPatient(kPatientUuid, limit: 2);

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
          case Failure():
            fail('expected Success');
        }
      });

      test('honours `offset` parameter', () async {
        for (var i = 0; i < 5; i++) {
          await cache.upsert(
            kPatientUuid,
            entry(id: 'b4c5d6e7-f8a9-4012-bef0-12345678902$i'),
            version: 1,
          );
        }

        // Skip first 2; expect <= 3 returned (DB ordering is impl-defined,
        // but count must equal total - offset, capped by limit if any).
        final result = await cache.listByPatient(kPatientUuid, offset: 2);

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(3));
          case Failure():
            fail('expected Success');
        }
      });

      test('combines limit + offset for pagination', () async {
        for (var i = 0; i < 5; i++) {
          await cache.upsert(
            kPatientUuid,
            entry(id: 'b4c5d6e7-f8a9-4012-bef0-12345678903$i'),
            version: 1,
          );
        }

        final result = await cache.listByPatient(
          kPatientUuid,
          limit: 2,
          offset: 2,
        );

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
          case Failure():
            fail('expected Success');
        }
      });
    });

    // ── delete + clear ─────────────────────────────────────────────────
    group('delete + clear', () {
      test('delete removes the entry; subsequent findById is null', () async {
        await cache.upsert(kPatientUuid, entry(), version: 1);

        final delete = await cache.delete(kAuditUuid);
        expect(delete, isA<Success<void>>());

        final found = await cache.findById(kAuditUuid);
        expect((found as Success).value, isNull);
      });

      test('delete on missing row is a no-op (Success)', () async {
        final result = await cache.delete(kAuditUuid);

        expect(result, isA<Success<void>>());
      });

      test('clear wipes the audit table', () async {
        await cache.upsert(kPatientUuid, entry(), version: 1);

        final clear = await cache.clear();
        expect(clear, isA<Success<void>>());

        final list = await cache.listByPatient(kPatientUuid);
        expect((list as Success).value, isEmpty);
      });
    });

    // ── DB-failure path ────────────────────────────────────────────────
    group('DB failure', () {
      test('returns Failure when underlying database is closed', () async {
        await database.close();

        final result = await cache.findById(kAuditUuid);

        expect(result, isA<Failure<AuditTrailEntryResponse?>>());
      });
    });
  });
}

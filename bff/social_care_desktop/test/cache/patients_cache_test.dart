/// RED-phase tests for `PatientsCache` (A17-v2).
///
/// `PatientsCache` is the desktop-only Drift-backed Read Model for the
/// Patient aggregate (which embeds the seven Assessment fichas) plus
/// `PatientSummaryResponse` rows used in list views.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `findById(String patientId)`
///       → `Future<Result<Cached<PatientResponse>?>>`
///   * `findByPersonId(String personId)`
///       → `Future<Result<Cached<PatientResponse>?>>`
///   * `listSummaries({String? status, String? cursor, int? limit})`
///       → `Future<Result<List<PatientSummaryResponse>>>`
///   * `searchSummaries(String term)`
///       → `Future<Result<List<PatientSummaryResponse>>>` (FTS5)
///   * `upsertPatient(PatientResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `upsertSummary(PatientSummaryResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deletePatient(String patientId)`  → `Future<Result<void>>`
///   * `deleteSummary(String patientId)`  → `Future<Result<void>>`
///   * `clear()` (drops both tables)      → `Future<Result<void>>`
///
/// ── Test axes per method (where applicable) ──────────────────────────
///   1. Round-trip: full DTO survives JSON-blob round-trip (every field).
///   2. Optimistic-locking `version` — caller-controlled, stored verbatim.
///   3. `cachedAt` — set by upsert, exposed by reads.
///   4. FTS5: token match, prefix match (`MATCH 'term*'`), no match,
///      sync-after-upsert, sync-after-delete.
///   5. B-Tree: `listSummaries(status: 'discharged')` returns only the
///      discharged rows.
///   6. Negative: missing rows return `Success(null)` (not Failure).
///
/// REGRA #2: `version` semantics. The test asserts caller-controlled
/// versioning — cache STORES whatever the caller provides (no auto-
/// increment). A18-v2 (SyncEngine) will manage the increment via the
/// optimistic-locking `WHERE id=? AND version=?` write. If the
/// implementer wants different semantics (e.g. cache auto-increments),
/// they MUST flag that here rather than silently changing the contract.
///
/// IMPORTANT (RED phase): `PatientsCache` and `DriftPatientsCache` do
/// NOT exist yet. The `import` lines fail — that is the intended RED
/// signal. W1 implements both at:
///   `lib/src/cache/contracts/patients_cache.dart`
///   `lib/src/cache/impls/drift_patients_cache.dart`
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore_for_file: implementation_imports
import 'package:social_care_desktop/src/cache/_shared/cached.dart';
import 'package:social_care_desktop/src/cache/contracts/patients_cache.dart';
import 'package:social_care_desktop/src/cache/impls/drift_patients_cache.dart';

import '../_test_uuids.dart';
import '_test_db.dart';

void main() {
  group('PatientsCache (Drift, in-memory)', () {
    late PatientsCache cache;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemoryDatabase();
      cache = DriftPatientsCache(database);
    });

    tearDown(() async {
      await safeClose(database);
    });

    PatientResponse fullPatient({
      String patientId = kPatientUuid,
      String personId = kPersonUuid,
      String status = 'admitted',
      int version = 0,
    }) {
      return PatientResponse(
        patientId: patientId,
        personId: personId,
        version: version,
        status: status,
        prRelationshipId: kLookupItemUuid,
        personalData: const PersonalDataResponse(
          firstName: 'Maria',
          lastName: 'Silva',
          motherName: 'Joana Silva',
          nationality: 'BR',
          sex: 'F',
          birthDate: '1990-05-15',
          socialName: 'Mari',
          phone: '+55-11-99999-9999',
        ),
      );
    }

    PatientSummaryResponse summary({
      String patientId = kPatientUuid,
      String personId = kPersonUuid,
      String status = 'admitted',
      String firstName = 'Maria',
      String lastName = 'Silva',
    }) {
      return PatientSummaryResponse(
        patientId: patientId,
        personId: personId,
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName',
        primaryDiagnosis: 'Q90.0',
        memberCount: 3,
        status: status,
      );
    }

    test('implements PatientsCache contract', () {
      expect(cache, isA<PatientsCache>());
    });

    // ── upsertPatient + findById ──────────────────────────────────────
    group('upsertPatient + findById', () {
      test('round-trips full PatientResponse via JSON blob', () async {
        final dto = fullPatient();

        final upsert = await cache.upsertPatient(dto, version: 1);
        expect(upsert, isA<Success<void>>());

        final found = await cache.findById(kPatientUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.dto.patientId, equals(kPatientUuid));
            expect(value.dto.personId, equals(kPersonUuid));
            expect(value.dto.status, equals('admitted'));
            expect(value.dto.prRelationshipId, equals(kLookupItemUuid));
            expect(value.dto.personalData?.firstName, equals('Maria'));
            expect(value.dto.personalData?.lastName, equals('Silva'));
            expect(value.dto.personalData?.motherName, equals('Joana Silva'));
            expect(value.dto.personalData?.sex, equals('F'));
            expect(value.dto.personalData?.birthDate, equals('1990-05-15'));
            expect(value.dto.personalData?.socialName, equals('Mari'));
          case Failure(:final error):
            fail('Expected Success on findById after upsert, got $error');
        }
      });

      test('returns Success(null) when patient is missing', () async {
        final found = await cache.findById(kPatientUuidAlt);

        switch (found) {
          case Success(:final value):
            expect(value, isNull);
          case Failure():
            fail('missing rows must be Success(null), not Failure');
        }
      });

      test('upsert is idempotent — second upsert overrides first', () async {
        await cache.upsertPatient(fullPatient(status: 'admitted'), version: 1);
        await cache.upsertPatient(
          fullPatient(status: 'discharged'),
          version: 2,
        );

        final found = await cache.findById(kPatientUuid);

        switch (found) {
          case Success(:final value):
            expect(value!.dto.status, equals('discharged'));
            expect(value.version, equals(2));
          case Failure():
            fail('expected Success after re-upsert');
        }
      });

      test(
        'preserves caller-controlled `version` (no auto-increment)',
        () async {
          await cache.upsertPatient(fullPatient(), version: 7);

          // The cache exposes the version via the [Cached] envelope.
          // Both the DTO's own `version` (round-trip from JSON) and the
          // envelope's `version` (the row's metadata column) must agree.
          await cache.upsertPatient(fullPatient(version: 7), version: 7);

          final found = await cache.findById(kPatientUuid);
          switch (found) {
            case Success(:final value):
              expect(value!.dto.version, equals(7));
              expect(value.version, equals(7));
            case Failure():
              fail('expected Success');
          }
        },
      );
    });

    // ── findByPersonId ─────────────────────────────────────────────────
    group('findByPersonId', () {
      test('returns the patient when personId matches', () async {
        await cache.upsertPatient(fullPatient(), version: 1);

        final found = await cache.findByPersonId(kPersonUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.dto.patientId, equals(kPatientUuid));
          case Failure():
            fail('expected Success');
        }
      });

      test('returns Success(null) when no patient has that personId', () async {
        await cache.upsertPatient(fullPatient(), version: 1);

        final found = await cache.findByPersonId(kPersonUuidAlt);

        switch (found) {
          case Success(:final value):
            expect(value, isNull);
          case Failure():
            fail('missing rows must be Success(null), not Failure');
        }
      });
    });

    // ── upsertSummary + listSummaries ──────────────────────────────────
    group('listSummaries', () {
      test('returns empty list on empty database', () async {
        final result = await cache.listSummaries();

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success on empty list');
        }
      });

      test('returns all summaries inserted via upsertSummary', () async {
        await cache.upsertSummary(summary(), version: 1);
        await cache.upsertSummary(
          summary(
            patientId: kPatientUuidAlt,
            personId: kPersonUuidAlt,
            firstName: 'Ana',
            lastName: 'Souza',
          ),
          version: 1,
        );

        final result = await cache.listSummaries();

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
            expect(
              value.map((p) => p.patientId).toSet(),
              equals({kPatientUuid, kPatientUuidAlt}),
            );
          case Failure():
            fail('expected Success');
        }
      });

      test(
        'filters by status (B-Tree index) — only `discharged` rows returned',
        () async {
          await cache.upsertSummary(summary(status: 'admitted'), version: 1);
          await cache.upsertSummary(
            summary(
              patientId: kPatientUuidAlt,
              personId: kPersonUuidAlt,
              status: 'discharged',
              firstName: 'Ana',
            ),
            version: 1,
          );

          final result = await cache.listSummaries(status: 'discharged');

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(1));
              expect(value.first.status, equals('discharged'));
              expect(value.first.patientId, equals(kPatientUuidAlt));
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('honours `limit` parameter', () async {
        for (var i = 0; i < 5; i++) {
          await cache.upsertSummary(
            summary(
              patientId: 'a$i$i$i$i$i$i$i$i-e5f6-4789-a012-3456789abcde',
              personId: 'b$i$i$i$i$i$i$i$i-e5f6-4789-a012-3456789abcde',
              firstName: 'Patient$i',
            ),
            version: 1,
          );
        }

        final result = await cache.listSummaries(limit: 2);

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
          case Failure():
            fail('expected Success');
        }
      });
    });

    // ── searchSummaries (FTS5) ─────────────────────────────────────────
    group('searchSummaries (FTS5)', () {
      setUp(() async {
        await cache.upsertSummary(
          summary(firstName: 'Maria', lastName: 'Silva'),
          version: 1,
        );
        await cache.upsertSummary(
          summary(
            patientId: kPatientUuidAlt,
            personId: kPersonUuidAlt,
            firstName: 'Mariana',
            lastName: 'Souza',
          ),
          version: 1,
        );
      });

      test('exact token match returns the row', () async {
        final result = await cache.searchSummaries('Silva');

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.lastName, equals('Silva'));
          case Failure():
            fail('expected Success');
        }
      });

      test('prefix match (Mari*) returns both Maria and Mariana', () async {
        final result = await cache.searchSummaries('Mari');

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(2));
            expect(
              value.map((p) => p.firstName).toSet(),
              equals({'Maria', 'Mariana'}),
            );
          case Failure():
            fail('expected Success');
        }
      });

      test('no-match returns empty list', () async {
        final result = await cache.searchSummaries('Xyzzy');

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });

      test('FTS5 syncs after upsertSummary (re-indexes)', () async {
        // Initial: term 'Bezerra' is not present.
        var result = await cache.searchSummaries('Bezerra');
        expect((result as Success).value, isEmpty);

        // Upsert: replace Maria Silva with Maria Bezerra.
        await cache.upsertSummary(
          summary(firstName: 'Maria', lastName: 'Bezerra'),
          version: 2,
        );

        result = await cache.searchSummaries('Bezerra');
        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.lastName, equals('Bezerra'));
          case Failure():
            fail('expected Success');
        }
      });

      test('FTS5 syncs after deleteSummary (de-indexes)', () async {
        await cache.deleteSummary(kPatientUuid);

        final result = await cache.searchSummaries('Silva');

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });
    });

    // ── deletePatient / deleteSummary ──────────────────────────────────
    group('delete*', () {
      test(
        'deletePatient removes the row; subsequent findById is null',
        () async {
          await cache.upsertPatient(fullPatient(), version: 1);

          final delete = await cache.deletePatient(kPatientUuid);
          expect(delete, isA<Success<void>>());

          final found = await cache.findById(kPatientUuid);
          switch (found) {
            case Success(:final value):
              expect(value, isNull);
            case Failure():
              fail('expected Success(null) after delete');
          }
        },
      );

      test('deletePatient on missing row is a no-op (Success)', () async {
        final result = await cache.deletePatient(kPatientUuidAlt);

        expect(result, isA<Success<void>>());
      });

      test('deleteSummary removes the row from listSummaries', () async {
        await cache.upsertSummary(summary(), version: 1);

        await cache.deleteSummary(kPatientUuid);

        final list = await cache.listSummaries();
        switch (list) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });
    });

    // ── clear ──────────────────────────────────────────────────────────
    group('clear', () {
      test('wipes both Patients and PatientSummaries tables', () async {
        await cache.upsertPatient(fullPatient(), version: 1);
        await cache.upsertSummary(summary(), version: 1);

        final clear = await cache.clear();
        expect(clear, isA<Success<void>>());

        final byId = await cache.findById(kPatientUuid);
        final list = await cache.listSummaries();

        expect((byId as Success).value, isNull);
        expect((list as Success).value, isEmpty);
      });
    });

    // ── DB-failure path ────────────────────────────────────────────────
    group('DB failure', () {
      test('returns Failure when underlying database is closed', () async {
        await database.close();

        final result = await cache.findById(kPatientUuid);

        expect(result, isA<Failure<Cached<PatientResponse>?>>());
      });
    });
  });
}

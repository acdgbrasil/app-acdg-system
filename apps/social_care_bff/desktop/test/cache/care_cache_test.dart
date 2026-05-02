/// RED-phase tests for `CareCache` (A17-v2).
///
/// `CareCache` is the desktop-only Drift-backed Read Model for the Care
/// aggregate — appointments scoped to a patient. Each row is one
/// `AppointmentResponse` keyed by `(patientId, appointmentId)`.
///
/// ── Surface under test ────────────────────────────────────────────────
///   * `findById(String patientId, String appointmentId)`
///       → `Future<Result<AppointmentResponse?>>`
///   * `listByPatient(String patientId, {int? limit})`
///       → `Future<Result<List<AppointmentResponse>>>` (B-Tree on patientId)
///   * `upsert(String patientId, AppointmentResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `delete(String patientId, String appointmentId)`
///       → `Future<Result<void>>`
///   * `clear()` → `Future<Result<void>>`
///
/// No FTS5: appointments are not free-text searchable in this MVP — the
/// cache exposes only patient-scoped listing. (Architect's call —
/// search-by-summary can be added in a future ticket if needed.)
///
/// IMPORTANT (RED phase): `CareCache` and `DriftCareCache` do NOT exist
/// yet. `import` lines fail — that is the intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/contracts/care_cache.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/impls/drift_care_cache.dart';

import '../_test_uuids.dart';
import '_test_db.dart';

void main() {
  group('CareCache (Drift, in-memory)', () {
    late CareCache cache;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemoryDatabase();
      cache = DriftCareCache(database);
    });

    tearDown(() async {
      await safeClose(database);
    });

    AppointmentResponse appointment({
      String id = kAppointmentUuid,
      String date = '2026-04-15',
      String type = 'first_visit',
      String summary = 'Initial intake',
      String actionPlan = 'Schedule HC follow-up',
    }) {
      return AppointmentResponse(
        id: id,
        date: date,
        professionalId: kProfessionalUuid,
        type: type,
        summary: summary,
        actionPlan: actionPlan,
      );
    }

    test('implements CareCache contract', () {
      expect(cache, isA<CareCache>());
    });

    // ── upsert + findById ─────────────────────────────────────────────
    group('upsert + findById', () {
      test('round-trips full AppointmentResponse via JSON blob', () async {
        final dto = appointment();

        final upsert = await cache.upsert(kPatientUuid, dto, version: 1);
        expect(upsert, isA<Success<void>>());

        final found = await cache.findById(kPatientUuid, kAppointmentUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kAppointmentUuid));
            expect(value.date, equals('2026-04-15'));
            expect(value.professionalId, equals(kProfessionalUuid));
            expect(value.type, equals('first_visit'));
            expect(value.summary, equals('Initial intake'));
            expect(value.actionPlan, equals('Schedule HC follow-up'));
          case Failure():
            fail('expected Success');
        }
      });

      test('returns Success(null) when appointment is missing', () async {
        final found = await cache.findById(kPatientUuid, kAppointmentUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNull);
          case Failure():
            fail('missing rows must be Success(null), not Failure');
        }
      });

      test('isolates appointments by patientId — same appointment id under '
          'different patient is a different row', () async {
        await cache.upsert(kPatientUuid, appointment(), version: 1);

        // Same id under another patient — must NOT collide.
        final foundUnderAlt = await cache.findById(
          kPatientUuidAlt,
          kAppointmentUuid,
        );
        switch (foundUnderAlt) {
          case Success(:final value):
            expect(value, isNull);
          case Failure():
            fail('expected isolation between patients');
        }
      });

      test('upsert is idempotent — second upsert overrides', () async {
        await cache.upsert(
          kPatientUuid,
          appointment(summary: 'first'),
          version: 1,
        );
        await cache.upsert(
          kPatientUuid,
          appointment(summary: 'second'),
          version: 2,
        );

        final found = await cache.findById(kPatientUuid, kAppointmentUuid);
        switch (found) {
          case Success(:final value):
            expect(value!.summary, equals('second'));
          case Failure():
            fail('expected Success');
        }
      });
    });

    // ── listByPatient ──────────────────────────────────────────────────
    group('listByPatient', () {
      test('returns empty list when no appointments are cached', () async {
        final result = await cache.listByPatient(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value, isEmpty);
          case Failure():
            fail('expected Success');
        }
      });

      test('returns only appointments for the requested patient', () async {
        await cache.upsert(kPatientUuid, appointment(), version: 1);
        await cache.upsert(
          kPatientUuidAlt,
          appointment(id: 'f1f2f3f4-c5d6-4789-a0bc-def012345678'),
          version: 1,
        );

        final result = await cache.listByPatient(kPatientUuid);

        switch (result) {
          case Success(:final value):
            expect(value, hasLength(1));
            expect(value.first.id, equals(kAppointmentUuid));
          case Failure():
            fail('expected Success');
        }
      });

      test('honours `limit` parameter', () async {
        for (var i = 0; i < 5; i++) {
          await cache.upsert(
            kPatientUuid,
            appointment(id: 'e1f2a3b4-c5d6-4789-a0bc-def00000000$i'),
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
    });

    // ── delete / clear ─────────────────────────────────────────────────
    group('delete + clear', () {
      test('delete removes the row; subsequent findById is null', () async {
        await cache.upsert(kPatientUuid, appointment(), version: 1);

        final delete = await cache.delete(kPatientUuid, kAppointmentUuid);
        expect(delete, isA<Success<void>>());

        final found = await cache.findById(kPatientUuid, kAppointmentUuid);
        expect((found as Success).value, isNull);
      });

      test('delete on missing row is a no-op (Success)', () async {
        final result = await cache.delete(kPatientUuid, kAppointmentUuid);

        expect(result, isA<Success<void>>());
      });

      test('clear wipes the appointments table', () async {
        await cache.upsert(kPatientUuid, appointment(), version: 1);
        await cache.upsert(
          kPatientUuidAlt,
          appointment(id: 'f1f2a3b4-c5d6-4789-a0bc-def012345678'),
          version: 1,
        );

        final clear = await cache.clear();
        expect(clear, isA<Success<void>>());

        final list = await cache.listByPatient(kPatientUuid);
        final listAlt = await cache.listByPatient(kPatientUuidAlt);

        expect((list as Success).value, isEmpty);
        expect((listAlt as Success).value, isEmpty);
      });
    });

    // ── DB-failure path ────────────────────────────────────────────────
    group('DB failure', () {
      test('returns Failure when underlying database is closed', () async {
        await database.close();

        final result = await cache.findById(kPatientUuid, kAppointmentUuid);

        expect(result, isA<Failure<AppointmentResponse?>>());
      });
    });
  });
}

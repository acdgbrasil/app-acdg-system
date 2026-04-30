/// RED-phase tests for `ProtectionCache` (A17-v2).
///
/// `ProtectionCache` covers three protection-context aggregates per
/// patient: Referrals, ViolationReports, and PlacementHistory.
/// PlacementHistory is one-per-patient (it's a single response object
/// holding multiple `PlacementRegistryResponse` entries internally), so
/// the cache stores it as a single row keyed by patientId.
///
/// ── Surface under test ────────────────────────────────────────────────
/// Referrals (per patient):
///   * `findReferralById(String patientId, String referralId)`
///       → `Future<Result<ReferralResponse?>>`
///   * `listReferrals(String patientId)`
///       → `Future<Result<List<ReferralResponse>>>`
///   * `upsertReferral(String patientId, ReferralResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deleteReferral(String patientId, String referralId)`
///       → `Future<Result<void>>`
///
/// ViolationReports (per patient):
///   * `findViolationReportById(String patientId, String reportId)`
///       → `Future<Result<ViolationReportResponse?>>`
///   * `listViolationReports(String patientId)`
///       → `Future<Result<List<ViolationReportResponse>>>`
///   * `upsertViolationReport(String patientId, ViolationReportResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deleteViolationReport(String patientId, String reportId)`
///       → `Future<Result<void>>`
///
/// PlacementHistory (one-per-patient):
///   * `findPlacementHistory(String patientId)`
///       → `Future<Result<PlacementHistoryResponse?>>`
///   * `upsertPlacementHistory(String patientId, PlacementHistoryResponse dto, {required int version})`
///       → `Future<Result<void>>`
///   * `deletePlacementHistory(String patientId)`
///       → `Future<Result<void>>`
///
/// Cross-cutting:
///   * `clear()` — wipes all three tables.
///
/// IMPORTANT (RED phase): `ProtectionCache` and `DriftProtectionCache`
/// do NOT exist yet. `import` lines fail — that is the intended RED
/// signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/contracts/protection_cache.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/cache/impls/drift_protection_cache.dart';

import '../_test_uuids.dart';
import '_test_db.dart';

void main() {
  group('ProtectionCache (Drift, in-memory)', () {
    late ProtectionCache cache;
    // ignore: prefer_typing_uninitialized_variables
    late var database;

    setUp(() {
      database = newInMemoryDatabase();
      cache = DriftProtectionCache(database);
    });

    tearDown(() async {
      await safeClose(database);
    });

    ReferralResponse referral({
      String id = kReferralUuid,
      String status = 'open',
    }) {
      return ReferralResponse(
        id: id,
        date: '2026-04-10',
        professionalId: kProfessionalUuid,
        referredPersonId: kPersonUuid,
        destinationService: 'CRAS Centro',
        reason: 'Documentation support',
        status: status,
      );
    }

    ViolationReportResponse violationReport({
      String id = kViolationReportUuid,
    }) {
      return ViolationReportResponse(
        id: id,
        reportDate: '2026-04-12',
        incidentDate: '2026-04-09',
        victimId: kPersonUuid,
        violationType: 'physical',
        descriptionOfFact: 'caregiver mistreatment',
        actionsTaken: 'Reported to Conselho Tutelar',
      );
    }

    PlacementHistoryResponse placement() {
      return PlacementHistoryResponse(
        individualPlacements: [
          PlacementRegistryResponse(
            id: kReferralUuid, // any UUID for the placement registry id
            memberId: kFamilyMemberUuid,
            startDate: '2026-04-01',
            endDate: '2026-04-20',
            reason: 'temporary shelter',
          ),
        ],
        homeLossReport: 'eviction in progress',
        thirdPartyGuardReport: null,
        adultInPrison: false,
        adolescentInInternment: true,
      );
    }

    test('implements ProtectionCache contract', () {
      expect(cache, isA<ProtectionCache>());
    });

    // ── Referrals ──────────────────────────────────────────────────────
    group('Referrals', () {
      test('upsert + findById round-trip', () async {
        final dto = referral();

        final upsert = await cache.upsertReferral(
          kPatientUuid,
          dto,
          version: 1,
        );
        expect(upsert, isA<Success<void>>());

        final found = await cache.findReferralById(kPatientUuid, kReferralUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kReferralUuid));
            expect(value.status, equals('open'));
            expect(value.destinationService, equals('CRAS Centro'));
            expect(value.referredPersonId, equals(kPersonUuid));
          case Failure():
            fail('expected Success');
        }
      });

      test('findReferralById returns Success(null) when missing', () async {
        final found = await cache.findReferralById(kPatientUuid, kReferralUuid);
        expect((found as Success).value, isNull);
      });

      test(
        'listReferrals returns only rows for the requested patient',
        () async {
          await cache.upsertReferral(kPatientUuid, referral(), version: 1);
          await cache.upsertReferral(
            kPatientUuidAlt,
            referral(id: 'f3a3b4c5-d6e7-4890-b1cd-ef0123456789'),
            version: 1,
          );

          final result = await cache.listReferrals(kPatientUuid);

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(1));
              expect(value.first.id, equals(kReferralUuid));
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('deleteReferral removes the row', () async {
        await cache.upsertReferral(kPatientUuid, referral(), version: 1);

        await cache.deleteReferral(kPatientUuid, kReferralUuid);

        final found = await cache.findReferralById(kPatientUuid, kReferralUuid);
        expect((found as Success).value, isNull);
      });

      test('deleteReferral on missing row is a no-op (Success)', () async {
        final result = await cache.deleteReferral(kPatientUuid, kReferralUuid);
        expect(result, isA<Success<void>>());
      });
    });

    // ── ViolationReports ───────────────────────────────────────────────
    group('ViolationReports', () {
      test('upsert + findById round-trip', () async {
        final dto = violationReport();

        await cache.upsertViolationReport(kPatientUuid, dto, version: 1);

        final found = await cache.findViolationReportById(
          kPatientUuid,
          kViolationReportUuid,
        );

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.id, equals(kViolationReportUuid));
            expect(value.reportDate, equals('2026-04-12'));
            expect(value.incidentDate, equals('2026-04-09'));
            expect(value.violationType, equals('physical'));
            expect(value.descriptionOfFact, equals('caregiver mistreatment'));
            expect(value.actionsTaken, equals('Reported to Conselho Tutelar'));
          case Failure():
            fail('expected Success');
        }
      });

      test(
        'findViolationReportById returns Success(null) when missing',
        () async {
          final found = await cache.findViolationReportById(
            kPatientUuid,
            kViolationReportUuid,
          );
          expect((found as Success).value, isNull);
        },
      );

      test(
        'listViolationReports returns only rows for the requested patient',
        () async {
          await cache.upsertViolationReport(
            kPatientUuid,
            violationReport(),
            version: 1,
          );
          await cache.upsertViolationReport(
            kPatientUuidAlt,
            violationReport(id: 'a4b4c5d6-e7f8-4901-9def-012345678901'),
            version: 1,
          );

          final result = await cache.listViolationReports(kPatientUuid);

          switch (result) {
            case Success(:final value):
              expect(value, hasLength(1));
              expect(value.first.id, equals(kViolationReportUuid));
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('deleteViolationReport removes the row', () async {
        await cache.upsertViolationReport(
          kPatientUuid,
          violationReport(),
          version: 1,
        );

        await cache.deleteViolationReport(kPatientUuid, kViolationReportUuid);

        final found = await cache.findViolationReportById(
          kPatientUuid,
          kViolationReportUuid,
        );
        expect((found as Success).value, isNull);
      });
    });

    // ── PlacementHistory ───────────────────────────────────────────────
    group('PlacementHistory', () {
      test('upsert + find round-trips full DTO', () async {
        final dto = placement();

        await cache.upsertPlacementHistory(kPatientUuid, dto, version: 1);

        final found = await cache.findPlacementHistory(kPatientUuid);

        switch (found) {
          case Success(:final value):
            expect(value, isNotNull);
            expect(value!.individualPlacements, hasLength(1));
            expect(
              value.individualPlacements.first.memberId,
              equals(kFamilyMemberUuid),
            );
            expect(value.homeLossReport, equals('eviction in progress'));
            expect(value.adultInPrison, isFalse);
            expect(value.adolescentInInternment, isTrue);
          case Failure():
            fail('expected Success');
        }
      });

      test('findPlacementHistory returns Success(null) when missing', () async {
        final found = await cache.findPlacementHistory(kPatientUuid);
        expect((found as Success).value, isNull);
      });

      test(
        'upsertPlacementHistory is idempotent — second upsert overrides',
        () async {
          await cache.upsertPlacementHistory(
            kPatientUuid,
            placement(),
            version: 1,
          );
          await cache.upsertPlacementHistory(
            kPatientUuid,
            const PlacementHistoryResponse(homeLossReport: 'updated report'),
            version: 2,
          );

          final found = await cache.findPlacementHistory(kPatientUuid);
          switch (found) {
            case Success(:final value):
              expect(value!.homeLossReport, equals('updated report'));
              expect(value.individualPlacements, isEmpty);
            case Failure():
              fail('expected Success');
          }
        },
      );

      test('deletePlacementHistory removes the row', () async {
        await cache.upsertPlacementHistory(
          kPatientUuid,
          placement(),
          version: 1,
        );

        await cache.deletePlacementHistory(kPatientUuid);

        final found = await cache.findPlacementHistory(kPatientUuid);
        expect((found as Success).value, isNull);
      });
    });

    // ── clear ──────────────────────────────────────────────────────────
    group('clear', () {
      test(
        'wipes referrals, violation reports, and placement histories',
        () async {
          await cache.upsertReferral(kPatientUuid, referral(), version: 1);
          await cache.upsertViolationReport(
            kPatientUuid,
            violationReport(),
            version: 1,
          );
          await cache.upsertPlacementHistory(
            kPatientUuid,
            placement(),
            version: 1,
          );

          final clear = await cache.clear();
          expect(clear, isA<Success<void>>());

          expect(
            ((await cache.listReferrals(kPatientUuid)) as Success).value,
            isEmpty,
          );
          expect(
            ((await cache.listViolationReports(kPatientUuid)) as Success).value,
            isEmpty,
          );
          expect(
            ((await cache.findPlacementHistory(kPatientUuid)) as Success).value,
            isNull,
          );
        },
      );
    });

    // ── DB-failure path ────────────────────────────────────────────────
    group('DB failure', () {
      test('returns Failure when underlying database is closed', () async {
        await database.close();

        final result = await cache.findReferralById(
          kPatientUuid,
          kReferralUuid,
        );

        expect(result, isA<Failure<ReferralResponse?>>());
      });
    });
  });
}

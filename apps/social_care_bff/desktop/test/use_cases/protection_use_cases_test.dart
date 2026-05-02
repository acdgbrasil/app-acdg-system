/// RED-phase tests for Protection use cases (A18b-v2).
///
/// 6 use cases:
///   Reads (3):
///     * `ListReferralsUseCase`         — by patientId.
///     * `ListViolationReportsUseCase`  — by patientId.
///     * `FetchPlacementHistoryUseCase` — single PlacementHistoryResponse
///                                        per patient.
///   Writes (3):
///     * `CreateReferralUseCase`        — register-style: expectedVersion 0.
///     * `ReportViolationUseCase`       — register-style: expectedVersion 0.
///     * `UpdatePlacementHistoryUseCase`— patient-aggregate write.
///
/// REGRA #2 lock: ProtectionContract does NOT expose list endpoints
/// (only mutating endpoints). Read use cases are cache-only — they
/// return cached data or `Success([])` on miss. If W1 wants to add
/// remote fallback, they MUST extend ProtectionContract first and
/// document the change.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/protection/...` do NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/list_referrals_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/list_violation_reports_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/fetch_placement_history_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/create_referral_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/report_violation_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/protection/update_placement_history_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  ReferralResponse referralFixture({String id = kReferralUuid}) =>
      ReferralResponse(
        id: id,
        date: '2026-04-30',
        referredPersonId: kPersonUuid,
        destinationService: 'CRAS Norte',
        reason: 'social_assistance',
        status: 'pending',
      );

  ViolationReportResponse violationFixture({String id = kViolationReportUuid}) =>
      ViolationReportResponse(
        id: id,
        reportDate: '2026-04-30',
        victimId: kFamilyMemberUuid,
        violationType: 'neglect',
        descriptionOfFact: 'Member untreated for 2 weeks',
        actionsTaken: 'Notified guardianship council',
      );

  PlacementHistoryResponse placementFixture() =>
      const PlacementHistoryResponse(
        adultInPrison: false,
        adolescentInInternment: false,
      );

  // ═════════════════════════════════════════════════════════════════════
  // READS (3) — cache-first, cache-only fallback when remote lacks endpoint
  // ═════════════════════════════════════════════════════════════════════

  group('ListReferralsUseCase (Pattern 1)', () {
    test('cache hit fresh returns referrals', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.protectionCache
          .upsertReferral(kPatientUuid, referralFixture(), version: 1);

      final useCase = ListReferralsUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<List<ReferralResponse>>>());
      expect((result as Success<List<ReferralResponse>>).value, hasLength(1));
    });

    test('cache miss returns empty list', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ListReferralsUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<List<ReferralResponse>>>());
      expect((result as Success<List<ReferralResponse>>).value, isEmpty);
    });
  });

  group('ListViolationReportsUseCase (Pattern 1)', () {
    test('cache hit fresh returns reports', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.protectionCache.upsertViolationReport(
          kPatientUuid, violationFixture(), version: 1);

      final useCase = ListViolationReportsUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(
          (result as Success<List<ViolationReportResponse>>).value, hasLength(1));
    });

    test('cache miss returns empty list', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ListViolationReportsUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(
          (result as Success<List<ViolationReportResponse>>).value, isEmpty);
    });
  });

  group('FetchPlacementHistoryUseCase (Pattern 1)', () {
    test('cache hit returns placement history', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.protectionCache.upsertPlacementHistory(
          kPatientUuid, placementFixture(), version: 1);

      final useCase = FetchPlacementHistoryUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<PlacementHistoryResponse?>>());
      expect((result as Success<PlacementHistoryResponse?>).value, isNotNull);
    });

    test('cache miss returns Success(null)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = FetchPlacementHistoryUseCase(
        cache: ctx.protectionCache,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<PlacementHistoryResponse?>>());
      expect((result as Success<PlacementHistoryResponse?>).value, isNull);
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // WRITES (3)
  // ═════════════════════════════════════════════════════════════════════

  group('CreateReferralUseCase (Pattern 2 — register-style)', () {
    const req = CreateReferralRequest(
      referredPersonId: kPersonUuid,
      destinationService: 'CRAS',
      reason: 'social_assistance',
    );

    test('happy path enqueues create_referral with expectedVersion 0',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = CreateReferralUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<StandardIdResponse>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'create_referral');
      expect(entry.expectedVersion, 0);
      expect(entry.aggregateType, 'referral');

      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('outbox enqueue failure propagates', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.syncDb.close();

      final useCase = CreateReferralUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Failure<StandardIdResponse>>());
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  group('ReportViolationUseCase (Pattern 2 — register-style)', () {
    const req = ReportRightsViolationRequest(
      victimId: kFamilyMemberUuid,
      violationType: 'neglect',
      descriptionOfFact: 'Untreated for 2 weeks',
    );

    test('happy path enqueues report_violation with expectedVersion 0',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ReportViolationUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<StandardIdResponse>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'report_violation');
      expect(entry.expectedVersion, 0);
      expect(entry.aggregateType, 'violation_report');
    });

    test('outbox failure propagates and engine NOT triggered', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.syncDb.close();

      final useCase = ReportViolationUseCase(
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Failure<StandardIdResponse>>());
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  group('UpdatePlacementHistoryUseCase (Pattern 2 — patient-aggregate)', () {
    const req = UpdatePlacementHistoryRequest();

    test('happy path enqueues update_placement_history with patient version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(
        PatientResponse(
          patientId: kPatientUuid,
          personId: kPersonUuid,
          version: 4,
          prRelationshipId: kRoleUuid,
        ),
        version: 4,
      );

      final useCase = UpdatePlacementHistoryUseCase(
        patientsCache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'update_placement_history');
      expect(entry.expectedVersion, 4);
      expect(entry.aggregateType, 'patient');
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdatePlacementHistoryUseCase(
        patientsCache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });
}

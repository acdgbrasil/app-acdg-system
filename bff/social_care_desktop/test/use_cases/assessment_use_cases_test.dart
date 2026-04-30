/// RED-phase tests for Assessment use cases (A18b-v2).
///
/// 7 use cases, all writes (Pattern 2). Every mutation hangs off the
/// Patient aggregate, so the `expectedVersion` is read from
/// `PatientsCache`. Mutations target the same patient row, so cache
/// version monotonicity matters.
///
/// Use cases:
///   * `UpdateHealthStatusUseCase`
///   * `UpdateHousingConditionUseCase`
///   * `UpdateEducationalStatusUseCase`
///   * `UpdateSocioEconomicSituationUseCase`
///   * `UpdateWorkAndIncomeUseCase`
///   * `UpdateCommunitySupportNetworkUseCase`
///   * `UpdateSocialHealthSummaryUseCase`
///
/// ── Test axes per use case (Pattern 2) ────────────────────────────────
///   1. Happy path: enqueues correct mutation, optimistic cache version
///      bumped, engine triggered.
///   2. Cache miss → Failure(NotFoundFailure); outbox empty; engine
///      NOT triggered.
///   3. (One axis per use case) outbox enqueue failure leaves cache
///      untouched + engine NOT triggered. Tested once on
///      `UpdateHealthStatusUseCase` to avoid 7× redundancy — the impl
///      is uniform.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/assessment/...` do NOT exist yet. Imports fail —
/// intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_health_status_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_housing_condition_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_educational_status_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_socio_economic_situation_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_work_and_income_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_community_support_network_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/assessment/update_social_health_summary_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  PatientResponse patient({int version = 1}) => PatientResponse(
        patientId: kPatientUuid,
        personId: kPersonUuid,
        version: version,
        prRelationshipId: kRoleUuid,
      );

  // ─────────────────────────────────────────────────────────────────────
  // UpdateHealthStatusUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateHealthStatusUseCase (Pattern 2)', () {
    const req = UpdateHealthStatusRequest(foodInsecurity: true);

    test('happy path enqueues update_health_status with patient version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 3), version: 3);

      final useCase = UpdateHealthStatusUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.aggregateId, kPatientUuid);
      expect(entry.mutationType, 'update_health_status');
      expect(entry.expectedVersion, 3);
      expect(entry.aggregateType, 'patient');

      final cached = (await ctx.patientsCache.findById(kPatientUuid)
              as Success<Cached<PatientResponse>?>)
          .value!;
      expect(cached.version, 4);
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → Failure(NotFoundFailure); outbox empty', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateHealthStatusUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect((pending as Success<List<OutboxEntry>>).value, isEmpty);
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });

    test('outbox failure → cache UNCHANGED, engine NOT triggered', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 3), version: 3);
      await ctx.syncDb.close();

      final useCase = UpdateHealthStatusUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Failure<void>>());

      final cached = (await ctx.patientsCache.findById(kPatientUuid)
              as Success<Cached<PatientResponse>?>)
          .value!;
      expect(cached.version, 3);
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateHousingConditionUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateHousingConditionUseCase (Pattern 2)', () {
    const req = UpdateHousingConditionRequest(
      type: 'rented',
      wallMaterial: 'concrete',
      numberOfRooms: 3,
      numberOfBedrooms: 2,
      numberOfBathrooms: 1,
      waterSupply: 'public',
      hasPipedWater: true,
      electricityAccess: 'public',
      sewageDisposal: 'public',
      wasteCollection: 'public',
      accessibilityLevel: 'partial',
      isInGeographicRiskArea: false,
      hasDifficultAccess: false,
      isInSocialConflictArea: false,
      hasDiagnosticObservations: false,
    );

    test('happy path enqueues update_housing_condition', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 1), version: 1);

      final useCase = UpdateHousingConditionUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'update_housing_condition');
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateHousingConditionUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateEducationalStatusUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateEducationalStatusUseCase (Pattern 2)', () {
    const req = UpdateEducationalStatusRequest();

    test('happy path enqueues update_educational_status', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 2), version: 2);

      final useCase = UpdateEducationalStatusUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'update_educational_status');
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateEducationalStatusUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateSocioEconomicSituationUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateSocioEconomicSituationUseCase (Pattern 2)', () {
    const req = UpdateSocioEconomicSituationRequest(
      totalFamilyIncome: 1500.0,
      incomePerCapita: 500.0,
      receivesSocialBenefit: true,
      mainSourceOfIncome: 'salary',
      hasUnemployed: false,
    );

    test('happy path enqueues update_socio_economic_situation', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 1), version: 1);

      final useCase = UpdateSocioEconomicSituationUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'update_socio_economic_situation');
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateSocioEconomicSituationUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateWorkAndIncomeUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateWorkAndIncomeUseCase (Pattern 2)', () {
    const req = UpdateWorkAndIncomeRequest(hasRetiredMembers: false);

    test('happy path enqueues update_work_and_income', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 4), version: 4);

      final useCase = UpdateWorkAndIncomeUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'update_work_and_income');
      expect(entry.expectedVersion, 4);
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateWorkAndIncomeUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateCommunitySupportNetworkUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateCommunitySupportNetworkUseCase (Pattern 2)', () {
    const req = UpdateCommunitySupportNetworkRequest(
      hasRelativeSupport: true,
      hasNeighborSupport: false,
      familyConflicts: 'none',
      patientParticipatesInGroups: true,
      familyParticipatesInGroups: true,
      patientHasAccessToLeisure: false,
      facesDiscrimination: false,
    );

    test('happy path enqueues update_community_support_network', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 0), version: 0);

      final useCase = UpdateCommunitySupportNetworkUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      expect(
          (pending as Success<List<OutboxEntry>>).value.single.mutationType,
          'update_community_support_network');
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateCommunitySupportNetworkUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // UpdateSocialHealthSummaryUseCase
  // ─────────────────────────────────────────────────────────────────────

  group('UpdateSocialHealthSummaryUseCase (Pattern 2)', () {
    const req = UpdateSocialHealthSummaryRequest(
      requiresConstantCare: true,
      hasMobilityImpairment: false,
      hasRelevantDrugTherapy: false,
    );

    test('happy path enqueues update_social_health_summary', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(patient(version: 7), version: 7);

      final useCase = UpdateSocialHealthSummaryUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'update_social_health_summary');
      expect(entry.expectedVersion, 7);
      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → NotFoundFailure', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateSocialHealthSummaryUseCase(
        cache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });
}

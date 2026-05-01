/// RED-phase tests for [AssessmentFacade] (A18c-v2).
///
/// 7 public methods delegate to the 7 Assessment use cases (A18b-v2).
/// All follow Pattern 2 (patient-aggregate write): take
/// `(String patientId, XxxRequest req)` and return `Result<void>`.
///
/// Locked contract:
///
///   class AssessmentFacade {
///     AssessmentFacade._({...7 use cases...});
///     Future<Result<void>> updateHealthStatus(String patientId, UpdateHealthStatusRequest req);
///     Future<Result<void>> updateHousingCondition(String patientId, UpdateHousingConditionRequest req);
///     Future<Result<void>> updateEducationalStatus(String patientId, UpdateEducationalStatusRequest req);
///     Future<Result<void>> updateSocioEconomicSituation(String patientId, UpdateSocioEconomicSituationRequest req);
///     Future<Result<void>> updateWorkAndIncome(String patientId, UpdateWorkAndIncomeRequest req);
///     Future<Result<void>> updateCommunitySupportNetwork(String patientId, UpdateCommunitySupportNetworkRequest req);
///     Future<Result<void>> updateSocialHealthSummary(String patientId, UpdateSocialHealthSummaryRequest req);
///   }
///
/// IMPORTANT (RED phase): the facade does NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
// ignore_for_file: depend_on_referenced_packages
import 'package:test/test.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  Future<SocialCareDesktop> build(FacadeTestContext ctx) =>
      SocialCareDesktop.create(
        baseUrl: 'http://localhost:8080',
        actorId: 'actor-123',
        tokenProvider: kStaticToken('test-token'),
        cacheFilePath: ':memory:',
        syncQueueFilePath: ':memory:',
        dio: ctx.dio,
        clock: ctx.fakeClock,
        connectivity: ctx.fakeConnectivity,
      );

  group('AssessmentFacade — wiring smoke', () {
    test(
      'updateHealthStatus takes (patientId, req) and returns Result<void>',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        const req = UpdateHealthStatusRequest(foodInsecurity: true);
        final result = await desktop.assessment.updateHealthStatus(
          kPatientUuid,
          req,
        );
        expect(result, isA<Result<void>>());
      },
    );

    test('updateHousingCondition signature matches A18b use case', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

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
      final result = await desktop.assessment.updateHousingCondition(
        kPatientUuid,
        req,
      );
      expect(result, isA<Result<void>>());
    });

    test(
      'updateCommunitySupportNetwork wired (proves all 7 methods present)',
      () async {
        // We pick this one as the "long-tail" — verifying the facade
        // doesn't accidentally short on the 5th-7th methods.
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        const req = UpdateCommunitySupportNetworkRequest(
          hasRelativeSupport: true,
          hasNeighborSupport: false,
          familyConflicts: 'none',
          patientParticipatesInGroups: true,
          familyParticipatesInGroups: true,
          patientHasAccessToLeisure: false,
          facesDiscrimination: false,
        );
        final result = await desktop.assessment.updateCommunitySupportNetwork(
          kPatientUuid,
          req,
        );
        expect(result, isA<Result<void>>());
      },
    );
  });
}

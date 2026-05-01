/// RED-phase tests for [ProtectionFacade] (A18c-v2).
///
/// 6 public methods delegate to the 6 Protection use cases (A18b-v2).
///
/// Locked contract:
///
///   class ProtectionFacade {
///     ProtectionFacade._({...6 use cases...});
///     Future<Result<StandardIdResponse>> createReferral(String patientId, CreateReferralRequest req);
///     Future<Result<List<ReferralResponse>>> listReferrals(String patientId);
///     Future<Result<StandardIdResponse>> reportViolation(String patientId, ReportRightsViolationRequest req);
///     Future<Result<List<ViolationReportResponse>>> listViolationReports(String patientId);
///     Future<Result<PlacementHistoryResponse?>> fetchPlacementHistory(String patientId);
///     Future<Result<void>> updatePlacementHistory(String patientId, UpdatePlacementHistoryRequest req);
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

  group('ProtectionFacade — wiring smoke (writes)', () {
    test('createReferral returns Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = CreateReferralRequest(
        referredPersonId: kPersonUuid,
        destinationService: 'CRAS',
        reason: 'social_assistance',
      );
      final result = await desktop.protection.createReferral(kPatientUuid, req);
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test('reportViolation returns Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = ReportRightsViolationRequest(
        victimId: kFamilyMemberUuid,
        violationType: 'neglect',
        descriptionOfFact: 'Untreated for 2 weeks',
      );
      final result = await desktop.protection.reportViolation(
        kPatientUuid,
        req,
      );
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test('updatePlacementHistory returns Result<void>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = UpdatePlacementHistoryRequest();
      final result = await desktop.protection.updatePlacementHistory(
        kPatientUuid,
        req,
      );
      expect(result, isA<Result<void>>());
    });
  });

  group('ProtectionFacade — wiring smoke (reads)', () {
    test('listReferrals returns Result<List<ReferralResponse>>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.protection.listReferrals(kPatientUuid);
      expect(result, isA<Result<List<ReferralResponse>>>());
    });

    test('fetchPlacementHistory returns Result<PlacementHistoryResponse?> '
        '(nullable for "not yet recorded")', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.protection.fetchPlacementHistory(
        kPatientUuid,
      );
      expect(result, isA<Result<PlacementHistoryResponse?>>());
    });
  });
}

/// RED-phase tests for [AuditFacade] (A18c-v2).
///
/// 1 public method delegates to the 1 Audit use case (A18b-v2).
///
/// Locked contract:
///
///   class AuditFacade {
///     AuditFacade._({required FetchAuditTrailUseCase fetchAuditTrail});
///     Future<Result<List<AuditTrailEntryResponse>>> fetchAuditTrail(
///       String patientId, {
///       String? eventType, int? limit, int? offset,
///     });
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

  group('AuditFacade — wiring smoke', () {
    test('fetchAuditTrail takes (patientId, {eventType, limit, offset}) and '
        'returns Result<List<AuditTrailEntryResponse>>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.audit.fetchAuditTrail(
        kPatientUuid,
        eventType: 'patient.discharged',
        limit: 20,
        offset: 0,
      );
      expect(result, isA<Result<List<AuditTrailEntryResponse>>>());
    });

    test(
      'fetchAuditTrail accepts only patientId (named params optional)',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        final result = await desktop.audit.fetchAuditTrail(kPatientUuid);
        expect(result, isA<Result<List<AuditTrailEntryResponse>>>());
      },
    );
  });
}

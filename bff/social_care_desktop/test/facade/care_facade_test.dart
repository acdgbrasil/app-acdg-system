/// RED-phase tests for [CareFacade] (A18c-v2).
///
/// 3 public methods delegate to the 3 Care use cases (A18b-v2).
///
/// Locked contract:
///
///   class CareFacade {
///     CareFacade._({...3 use cases...});
///     Future<Result<List<AppointmentResponse>>> listAppointments(String patientId, {int? limit});
///     Future<Result<StandardIdResponse>> registerAppointment(String patientId, RegisterAppointmentRequest req);
///     Future<Result<void>> updateIntakeInfo(String patientId, RegisterIntakeInfoRequest req);
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

  group('CareFacade — wiring smoke', () {
    test('listAppointments takes (patientId, {limit}) and returns '
        'Result<List<AppointmentResponse>>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      final result = await desktop.care.listAppointments(
        kPatientUuid,
        limit: 10,
      );
      expect(result, isA<Result<List<AppointmentResponse>>>());
    });

    test('registerAppointment takes (patientId, req) and returns '
        'Result<StandardIdResponse>', () async {
      final ctx = FacadeTestContext.fresh();
      addTearDown(ctx.close);
      final desktop = await build(ctx);
      addTearDown(desktop.close);

      const req = RegisterAppointmentRequest(
        professionalId: kProfessionalUuid,
        summary: 'First contact',
        actionPlan: 'Schedule home visit',
        date: '2026-05-01',
        type: 'home_visit',
      );
      final result = await desktop.care.registerAppointment(kPatientUuid, req);
      expect(result, isA<Result<StandardIdResponse>>());
    });

    test(
      'updateIntakeInfo takes (patientId, req) and returns Result<void>',
      () async {
        final ctx = FacadeTestContext.fresh();
        addTearDown(ctx.close);
        final desktop = await build(ctx);
        addTearDown(desktop.close);

        const req = RegisterIntakeInfoRequest(
          ingressTypeId: kLookupItemUuid,
          serviceReason: 'Initial intake',
        );
        final result = await desktop.care.updateIntakeInfo(kPatientUuid, req);
        expect(result, isA<Result<void>>());
      },
    );
  });
}

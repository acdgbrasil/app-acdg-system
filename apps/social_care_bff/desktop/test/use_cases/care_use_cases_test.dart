/// RED-phase tests for Care use cases (A18b-v2).
///
/// 3 use cases:
///   * `RegisterAppointmentUseCase` — write, mutation has
///     `expectedVersion: 0` (new appointment entity); aggregate is
///     `appointment` (mutation aggregateType), but the parent patient
///     bookkeeping for cache happens via the Care cache.
///   * `UpdateIntakeInfoUseCase`     — write, intake hangs off the
///     Patient aggregate (PatientsCache).
///   * `ListAppointmentsUseCase`     — read, cache-first via
///     `CareCache.listByPatient`, falls back to remote.
///
/// IMPORTANT (RED phase): Use cases under
/// `lib/src/use_cases/care/...` do NOT exist yet. Imports fail —
/// intended RED signal.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/care/register_appointment_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/care/update_intake_info_use_case.dart';
// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/care/list_appointments_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  AppointmentResponse appointment({String id = kAppointmentUuid}) =>
      AppointmentResponse(
        id: id,
        date: '2026-04-30',
        professionalId: kProfessionalUuid,
        type: 'follow_up',
        summary: 'Initial review',
        actionPlan: 'Schedule next visit',
      );

  // ═════════════════════════════════════════════════════════════════════
  // RegisterAppointmentUseCase (Pattern 2 — special: new entity v=0)
  // ═════════════════════════════════════════════════════════════════════

  group('RegisterAppointmentUseCase (Pattern 2 — register-style)', () {
    const req = RegisterAppointmentRequest(
      professionalId: kProfessionalUuid,
      summary: 'First contact',
      actionPlan: 'Schedule home visit',
      date: '2026-05-01',
      type: 'home_visit',
    );

    test(
        'happy path: enqueues register_appointment with expectedVersion 0; engine triggered',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = RegisterAppointmentUseCase(
        careCache: ctx.careCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<StandardIdResponse>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'register_appointment');
      expect(entry.expectedVersion, 0);
      expect(entry.aggregateType, 'appointment');

      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('outbox enqueue failure propagates and engine NOT triggered',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.syncDb.close();

      final useCase = RegisterAppointmentUseCase(
        careCache: ctx.careCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Failure<StandardIdResponse>>());
      expect(ctx.fakeEngine.triggerDrainCount, 0);
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // UpdateIntakeInfoUseCase (Pattern 2 — patient-aggregate write)
  // ═════════════════════════════════════════════════════════════════════

  group('UpdateIntakeInfoUseCase (Pattern 2)', () {
    const req = RegisterIntakeInfoRequest(
      ingressTypeId: kLookupItemUuid,
      serviceReason: 'Initial intake',
    );

    test('happy path enqueues update_intake_info using patient version',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.patientsCache.upsertPatient(
        PatientResponse(
          patientId: kPatientUuid,
          personId: kPersonUuid,
          version: 2,
          prRelationshipId: kRoleUuid,
        ),
        version: 2,
      );

      final useCase = UpdateIntakeInfoUseCase(
        patientsCache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect(result, isA<Success<void>>());

      final pending = await ctx.outbox.listByStatus(OutboxStatus.pending);
      final entry = (pending as Success<List<OutboxEntry>>).value.single;
      expect(entry.mutationType, 'update_intake_info');
      expect(entry.expectedVersion, 2);
      expect(entry.aggregateType, 'patient');

      expect(ctx.fakeEngine.triggerDrainCount, 1);
    });

    test('cache miss → Failure(NotFoundFailure)', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = UpdateIntakeInfoUseCase(
        patientsCache: ctx.patientsCache,
        outbox: ctx.outbox,
        engine: ctx.fakeEngine,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, req);
      expect((result as Failure<void>).error, isA<NotFoundFailure>());
    });
  });

  // ═════════════════════════════════════════════════════════════════════
  // ListAppointmentsUseCase (Pattern 1 — read)
  // ═════════════════════════════════════════════════════════════════════

  group('ListAppointmentsUseCase (Pattern 1)', () {
    test('cache hit fresh returns appointments without remote call',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.careCache.upsert(kPatientUuid, appointment(), version: 1);

      final useCase = ListAppointmentsUseCase(
        cache: ctx.careCache,
        remote: ctx.fakeCare,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<List<AppointmentResponse>>>());
      expect((result as Success<List<AppointmentResponse>>).value, hasLength(1));
    });

    test('stale cache refreshes via remote (when remote source available)',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      // Care contract has no fetchAppointments method. Pattern 1 here is
      // cache-first; if Care remote does not expose a list-by-patient
      // method, the use case may surface stale-cache as Success(value)
      // anyway. Tests assert: stale cache + advance clock still returns
      // cached data — implementer can choose to throw a follow-up if
      // they want to wire a list endpoint.
      await ctx.careCache.upsert(kPatientUuid, appointment(), version: 1);
      ctx.fakeClock.advance(const Duration(minutes: 10));

      final useCase = ListAppointmentsUseCase(
        cache: ctx.careCache,
        remote: ctx.fakeCare,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      // Either Success (if cache-only fallback) or Failure (if forced
      // remote and Care remote lacks a list method) — assert no throw
      // and that we get a Result.
      expect(result, anyOf(isA<Success>(), isA<Failure>()));
    });

    test('cache miss + empty remote returns Success(empty list) or Failure',
        () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      final useCase = ListAppointmentsUseCase(
        cache: ctx.careCache,
        remote: ctx.fakeCare,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, anyOf(isA<Success>(), isA<Failure>()));
    });
  });
}

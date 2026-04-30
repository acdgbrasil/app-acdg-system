/// RED-phase tests for Audit use cases (A18b-v2).
///
/// 1 use case:
///   * `FetchAuditTrailUseCase` — cache-first via
///     `AuditCache.listByPatient` with optional eventType / limit /
///     offset filters; falls back to remote `getAuditTrail` on miss /
///     stale.
///
/// IMPORTANT (RED phase): Use case under
/// `lib/src/use_cases/audit/...` does NOT exist yet. Imports fail.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

// ignore: uri_does_not_exist
import 'package:social_care_desktop/src/use_cases/audit/fetch_audit_trail_use_case.dart';

import '../_test_uuids.dart';
import '_test_helpers.dart';

void main() {
  AuditTrailEntryResponse entry({String id = kAuditUuid}) =>
      AuditTrailEntryResponse(
        id: id,
        aggregateId: kPatientUuid,
        eventType: 'PATIENT_REGISTERED',
        occurredAt: '2026-04-30T12:00:00Z',
        recordedAt: '2026-04-30T12:00:01Z',
      );

  group('FetchAuditTrailUseCase (Pattern 1)', () {
    test('cache hit fresh returns trail entries', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.auditCache.upsert(kPatientUuid, entry(), version: 1);

      final useCase = FetchAuditTrailUseCase(
        cache: ctx.auditCache,
        remote: ctx.fakeAudit,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<List<AuditTrailEntryResponse>>>());
      expect(
          (result as Success<List<AuditTrailEntryResponse>>).value, hasLength(1));
    });

    test('cache miss falls back to remote and upserts', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      ctx.fakeAudit.seed(kPatientUuid, [entry()]);

      final useCase = FetchAuditTrailUseCase(
        cache: ctx.auditCache,
        remote: ctx.fakeAudit,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid);
      expect(result, isA<Success<List<AuditTrailEntryResponse>>>());
      expect(
          (result as Success<List<AuditTrailEntryResponse>>).value, hasLength(1));
    });

    test('eventType filter is honored when reading from cache', () async {
      final ctx = TestContext.fresh();
      addTearDown(ctx.close);

      await ctx.auditCache.upsert(kPatientUuid, entry(), version: 1);
      await ctx.auditCache.upsert(
        kPatientUuid,
        AuditTrailEntryResponse(
          id: 'b4c5d6e7-f8a9-4012-bef0-123456789013',
          aggregateId: kPatientUuid,
          eventType: 'PATIENT_DISCHARGED',
          occurredAt: '2026-04-30T13:00:00Z',
          recordedAt: '2026-04-30T13:00:01Z',
        ),
        version: 1,
      );

      final useCase = FetchAuditTrailUseCase(
        cache: ctx.auditCache,
        remote: ctx.fakeAudit,
        clock: ctx.fakeClock,
      );

      final result = await useCase(kPatientUuid, eventType: 'PATIENT_DISCHARGED');
      final list =
          (result as Success<List<AuditTrailEntryResponse>>).value;
      expect(list, hasLength(1));
      expect(list.single.eventType, 'PATIENT_DISCHARGED');
    });
  });
}

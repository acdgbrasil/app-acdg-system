import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_audit_trail_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_audit_trail_use_case.dart';

import 'test_observability.dart';

/// Wave 0 RED for the new [GetAuditTrailUseCase].
///
/// Canonical query UseCase:
/// - `registry.audit_trail.get.received` — `patientId` + `hasEventTypeFilter`
///   + `hasPagination` booleans (NEVER the raw values).
/// - `registry.audit_trail.get.completed` — carries `count` (List length).
/// - `registry.audit_trail.get.failed` — carries `errorCode`.
///
/// The fake audit store does NOT apply filters today — the UseCase still
/// forwards them to the contract (pinned by `_CapturingAudit`).

/// Spy variant of [FakeAuditBff] that captures the arguments received.
class _CapturingAudit extends FakeAuditBff {
  String? capturedEventType;
  int? capturedLimit;
  int? capturedOffset;

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async {
    capturedEventType = eventType;
    capturedLimit = limit;
    capturedOffset = offset;
    return super.getAuditTrail(
      patientId,
      eventType: eventType,
      limit: limit,
      offset: offset,
    );
  }
}

/// Fake that forces the audit contract to fail.
class _FailingAudit extends FakeAuditBff {
  _FailingAudit(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<List<AuditTrailEntryResponse>>>> getAuditTrail(
    String patientId, {
    String? eventType,
    int? limit,
    int? offset,
  }) async => Failure(error);
}

AuditTrailEntryResponse _entry(String id) => AuditTrailEntryResponse(
  id: id,
  aggregateId: 'pat-1',
  eventType: 'PATIENT_REGISTERED',
  occurredAt: '2026-04-17T10:00:00Z',
  recordedAt: '2026-04-17T10:00:01Z',
);

void main() {
  group('GetAuditTrailUseCase', () {
    late FakeAuditBff fakeAudit;
    late ObservabilityContext obs;
    late GetAuditTrailUseCase useCase;

    setUp(() {
      fakeAudit = FakeAuditBff();
      obs = ObservabilityContext.noop();
      useCase = GetAuditTrailUseCase(audit: fakeAudit);
    });

    test('returns Success with empty list when nothing is seeded', () async {
      final result = await useCase.execute(
        const GetAuditTrailIntent(patientId: 'pat-1'),
        obs,
      );

      expect(
        result,
        isA<Success<StandardResponse<List<AuditTrailEntryResponse>>>>(),
      );
      switch (result) {
        case Success(:final value):
          expect(value.data, isEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns Success with seeded entries', () async {
      fakeAudit.seed('pat-1', [_entry('ev-1'), _entry('ev-2')]);

      final result = await useCase.execute(
        const GetAuditTrailIntent(patientId: 'pat-1'),
        obs,
      );

      switch (result) {
        case Success(:final value):
          expect(value.data, hasLength(2));
        case Failure():
          fail('Expected Success');
      }
    });

    test('forwards eventType + limit + offset to the audit contract', () async {
      final capturing = _CapturingAudit();
      final useCaseSpy = GetAuditTrailUseCase(audit: capturing);

      await useCaseSpy.execute(
        const GetAuditTrailIntent(
          patientId: 'pat-1',
          eventType: 'PATIENT_REGISTERED',
          limit: 25,
          offset: 10,
        ),
        obs,
      );

      expect(capturing.capturedEventType, equals('PATIENT_REGISTERED'));
      expect(capturing.capturedLimit, equals(25));
      expect(capturing.capturedOffset, equals(10));
    });

    group('observability canon', () {
      test(
        'emits registry.audit_trail.get.received with patientId + flags',
        () async {
          await useCase.execute(
            const GetAuditTrailIntent(
              patientId: 'pat-1',
              eventType: 'PATIENT_REGISTERED',
              limit: 10,
            ),
            obs,
          );

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.audit_trail.get.received', {
                'patientId': 'pat-1',
                'hasEventTypeFilter': true,
                'hasPagination': true,
              }),
            ),
          );
        },
      );

      test('emits registry.audit_trail.get.received with both flags=false when '
          'no filters are provided', () async {
        await useCase.execute(
          const GetAuditTrailIntent(patientId: 'pat-1'),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.audit_trail.get.received', {
              'patientId': 'pat-1',
              'hasEventTypeFilter': false,
              'hasPagination': false,
            }),
          ),
        );
      });

      test(
        'emits registry.audit_trail.get.completed with count on success',
        () async {
          fakeAudit.seed('pat-1', [_entry('ev-1'), _entry('ev-2')]);

          await useCase.execute(
            const GetAuditTrailIntent(patientId: 'pat-1'),
            obs,
          );

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.audit_trail.get.completed', {
                'count': 2,
              }),
            ),
          );
        },
      );

      test(
        'emits registry.audit_trail.get.completed with count=0 when empty',
        () async {
          await useCase.execute(
            const GetAuditTrailIntent(patientId: 'pat-1'),
            obs,
          );

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.audit_trail.get.completed', {
                'count': 0,
              }),
            ),
          );
        },
      );
    });

    group('failure path', () {
      test('propagates Failure when audit contract fails', () async {
        const error = BackendError(
          id: 'err-1',
          code: 'AUDIT_UNAVAILABLE',
          message: 'audit backend is down',
          http: 502,
        );
        final failing = _FailingAudit(error);
        final useCaseFail = GetAuditTrailUseCase(audit: failing);

        final result = await useCaseFail.execute(
          const GetAuditTrailIntent(patientId: 'pat-1'),
          obs,
        );

        expect(
          result,
          isA<Failure<StandardResponse<List<AuditTrailEntryResponse>>>>(),
        );
      });

      test(
        'emits registry.audit_trail.get.failed with errorCode on failure',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'AUDIT_UNAVAILABLE',
            message: 'audit backend is down',
            http: 502,
          );
          final failing = _FailingAudit(error);
          final useCaseFail = GetAuditTrailUseCase(audit: failing);

          await useCaseFail.execute(
            const GetAuditTrailIntent(patientId: 'pat-1'),
            obs,
          );

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.audit_trail.get.failed', {
                'errorCode': 'AUDIT_UNAVAILABLE',
              }),
            ),
          );
        },
      );
    });
  });
}

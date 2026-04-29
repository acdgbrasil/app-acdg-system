import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/report_rights_violation_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/report_rights_violation_use_case.dart';

import 'test_observability.dart';

/// Forces every call to [ProtectionContract.reportViolation] to fail with
/// the configured [BackendError]. Used to validate the failure-path breadcrumb.
class _FailingProtection extends FakeProtectionBff {
  _FailingProtection(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> reportViolation(
    String patientId,
    ReportRightsViolationRequest request,
  ) async => Failure(error);
}

const _request = ReportRightsViolationRequest(
  victimId: '660e8400-e29b-41d4-a716-446655440001',
  violationType: 'PHYSICAL',
  descriptionOfFact:
      'Marcas de agressao no braco esquerdo, relato de pai violento',
  violationTypeId: 'viol-phys',
  reportDate: '2026-04-17T10:00:00Z',
  incidentDate: '2026-04-14T00:00:00Z',
  actionsTaken: 'Comunicado Conselho Tutelar distrital',
);

const _intent = ReportRightsViolationIntent(
  patientId: 'pat-1',
  request: _request,
);

void main() {
  group('ReportRightsViolationUseCase', () {
    late FakeProtectionBff fakeProtection;
    late ObservabilityContext obs;
    late ReportRightsViolationUseCase useCase;

    setUp(() {
      fakeProtection = FakeProtectionBff();
      obs = ObservabilityContext.noop();
      useCase = ReportRightsViolationUseCase(protection: fakeProtection);
    });

    test('returns Success with StandardIdResponse on happy path', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardIdResponse>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.id, isNotEmpty);
        case Failure():
          fail('Expected Success');
      }
    });

    test('persists violation on the fake store (side-effect)', () async {
      await useCase.execute(_intent, obs);

      expect(fakeProtection.store.violations, hasLength(1));
      expect(
        fakeProtection.store.violations.first.victimId,
        equals('660e8400-e29b-41d4-a716-446655440001'),
      );
    });

    test(
      'emits protection.violation.report.received with patientId only',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.violation.report.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test('emits protection.violation.report.completed on success', () async {
      await useCase.execute(_intent, obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('protection.violation.report.completed')),
      );
    });

    test('.completed breadcrumb carries violationId (non-PII UUID)', () async {
      final result = await useCase.execute(_intent, obs);

      final expectedId = switch (result) {
        Success(:final value) => value.data.id,
        Failure() => fail('Expected Success'),
      };

      final completed = obs.breadcrumbs.firstWhere(
        (b) => b.event == 'protection.violation.report.completed',
      );
      expect(completed.data['violationId'], equals(expectedId));
    });

    test('propagates Failure when protection.reportViolation fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_VIOLATION_TYPE',
        message: 'violation type not recognized',
        http: 422,
      );
      final failing = _FailingProtection(error);
      final useCaseFail = ReportRightsViolationUseCase(protection: failing);

      final result = await useCaseFail.execute(_intent, obs);

      expect(result, isA<Failure<StandardIdResponse>>());
    });

    test(
      'emits protection.violation.report.failed on backend failure with errorCode',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_VIOLATION_TYPE',
          message: 'violation type not recognized',
          http: 422,
        );
        final failing = _FailingProtection(error);
        final useCaseFail = ReportRightsViolationUseCase(protection: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('protection.violation.report.failed', {
              'errorCode': 'INVALID_VIOLATION_TYPE',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumbs NEVER echo raw descriptionOfFact (PII — CRITICAL)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('agressao')),
            reason: 'descriptionOfFact fragments MUST NOT surface',
          );
          expect(
            dumped,
            isNot(contains('braco esquerdo')),
            reason: 'descriptionOfFact fragments MUST NOT surface',
          );
          expect(
            dumped,
            isNot(contains('pai violento')),
            reason: 'descriptionOfFact fragments MUST NOT surface',
          );
          expect(dumped, isNot(contains('Marcas de')));
        }
      },
    );

    test(
      'breadcrumbs NEVER echo raw actionsTaken (PII — intervention canon)',
      () async {
        await useCase.execute(_intent, obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('Conselho Tutelar')));
          expect(dumped, isNot(contains('Comunicado')));
          expect(dumped, isNot(contains('distrital')));
        }
      },
    );

    test('breadcrumbs NEVER echo violationType label', () async {
      await useCase.execute(_intent, obs);

      for (final record in obs.breadcrumbs) {
        final dumped = record.data.toString();
        // violationType is not high-sensitivity but still not a useful
        // breadcrumb key — prefer errorCode / ids. Pin it here so future
        // refactors don't silently reintroduce it.
        expect(dumped, isNot(contains('PHYSICAL')));
      }
    });
  });
}

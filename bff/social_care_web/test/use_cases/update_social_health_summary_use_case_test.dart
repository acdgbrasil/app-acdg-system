import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_social_health_summary_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_social_health_summary_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateSocialHealthSummary(
    String patientId,
    UpdateSocialHealthSummaryRequest request,
  ) async => Failure(error);
}

const _request = UpdateSocialHealthSummaryRequest(
  requiresConstantCare: true,
  hasMobilityImpairment: false,
  hasRelevantDrugTherapy: true,
);

void main() {
  group('UpdateSocialHealthSummaryUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateSocialHealthSummaryUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateSocialHealthSummaryUseCase(assessment: fakeAssessment);
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateSocialHealthSummaryIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits assessment.social_health_summary.update.received with patientId',
      () async {
        await useCase.execute(
          const UpdateSocialHealthSummaryIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData(
              'assessment.social_health_summary.update.received',
              {'patientId': 'pat-1'},
            ),
          ),
        );
      },
    );

    test(
      'emits assessment.social_health_summary.update.completed on success',
      () async {
        await useCase.execute(
          const UpdateSocialHealthSummaryIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEvent('assessment.social_health_summary.update.completed'),
          ),
        );
      },
    );

    test('propagates Failure when contract fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot update',
        http: 409,
      );
      final failing = _FailingAssessment(error);
      final useCaseFail = UpdateSocialHealthSummaryUseCase(assessment: failing);

      final result = await useCaseFail.execute(
        const UpdateSocialHealthSummaryIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.social_health_summary.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateSocialHealthSummaryUseCase(
          assessment: failing,
        );

        await useCaseFail.execute(
          const UpdateSocialHealthSummaryIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.social_health_summary.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );
  });
}

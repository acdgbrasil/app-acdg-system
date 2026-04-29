import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_work_and_income_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_work_and_income_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateWorkAndIncome(
    String patientId,
    UpdateWorkAndIncomeRequest request,
  ) async => Failure(error);
}

const _request = UpdateWorkAndIncomeRequest(hasRetiredMembers: false);

void main() {
  group('UpdateWorkAndIncomeUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateWorkAndIncomeUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateWorkAndIncomeUseCase(assessment: fakeAssessment);
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateWorkAndIncomeIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits assessment.work_and_income.update.received with patientId',
      () async {
        await useCase.execute(
          const UpdateWorkAndIncomeIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.work_and_income.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits assessment.work_and_income.update.completed on success',
      () async {
        await useCase.execute(
          const UpdateWorkAndIncomeIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(hasEvent('assessment.work_and_income.update.completed')),
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
      final useCaseFail = UpdateWorkAndIncomeUseCase(assessment: failing);

      final result = await useCaseFail.execute(
        const UpdateWorkAndIncomeIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.work_and_income.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateWorkAndIncomeUseCase(assessment: failing);

        await useCaseFail.execute(
          const UpdateWorkAndIncomeIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.work_and_income.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );
  });
}

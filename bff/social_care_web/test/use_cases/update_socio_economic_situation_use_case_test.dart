import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_socio_economic_situation_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_socio_economic_situation_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateSocioEconomicSituation(
    String patientId,
    UpdateSocioEconomicSituationRequest request,
  ) async => Failure(error);
}

const _request = UpdateSocioEconomicSituationRequest(
  totalFamilyIncome: 1500,
  incomePerCapita: 500,
  receivesSocialBenefit: true,
  mainSourceOfIncome: 'FORMAL_EMPLOYMENT',
  hasUnemployed: false,
);

void main() {
  group('UpdateSocioEconomicSituationUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateSocioEconomicSituationUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateSocioEconomicSituationUseCase(assessment: fakeAssessment);
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateSocioEconomicSituationIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits assessment.socio_economic.update.received with patientId',
      () async {
        await useCase.execute(
          const UpdateSocioEconomicSituationIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.socio_economic.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits assessment.socio_economic.update.completed on success',
      () async {
        await useCase.execute(
          const UpdateSocioEconomicSituationIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(hasEvent('assessment.socio_economic.update.completed')),
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
      final useCaseFail = UpdateSocioEconomicSituationUseCase(
        assessment: failing,
      );

      final result = await useCaseFail.execute(
        const UpdateSocioEconomicSituationIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.socio_economic.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateSocioEconomicSituationUseCase(
          assessment: failing,
        );

        await useCaseFail.execute(
          const UpdateSocioEconomicSituationIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.socio_economic.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );
  });
}

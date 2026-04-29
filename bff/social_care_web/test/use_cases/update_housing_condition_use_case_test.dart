import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_housing_condition_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_housing_condition_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateHousingCondition(
    String patientId,
    UpdateHousingConditionRequest request,
  ) async => Failure(error);
}

const _request = UpdateHousingConditionRequest(
  type: 'OWNED',
  wallMaterial: 'BRICK',
  numberOfRooms: 3,
  numberOfBedrooms: 2,
  numberOfBathrooms: 1,
  waterSupply: 'PUBLIC_NETWORK',
  hasPipedWater: true,
  electricityAccess: 'REGULAR',
  sewageDisposal: 'PUBLIC_NETWORK',
  wasteCollection: 'COLLECTED',
  accessibilityLevel: 'FULLY_ACCESSIBLE',
  isInGeographicRiskArea: false,
  hasDifficultAccess: false,
  isInSocialConflictArea: false,
  hasDiagnosticObservations: false,
);

void main() {
  group('UpdateHousingConditionUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateHousingConditionUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateHousingConditionUseCase(assessment: fakeAssessment);
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateHousingConditionIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits assessment.housing.update.received with patientId', () async {
      await useCase.execute(
        const UpdateHousingConditionIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('assessment.housing.update.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits assessment.housing.update.completed on success', () async {
      await useCase.execute(
        const UpdateHousingConditionIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('assessment.housing.update.completed')),
      );
    });

    test('propagates Failure when contract fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot update housing',
        http: 409,
      );
      final failing = _FailingAssessment(error);
      final useCaseFail = UpdateHousingConditionUseCase(assessment: failing);

      final result = await useCaseFail.execute(
        const UpdateHousingConditionIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.housing.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update housing',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateHousingConditionUseCase(assessment: failing);

        await useCaseFail.execute(
          const UpdateHousingConditionIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.housing.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );
  });
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_health_status_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_health_status_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateHealthStatus(
    String patientId,
    UpdateHealthStatusRequest request,
  ) async => Failure(error);
}

const _request = UpdateHealthStatusRequest(foodInsecurity: false);

void main() {
  group('UpdateHealthStatusUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateHealthStatusUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateHealthStatusUseCase(assessment: fakeAssessment);
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateHealthStatusIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits assessment.health_status.update.received with patientId',
      () async {
        await useCase.execute(
          const UpdateHealthStatusIntent(patientId: 'pat-1', request: _request),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.health_status.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits assessment.health_status.update.completed on success',
      () async {
        await useCase.execute(
          const UpdateHealthStatusIntent(patientId: 'pat-1', request: _request),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(hasEvent('assessment.health_status.update.completed')),
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
      final useCaseFail = UpdateHealthStatusUseCase(assessment: failing);

      final result = await useCaseFail.execute(
        const UpdateHealthStatusIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.health_status.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateHealthStatusUseCase(assessment: failing);

        await useCaseFail.execute(
          const UpdateHealthStatusIntent(patientId: 'pat-1', request: _request),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.health_status.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );

    test(
      'breadcrumb data does NOT contain responsibleCaregiverName (PII)',
      () async {
        const requestWithPii = UpdateHealthStatusRequest(
          foodInsecurity: false,
          deficiencies: [
            DeficiencyDraftDto(
              memberId: 'm-1',
              deficiencyTypeId: 'def-1',
              needsConstantCare: true,
              responsibleCaregiverName: 'Dona Maria da Silva',
            ),
          ],
        );

        await useCase.execute(
          const UpdateHealthStatusIntent(
            patientId: 'pat-1',
            request: requestWithPii,
          ),
          obs,
        );

        for (final b in obs.breadcrumbs) {
          final dump = b.data.toString();
          expect(
            dump,
            isNot(contains('Dona Maria')),
            reason: 'Breadcrumb must never carry caregiver given name',
          );
          expect(
            dump,
            isNot(contains('da Silva')),
            reason: 'Breadcrumb must never carry caregiver family name',
          );
        }
      },
    );
  });
}

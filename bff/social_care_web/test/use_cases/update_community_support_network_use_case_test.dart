import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/update_community_support_network_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/update_community_support_network_use_case.dart';

import 'test_observability.dart';

class _FailingAssessment extends FakeAssessmentBff {
  _FailingAssessment(this.error);
  final BackendError error;

  @override
  Future<Result<void>> updateCommunitySupportNetwork(
    String patientId,
    UpdateCommunitySupportNetworkRequest request,
  ) async => Failure(error);
}

const _request = UpdateCommunitySupportNetworkRequest(
  hasRelativeSupport: true,
  hasNeighborSupport: false,
  familyConflicts: 'NONE',
  patientParticipatesInGroups: true,
  familyParticipatesInGroups: false,
  patientHasAccessToLeisure: true,
  facesDiscrimination: false,
);

void main() {
  group('UpdateCommunitySupportNetworkUseCase', () {
    late FakeAssessmentBff fakeAssessment;
    late ObservabilityContext obs;
    late UpdateCommunitySupportNetworkUseCase useCase;

    setUp(() {
      fakeAssessment = FakeAssessmentBff();
      obs = ObservabilityContext.noop();
      useCase = UpdateCommunitySupportNetworkUseCase(
        assessment: fakeAssessment,
      );
    });

    test('returns Success when assessment contract accepts update', () async {
      final result = await useCase.execute(
        const UpdateCommunitySupportNetworkIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits assessment.community_support.update.received with patientId',
      () async {
        await useCase.execute(
          const UpdateCommunitySupportNetworkIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.community_support.update.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits assessment.community_support.update.completed on success',
      () async {
        await useCase.execute(
          const UpdateCommunitySupportNetworkIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(hasEvent('assessment.community_support.update.completed')),
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
      final useCaseFail = UpdateCommunitySupportNetworkUseCase(
        assessment: failing,
      );

      final result = await useCaseFail.execute(
        const UpdateCommunitySupportNetworkIntent(
          patientId: 'pat-1',
          request: _request,
        ),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits assessment.community_support.update.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot update',
          http: 409,
        );
        final failing = _FailingAssessment(error);
        final useCaseFail = UpdateCommunitySupportNetworkUseCase(
          assessment: failing,
        );

        await useCaseFail.execute(
          const UpdateCommunitySupportNetworkIntent(
            patientId: 'pat-1',
            request: _request,
          ),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('assessment.community_support.update.failed', {
              'errorCode': 'INVALID_STATE',
            }),
          ),
        );
      },
    );
  });
}

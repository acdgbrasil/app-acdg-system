import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/assign_primary_caregiver_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/assign_primary_caregiver_use_case.dart';

import 'test_observability.dart';

/// Wave 0 RED for the new [AssignPrimaryCaregiverUseCase].
///
/// Canonical simple UseCase:
/// - `registry.family.assign_caregiver.received` — `patientId`
/// - `registry.family.assign_caregiver.completed` — on success
/// - `registry.family.assign_caregiver.failed` — on error
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> assignPrimaryCaregiver(
    String patientId,
    AssignPrimaryCaregiverRequest request,
  ) async => Failure(error);
}

const _intent = AssignPrimaryCaregiverIntent(
  patientId: 'pat-1',
  request: AssignPrimaryCaregiverRequest(memberPersonId: 'per-42'),
);

void main() {
  group('AssignPrimaryCaregiverUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late AssignPrimaryCaregiverUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = AssignPrimaryCaregiverUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts the assignment', () async {
      final result = await useCase.execute(_intent, obs);

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test(
      'emits registry.family.assign_caregiver.received with patientId',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.family.assign_caregiver.received', {
              'patientId': 'pat-1',
            }),
          ),
        );
      },
    );

    test(
      'emits registry.family.assign_caregiver.completed on success',
      () async {
        await useCase.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('registry.family.assign_caregiver.completed')),
        );
      },
    );

    test(
      'propagates Failure when registry.assignPrimaryCaregiver fails',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'MEMBER_NOT_FOUND',
          message: 'caregiver candidate not in family',
          http: 404,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = AssignPrimaryCaregiverUseCase(registry: failing);

        final result = await useCaseFail.execute(_intent, obs);

        expect(result, isA<Failure<StandardResponse<void>>>());
      },
    );

    test(
      'emits registry.family.assign_caregiver.failed with errorCode on failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'MEMBER_NOT_FOUND',
          message: 'caregiver candidate not in family',
          http: 404,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = AssignPrimaryCaregiverUseCase(registry: failing);

        await useCaseFail.execute(_intent, obs);

        expect(
          obs.breadcrumbs,
          contains(
            hasEventWithData('registry.family.assign_caregiver.failed', {
              'errorCode': 'MEMBER_NOT_FOUND',
            }),
          ),
        );
      },
    );
  });
}

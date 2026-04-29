import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/withdraw_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/withdraw_patient_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> withdrawPatient(
    String patientId,
    WithdrawPatientRequest request,
  ) async => Failure(error);
}

const _request = WithdrawPatientRequest(reason: 'Family relocated');

void main() {
  group('WithdrawPatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late WithdrawPatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = WithdrawPatientUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts withdrawal', () async {
      final result = await useCase.execute(
        const WithdrawPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits registry.patient.withdraw.received with patientId', () async {
      await useCase.execute(
        const WithdrawPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.withdraw.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits registry.patient.withdraw.completed on success', () async {
      await useCase.execute(
        const WithdrawPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.withdraw.completed')),
      );
    });

    test('propagates Failure when registry.withdrawPatient fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot withdraw',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = WithdrawPatientUseCase(registry: failing);

      final result = await useCaseFail.execute(
        const WithdrawPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test('emits registry.patient.withdraw.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot withdraw',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = WithdrawPatientUseCase(registry: failing);

      await useCaseFail.execute(
        const WithdrawPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.withdraw.failed')),
      );
    });
  });
}

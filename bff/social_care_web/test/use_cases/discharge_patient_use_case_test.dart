import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/discharge_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/discharge_patient_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> dischargePatient(
    String patientId,
    DischargePatientRequest request,
  ) async => Failure(error);
}

const _request = DischargePatientRequest(reason: 'Treatment completed');

void main() {
  group('DischargePatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late DischargePatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = DischargePatientUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts discharge', () async {
      final result = await useCase.execute(
        const DischargePatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits registry.patient.discharge.received with patientId', () async {
      await useCase.execute(
        const DischargePatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.discharge.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits registry.patient.discharge.completed on success', () async {
      await useCase.execute(
        const DischargePatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.discharge.completed')),
      );
    });

    test('propagates Failure when registry.dischargePatient fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot discharge',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = DischargePatientUseCase(registry: failing);

      final result = await useCaseFail.execute(
        const DischargePatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test(
      'emits registry.patient.discharge.failed on backend failure',
      () async {
        const error = BackendError(
          id: 'err-1',
          code: 'INVALID_STATE',
          message: 'cannot discharge',
          http: 409,
        );
        final failing = _FailingRegistry(error);
        final useCaseFail = DischargePatientUseCase(registry: failing);

        await useCaseFail.execute(
          const DischargePatientIntent(patientId: 'pat-1', request: _request),
          obs,
        );

        expect(
          obs.breadcrumbs,
          contains(hasEvent('registry.patient.discharge.failed')),
        );
      },
    );
  });
}

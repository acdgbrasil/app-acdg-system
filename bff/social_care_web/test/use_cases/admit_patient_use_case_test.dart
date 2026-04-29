import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/admit_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/admit_patient_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> admitPatient(String patientId) async => Failure(error);
}

const _request = AdmitPatientRequest(
  reason: 'Triage approved',
  admittedAt: '2026-04-17T10:00:00Z',
);

void main() {
  group('AdmitPatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late AdmitPatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = AdmitPatientUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts admission', () async {
      final result = await useCase.execute(
        const AdmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits registry.patient.admit.received with patientId', () async {
      await useCase.execute(
        const AdmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.admit.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits registry.patient.admit.completed on success', () async {
      await useCase.execute(
        const AdmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.admit.completed')),
      );
    });

    test('propagates Failure when registry.admitPatient fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'patient already admitted',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = AdmitPatientUseCase(registry: failing);

      final result = await useCaseFail.execute(
        const AdmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test('emits registry.patient.admit.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'patient already admitted',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = AdmitPatientUseCase(registry: failing);

      await useCaseFail.execute(
        const AdmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.admit.failed')),
      );
    });
  });
}

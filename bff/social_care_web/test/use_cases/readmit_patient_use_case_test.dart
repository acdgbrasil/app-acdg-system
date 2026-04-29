import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/readmit_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/readmit_patient_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<void>> readmitPatient(
    String patientId,
    ReadmitPatientRequest request,
  ) async => Failure(error);
}

const _request = ReadmitPatientRequest(notes: 'Returned for follow-up');

void main() {
  group('ReadmitPatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late ObservabilityContext obs;
    late ReadmitPatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      obs = ObservabilityContext.noop();
      useCase = ReadmitPatientUseCase(registry: fakeRegistry);
    });

    test('returns Success when registry accepts readmission', () async {
      final result = await useCase.execute(
        const ReadmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Success<StandardResponse<void>>>());
    });

    test('emits registry.patient.readmit.received with patientId', () async {
      await useCase.execute(
        const ReadmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.readmit.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits registry.patient.readmit.completed on success', () async {
      await useCase.execute(
        const ReadmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.readmit.completed')),
      );
    });

    test('propagates Failure when registry.readmitPatient fails', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot readmit',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = ReadmitPatientUseCase(registry: failing);

      final result = await useCaseFail.execute(
        const ReadmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<void>>>());
    });

    test('emits registry.patient.readmit.failed on backend failure', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'INVALID_STATE',
        message: 'cannot readmit',
        http: 409,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = ReadmitPatientUseCase(registry: failing);

      await useCaseFail.execute(
        const ReadmitPatientIntent(patientId: 'pat-1', request: _request),
        obs,
      );

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.readmit.failed')),
      );
    });
  });
}

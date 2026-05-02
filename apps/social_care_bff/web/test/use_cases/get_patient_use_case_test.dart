import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/get_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/get_patient_use_case.dart';

import 'test_observability.dart';

class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;

  @override
  Future<Result<StandardResponse<PatientResponse>>> fetchPatient(
    String patientId,
  ) async => Failure(error);
}

void main() {
  group('GetPatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late FakePeopleBff fakePeople;
    late ObservabilityContext obs;
    late GetPatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      fakePeople = FakePeopleBff();
      obs = ObservabilityContext.noop();
      useCase = GetPatientUseCase(registry: fakeRegistry, people: fakePeople);
    });

    test('returns Success with the patient aggregate when found', () async {
      fakeRegistry.store.save(
        const PatientResponse(patientId: 'pat-1', personId: 'per-1'),
        const PatientSummaryResponse(patientId: 'pat-1', personId: 'per-1'),
      );

      final result = await useCase.execute(
        const GetPatientIntent(patientId: 'pat-1'),
        obs,
      );

      expect(result, isA<Success<StandardResponse<PatientResponse>>>());
      switch (result) {
        case Success(:final value):
          expect(value.data.patientId, equals('pat-1'));
        case Failure():
          fail('Expected Success');
      }
    });

    test('returns Failure when patient is not found', () async {
      final result = await useCase.execute(
        const GetPatientIntent(patientId: 'unknown'),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<PatientResponse>>>());
    });

    test('emits registry.patient.get.received with patientId', () async {
      await useCase.execute(const GetPatientIntent(patientId: 'pat-1'), obs);

      expect(
        obs.breadcrumbs,
        contains(
          hasEventWithData('registry.patient.get.received', {
            'patientId': 'pat-1',
          }),
        ),
      );
    });

    test('emits registry.patient.get.completed on success', () async {
      fakeRegistry.store.save(
        const PatientResponse(patientId: 'pat-1', personId: 'per-1'),
        const PatientSummaryResponse(patientId: 'pat-1', personId: 'per-1'),
      );

      await useCase.execute(const GetPatientIntent(patientId: 'pat-1'), obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.get.completed')),
      );
    });

    test('emits registry.patient.get.failed on missing patient', () async {
      await useCase.execute(const GetPatientIntent(patientId: 'unknown'), obs);

      expect(
        obs.breadcrumbs,
        contains(hasEvent('registry.patient.get.failed')),
      );
    });

    test('propagates Failure from RegistryContract.fetchPatient', () async {
      const error = BackendError(
        id: 'err-1',
        code: 'REGISTRY_UNAVAILABLE',
        message: 'backend down',
        http: 502,
      );
      final failing = _FailingRegistry(error);
      final useCaseFail = GetPatientUseCase(
        registry: failing,
        people: fakePeople,
      );

      final result = await useCaseFail.execute(
        const GetPatientIntent(patientId: 'pat-1'),
        obs,
      );

      expect(result, isA<Failure<StandardResponse<PatientResponse>>>());
    });

    test(
      'breadcrumbs NEVER carry raw patient personal data in get.completed',
      () async {
        fakeRegistry.store.save(
          const PatientResponse(
            patientId: 'pat-1',
            personId: 'per-1',
            personalData: PersonalDataResponse(
              firstName: 'Ana',
              lastName: 'Silva Santos',
              motherName: 'Marta Silva',
              nationality: 'BRA',
              sex: 'F',
              birthDate: '2018-05-10',
            ),
          ),
          const PatientSummaryResponse(
            patientId: 'pat-1',
            personId: 'per-1',
            fullName: 'Ana Silva Santos',
          ),
        );

        await useCase.execute(const GetPatientIntent(patientId: 'pat-1'), obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(dumped, isNot(contains('Ana Silva Santos')));
          expect(dumped, isNot(contains('Marta Silva')));
        }
      },
    );
  });
}

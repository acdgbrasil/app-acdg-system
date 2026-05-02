import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'package:social_care_web/src/intents/register_patient_intent.dart';
import 'package:social_care_web/src/observability/observability_context.dart';
import 'package:social_care_web/src/use_cases/register_patient_use_case.dart';

import 'test_observability.dart';

/// [RegistryContract] fake that forces [registerPatient] to fail.
///
/// Used to assert the saga does NOT attempt any `addFamilyMember` calls
/// once the core patient creation has failed.
class _FailingRegistry extends FakeRegistryBff {
  _FailingRegistry(this.error);
  final BackendError error;
  int addFamilyMemberCallCount = 0;

  @override
  Future<Result<StandardIdResponse>> registerPatient(
    RegisterPatientRequest request,
  ) async => Failure(error);

  @override
  Future<Result<void>> addFamilyMember(
    String patientId,
    AddFamilyMemberRequest request, {
    String? cpf,
  }) async {
    addFamilyMemberCallCount++;
    return const Success(null);
  }
}

/// [PeopleContract] fake that forces [registerPerson] to fail.
class _FailingPeople extends FakePeopleBff {
  _FailingPeople(this.error);
  final BackendError error;

  @override
  Future<Result<StandardIdResponse>> registerPerson(
    RegisterPersonRequest request,
  ) async => Failure(error);
}

/// Builds a happy-path RegisterPatientIntent with the main person only.
RegisterPatientIntent _intentSolo({String relationshipId = 'rel-self'}) {
  final request = RegisterPatientRequest(
    personId: '',
    prRelationshipId: relationshipId,
    initialDiagnoses: const <DiagnosisDraftDto>[],
    personalData: const PersonalDataDraftDto(
      firstName: 'Ana',
      lastName: 'Silva',
      motherName: 'Marta Silva',
      nationality: 'BRA',
      sex: 'F',
      birthDate: '2018-05-10',
    ),
    civilDocuments: const CivilDocumentsDraftDto(cpf: '11144477735'),
  );
  return RegisterPatientIntent(request: request);
}

void main() {
  group('RegisterPatientUseCase', () {
    late FakeRegistryBff fakeRegistry;
    late FakePeopleBff fakePeople;
    late ObservabilityContext obs;
    late RegisterPatientUseCase useCase;

    setUp(() {
      fakeRegistry = FakeRegistryBff();
      fakePeople = FakePeopleBff();
      obs = ObservabilityContext.noop();
      useCase = RegisterPatientUseCase(
        registry: fakeRegistry,
        people: fakePeople,
      );
    });

    group('happy path (patient only, no extra family members)', () {
      test('returns Success with the generated patient id', () async {
        final result = await useCase.execute(_intentSolo(), obs);

        expect(result, isA<Success<StandardIdResponse>>());
        switch (result) {
          case Success(:final value):
            expect(value.data.id, isNotEmpty);
          case Failure():
            fail('Expected Success');
        }
      });

      test('registers the principal person in the People Context', () async {
        await useCase.execute(_intentSolo(), obs);

        expect(fakePeople.store.people, isNotEmpty);
        expect(
          fakePeople.store.people.values.any((p) => p.cpf == '11144477735'),
          isTrue,
        );
      });

      test('persists the patient in the Registry store', () async {
        await useCase.execute(_intentSolo(), obs);

        expect(fakeRegistry.store.patients, hasLength(1));
      });
    });

    group('observability canon (A08 breadcrumbs)', () {
      test('emits registry.patient.register.received on dispatch', () async {
        await useCase.execute(_intentSolo(), obs);

        expect(
          obs.breadcrumbs,
          contains(hasEvent('registry.patient.register.received')),
        );
      });

      test(
        'emits registry.patient.register.people_context.reference_start',
        () async {
          await useCase.execute(_intentSolo(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEvent(
                'registry.patient.register.people_context.reference_start',
              ),
            ),
          );
        },
      );

      test(
        'emits registry.patient.register.social_care.patient_create',
        () async {
          await useCase.execute(_intentSolo(), obs);

          expect(
            obs.breadcrumbs,
            contains(
              hasEvent('registry.patient.register.social_care.patient_create'),
            ),
          );
        },
      );

      test(
        'emits registry.patient.register.completed with patientId data',
        () async {
          final result = await useCase.execute(_intentSolo(), obs);
          final patientId = switch (result) {
            Success(:final value) => value.data.id,
            Failure() => '',
          };

          expect(
            obs.breadcrumbs,
            contains(
              hasEventWithData('registry.patient.register.completed', {
                'patientId': patientId,
              }),
            ),
          );
        },
      );

      test('breadcrumbs NEVER carry raw CPF from the principal', () async {
        await useCase.execute(_intentSolo(), obs);

        for (final record in obs.breadcrumbs) {
          final dumped = record.data.toString();
          expect(
            dumped,
            isNot(contains('11144477735')),
            reason: 'Raw CPF must be masked in breadcrumbs (A08 PII canon)',
          );
        }
      });

      test(
        'breadcrumbs NEVER carry raw full name from the principal',
        () async {
          await useCase.execute(_intentSolo(), obs);

          for (final record in obs.breadcrumbs) {
            final dumped = record.data.toString();
            expect(dumped, isNot(contains('Ana Silva')));
            expect(dumped, isNot(contains('Marta Silva')));
          }
        },
      );
    });

    group('failure paths', () {
      test(
        'propagates Failure when People Context registration fails',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'PEOPLE_UNAVAILABLE',
            message: 'people context is down',
            http: 502,
          );
          final failingPeople = _FailingPeople(error);
          final useCaseFail = RegisterPatientUseCase(
            registry: fakeRegistry,
            people: failingPeople,
          );

          final result = await useCaseFail.execute(_intentSolo(), obs);

          expect(result, isA<Failure<StandardIdResponse>>());
        },
      );

      test(
        'emits registry.patient.register.failed on People Context failure',
        () async {
          const error = BackendError(
            id: 'err-1',
            code: 'PEOPLE_UNAVAILABLE',
            message: 'people context is down',
            http: 502,
          );
          final failingPeople = _FailingPeople(error);
          final useCaseFail = RegisterPatientUseCase(
            registry: fakeRegistry,
            people: failingPeople,
          );

          await useCaseFail.execute(_intentSolo(), obs);

          expect(
            obs.breadcrumbs,
            contains(hasEvent('registry.patient.register.failed')),
          );
        },
      );

      test(
        'propagates Failure when Registry.registerPatient fails (duplicate)',
        () async {
          const error = BackendError(
            id: 'err-2',
            code: 'PATIENT_DUPLICATE',
            message: 'patient already exists',
            http: 409,
          );
          final failingRegistry = _FailingRegistry(error);
          final useCaseFail = RegisterPatientUseCase(
            registry: failingRegistry,
            people: fakePeople,
          );

          final result = await useCaseFail.execute(_intentSolo(), obs);

          expect(result, isA<Failure<StandardIdResponse>>());
          switch (result) {
            case Success():
              fail('Expected Failure');
            case Failure(:final error):
              expect(error, isA<BackendError>());
              expect((error as BackendError).code, equals('PATIENT_DUPLICATE'));
          }
        },
      );

      test(
        'does NOT call addFamilyMember when registerPatient fails (no orphan calls)',
        () async {
          const error = BackendError(
            id: 'err-2',
            code: 'PATIENT_DUPLICATE',
            message: 'patient already exists',
            http: 409,
          );
          final failingRegistry = _FailingRegistry(error);
          final useCaseFail = RegisterPatientUseCase(
            registry: failingRegistry,
            people: fakePeople,
          );

          await useCaseFail.execute(_intentSolo(), obs);

          expect(failingRegistry.addFamilyMemberCallCount, equals(0));
        },
      );
    });
  });
}

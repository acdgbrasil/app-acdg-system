import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import '../../../testing/social_care_testing.dart';

void main() {
  late InMemoryPatientRepository repository;
  late Patient patient;

  setUp(() {
    repository = InMemoryPatientRepository();
    patient = PatientFixtures.validPatient;
    repository.registerPatient(patient);
  });

  group('Granular UseCases Integration', () {
    test('AddFamilyMemberUseCase should delegate to repository', () async {
      final useCase = AddFamilyMemberUseCase(patientRepository: repository);
      final intent = AddFamilyMemberIntent(
        patientId: patient.id,
        firstName: 'Familiar',
        lastName: 'Teste',
        relationshipId: '550e8400-e29b-41d4-a716-000000000010',
        birthDate: DateTime(1990, 1, 1),
        prRelationshipId: patient.prRelationshipId.value,
      );

      final result = await useCase.execute(intent);

      expect(result.isSuccess, isTrue);
      final getResult = await repository.getPatient(patient.id);
      if (getResult case Success(value: final updated)) {
        // Verify total members: 1 (auto-PR from registration) + 1 (new member)
        expect(updated.patientDetail.familyMembers.length, 2);
      } else {
        fail('Should have found patient');
      }
    });

    test(
      'UpdateHousingConditionUseCase should delegate to repository',
      () async {
        final useCase = UpdateHousingConditionUseCase(
          patientRepository: repository,
        );

        final intent = UpdateHousingConditionIntent(
          patientId: patient.id,
          type: ConditionType.owned,
          wallMaterial: WallMaterial.masonry,
          numberOfRooms: 4,
          numberOfBedrooms: 2,
          numberOfBathrooms: 1,
          waterSupply: WaterSupply.publicNetwork,
          hasPipedWater: true,
          electricityAccess: ElectricityAccess.meteredConnection,
          sewageDisposal: SewageDisposal.publicSewer,
          wasteCollection: WasteCollection.directCollection,
          accessibilityLevel: AccessibilityLevel.fullyAccessible,
          isInGeographicRiskArea: false,
          hasDifficultAccess: false,
          isInSocialConflictArea: false,
          hasDiagnosticObservations: false,
        );

        final result = await useCase.execute(intent);

        expect(result.isSuccess, isTrue);
        final getResult = await repository.getPatient(patient.id);
        if (getResult case Success(value: final updated)) {
          expect(updated.patientDetail.housingCondition?.type, equals(ConditionType.owned.name));
        } else {
          fail('Should have found patient');
        }
      },
    );

    test('UpdateSocialIdentityUseCase should delegate to repository', () async {
      final useCase = UpdateSocialIdentityUseCase(
        patientRepository: repository,
      );
      final identity = SocialIdentity.create(
        typeId: LookupId.create(
          '550e8400-e29b-41d4-a716-000000000001',
        ).valueOrNull!,
        otherDescription: 'Other',
        isOtherType: true,
      ).valueOrNull!;

      final intent = UpdateSocialIdentityIntent(
        patientId: patient.id,
        identity: identity,
      );

      final result = await useCase.execute(intent);

      expect(result.isSuccess, isTrue);
      final getResult = await repository.getPatient(patient.id);
      if (getResult case Success(value: final updated)) {
        expect(updated.patientDetail.socialIdentity?.typeId, equals(identity.typeId.value));
      } else {
        fail('Should have found patient');
      }
    });

    test('RegisterAppointmentUseCase should delegate to repository', () async {
      final useCase = RegisterAppointmentUseCase(patientRepository: repository);

      final intent = RegisterAppointmentIntent(
        patientId: patient.id,
        professionalId: '550e8400-e29b-41d4-a716-000000000002',
        type: AppointmentType.homeVisit,
        summary: 'Resumo',
        actionPlan: 'Plano',
        date: DateTime.now(),
      );

      final result = await useCase.execute(intent);

      expect(result.isSuccess, isTrue);
      if (result case Success(value: final val)) {
        expect(val, isNotNull);
      } else {
        fail('Should have returned success');
      }
    });
  });
}

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:social_care/social_care.dart';
import 'package:social_care/src/logic/mappers/assessment_mapper.dart';
import 'package:social_care/src/logic/mappers/family_mapper.dart';
import 'package:social_care/src/logic/mappers/intervention_mapper.dart';
import 'package:social_care/src/logic/mappers/registry_mapper.dart';

import '../../../testing/social_care_testing.dart';

void main() {
  final patientId = PatientFixtures.patientId;

  group('RegistryMapper', () {
    test(
      'toPatient should create a valid Patient with auto-added PR member',
      () {
        final intent = RegisterPatientIntent(
          firstName: 'Maria',
          lastName: 'Silva',
          motherName: 'Ana Silva',
          nationality: 'Brasileira',
          sex: Sex.feminino,
          birthDate: DateTime(1990, 5, 15),
          prRelationshipId: PatientFixtures.prRelationshipId.value,
          cpf: PatientFixtures.validCpf,
          city: 'São Paulo',
          addressState: 'SP',
          residenceLocation: ResidenceLocation.urbano,
          diagnoses: [PatientFixtures.diagnosis],
        );

        final result = RegistryMapper.toPatient(intent);

        expect(result.isSuccess, isTrue);
        final patient = result.valueOrNull!;
        expect(patient.familyMembers, hasLength(1));
        expect(patient.familyMembers.first.isPrimaryCaregiver, isTrue);
        expect(patient.personalData?.firstName, 'Maria');
      },
    );
  });

  group('FamilyMapper', () {
    test(
      'toFamilyMember should create a valid FamilyMember with new personId',
      () {
        final intent = AddFamilyMemberIntent(
          patientId: patientId,
          firstName: 'Jose',
          lastName: 'Silva',
          relationshipId: PatientFixtures.prRelationshipId.value,
          birthDate: DateTime(1980, 1, 1),
          prRelationshipId: PatientFixtures.prRelationshipId.value,
        );

        final result = FamilyMapper.toFamilyMember(intent);

        expect(result.isSuccess, isTrue);
        final member = result.valueOrNull!;
        expect(member.personId.value, isNotEmpty);
        expect(member.isPrimaryCaregiver, isFalse);
      },
    );
  });

  group('AssessmentMapper', () {
    test('toHousingCondition should map correctly', () {
      final intent = UpdateHousingConditionIntent(
        patientId: patientId,
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

      final result = AssessmentMapper.toHousingCondition(intent);

      expect(result.isSuccess, isTrue);
      final condition = result.valueOrNull!;
      expect(condition.type, ConditionType.owned);
      expect(condition.numberOfRooms, 4);
    });

    test('toSocioEconomic should fail on duplicate benefits', () {
      final benefit = SocialBenefit.create(
        benefitName: 'BPC',
        benefitTypeId: PatientFixtures.prRelationshipId,
        amount: 1000,
        beneficiaryId: PatientFixtures.personId,
      ).valueOrNull!;

      final intent = UpdateSocioEconomicIntent(
        patientId: patientId,
        totalFamilyIncome: 1000,
        incomePerCapita: 500,
        receivesSocialBenefit: true,
        socialBenefits: [benefit, benefit], // DUPLICATE
        mainSourceOfIncome: 'Trabalho',
        hasUnemployed: false,
      );

      final result = AssessmentMapper.toSocioEconomic(intent);

      expect(result.isFailure, isTrue);
      expect((result as Failure).error.toString(), contains('SBC-002'));
    });
  });

  group('InterventionMapper', () {
    test('toAppointment should generate valid domain object', () {
      final intent = RegisterAppointmentIntent(
        patientId: patientId,
        professionalId: '550e8400-e29b-41d4-a716-000000000002',
        type: AppointmentType.homeVisit,
        summary: 'Resumo teste',
        actionPlan: 'Plano teste',
        date: DateTime.now(),
      );

      final result = InterventionMapper.toAppointment(intent);

      expect(result.isSuccess, isTrue);
      final appointment = result.valueOrNull!;
      expect(appointment.summary, 'Resumo teste');
      expect(appointment.professionalInChargeId.value, intent.professionalId);
    });

    test('toViolationReport should map incident date correctly', () {
      final incidentDate = DateTime(2024, 1, 1);
      final intent = ReportViolationIntent(
        patientId: patientId,
        victimId: PatientFixtures.personId.value,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Descrição detalhada',
        incidentDate: incidentDate,
      );

      final result = InterventionMapper.toViolationReport(intent);

      expect(result.isSuccess, isTrue);
      final report = result.valueOrNull!;
      expect(report.incidentDate?.year, 2024);
      expect(report.violationType, ViolationType.neglect);
    });
  });
}

import 'package:social_care_bff/social_care_bff.dart';
import 'package:test/test.dart';

void main() {
  group('SocialCareApiClient parsers', () {
    // We test the parsers indirectly through the public API.
    // Full integration tests require a running API server.
    // These tests verify model construction correctness.

    test('Patient model can be constructed with all fields', () {
      const patient = Patient(
        patientId: 'p-1',
        personId: 'person-1',
        version: 3,
        personalData: PersonalData(firstName: 'Ana', lastName: 'Souza'),
        civilDocuments: CivilDocuments(cpf: Cpf('12345678901')),
        address: Address(city: 'São Paulo', state: 'SP'),
        socialIdentity: SocialIdentity(typeId: 'type-1'),
        familyMembers: [
          FamilyMember(
            personId: 'fm-1',
            relationshipId: 'rel-1',
            isPrimaryCaregiver: true,
            residesWithPatient: true,
            hasDisability: false,
            requiredDocuments: ['RG'],
          ),
        ],
        diagnoses: [Diagnosis(icdCode: 'Q87.1', description: 'Marfan')],
        housingCondition: HousingCondition(
          type: 'propria',
          wallMaterial: 'alvenaria',
          numberOfRooms: 4,
          numberOfBedrooms: 2,
          numberOfBathrooms: 1,
          waterSupply: 'rede_publica',
          hasPipedWater: true,
          electricityAccess: 'rede_publica',
          sewageDisposal: 'rede_coletora',
          wasteCollection: 'coleta_publica',
          accessibilityLevel: 'total',
          isInGeographicRiskArea: false,
          hasDifficultAccess: false,
          isInSocialConflictArea: false,
          hasDiagnosticObservations: false,
        ),
        appointments: [Appointment(id: 'app-1', professionalId: 'prof-1')],
        referrals: [
          Referral(
            id: 'ref-1',
            referredPersonId: 'rp-1',
            destinationService: 'CREAS',
            reason: 'Proteção',
          ),
        ],
        violationReports: [
          ViolationReport(
            id: 'vr-1',
            victimId: 'v-1',
            violationType: 'negligencia',
            descriptionOfFact: 'Fato',
          ),
        ],
        computedAnalytics: ComputedAnalytics(
          housing: HousingAnalytics(density: 2.0, isOvercrowded: false),
          financial: FinancialAnalytics(totalWorkIncome: 3000),
          ageProfile: AgeProfile(range0to6: 1, totalMembers: 5),
          educationalVulnerabilities: EducationalVulnerabilities(
            notInSchool6to14: 0,
          ),
        ),
      );

      expect(patient.patientId, 'p-1');
      expect(patient.personalData!.fullName, 'Ana Souza');
      expect(patient.civilDocuments!.cpf!.value, '12345678901');
      expect(patient.familyMembers, hasLength(1));
      expect(patient.familyMembers.first.isPrimaryCaregiver, isTrue);
      expect(patient.housingCondition!.type, 'propria');
      expect(patient.computedAnalytics.housing!.isOvercrowded, isFalse);
      expect(patient.computedAnalytics.ageProfile!.totalMembers, 5);
    });

    test('AuditEvent equality by id', () {
      final e1 = AuditEvent(
        id: 'evt-1',
        aggregateId: 'agg-1',
        eventType: 'PatientCreated',
        payload: const {'key': 'value'},
        occurredAt: DateTime(2024),
        recordedAt: DateTime(2024),
      );
      final e2 = AuditEvent(
        id: 'evt-1',
        aggregateId: 'agg-2',
        eventType: 'Other',
        payload: const {},
        occurredAt: DateTime(2025),
        recordedAt: DateTime(2025),
      );

      expect(e1, equals(e2));
    });

    test('PlacementHistory with registries', () {
      const history = PlacementHistory(
        individualPlacements: [
          PlacementRegistry(id: 'pl-1', memberId: 'm-1', reason: 'Acolhimento'),
        ],
        adultInPrison: false,
        adolescentInInternment: true,
      );

      expect(history.individualPlacements, hasLength(1));
      expect(history.adolescentInInternment, isTrue);
    });

    test('IntakeInfo with program links', () {
      const info = IntakeInfo(
        ingressTypeId: 'type-1',
        serviceReason: 'Demanda espontânea',
        linkedSocialPrograms: [
          ProgramLink(programId: 'prog-1', observation: 'BPC ativo'),
        ],
      );

      expect(info.linkedSocialPrograms, hasLength(1));
      expect(info.linkedSocialPrograms.first.observation, 'BPC ativo');
    });
  });
}

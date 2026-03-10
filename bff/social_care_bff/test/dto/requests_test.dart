import 'package:social_care_bff/social_care_bff.dart';
import 'package:test/test.dart';

void main() {
  group('RegisterPatientRequest.toJson', () {
    test('minimal required fields', () {
      const request = RegisterPatientRequest(
        personId: 'person-1',
        initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
        prRelationshipId: 'rel-1',
      );

      final json = request.toJson();

      expect(json['personId'], 'person-1');
      expect(json['prRelationshipId'], 'rel-1');
      expect(json['initialDiagnoses'], hasLength(1));
      expect(json.containsKey('personalData'), isFalse);
    });

    test('includes optional personalData', () {
      const request = RegisterPatientRequest(
        personId: 'person-1',
        initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
        prRelationshipId: 'rel-1',
        personalData: PersonalDataDto(
          firstName: 'Maria',
          lastName: 'Silva',
          sex: 'female',
        ),
      );

      final json = request.toJson();

      expect(json.containsKey('personalData'), isTrue);
      final pd = json['personalData'] as Map<String, dynamic>;
      expect(pd['firstName'], 'Maria');
      expect(pd['sex'], 'female');
    });
  });

  group('AddFamilyMemberRequest.toJson', () {
    test('serializes all fields', () {
      final request = AddFamilyMemberRequest(
        memberPersonId: 'm-1',
        relationship: 'filho',
        isResiding: true,
        isCaregiver: false,
        hasDisability: true,
        requiredDocuments: const ['RG', 'CPF'],
        birthDate: DateTime(2020, 6, 15),
        prRelationshipId: 'rel-1',
      );

      final json = request.toJson();

      expect(json['memberPersonId'], 'm-1');
      expect(json['relationship'], 'filho');
      expect(json['isResiding'], isTrue);
      expect(json['hasDisability'], isTrue);
      expect(json['requiredDocuments'], ['RG', 'CPF']);
    });
  });

  group('UpdateHousingConditionRequest.toJson', () {
    test('serializes all fields', () {
      const request = UpdateHousingConditionRequest(
        type: 'propria',
        wallMaterial: 'alvenaria',
        numberOfRooms: 5,
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
        hasDiagnosticObservations: true,
      );

      final json = request.toJson();

      expect(json['type'], 'propria');
      expect(json['numberOfRooms'], 5);
      expect(json['hasPipedWater'], isTrue);
      expect(json['hasDiagnosticObservations'], isTrue);
      expect(json.length, 15);
    });
  });

  group('RegisterAppointmentRequest.toJson', () {
    test('minimal fields', () {
      const request = RegisterAppointmentRequest(professionalId: 'prof-1');

      final json = request.toJson();

      expect(json['professionalId'], 'prof-1');
      expect(json.containsKey('summary'), isFalse);
      expect(json.containsKey('date'), isFalse);
    });

    test('with all optional fields', () {
      final request = RegisterAppointmentRequest(
        professionalId: 'prof-1',
        summary: 'Atendimento inicial',
        actionPlan: 'Encaminhar para CREAS',
        type: 'visita_domiciliar',
        date: DateTime(2024, 3, 15),
      );

      final json = request.toJson();

      expect(json['summary'], 'Atendimento inicial');
      expect(json['type'], 'visita_domiciliar');
      expect(json.containsKey('date'), isTrue);
    });
  });

  group('CreateReferralRequest.toJson', () {
    test('required fields only', () {
      const request = CreateReferralRequest(
        referredPersonId: 'ref-1',
        destinationService: 'CREAS',
        reason: 'Proteção social especial',
      );

      final json = request.toJson();

      expect(json['referredPersonId'], 'ref-1');
      expect(json['destinationService'], 'CREAS');
      expect(json['reason'], 'Proteção social especial');
      expect(json.containsKey('professionalId'), isFalse);
    });
  });

  group('ReportRightsViolationRequest.toJson', () {
    test('serializes required and optional fields', () {
      final request = ReportRightsViolationRequest(
        victimId: 'victim-1',
        violationType: 'negligencia',
        descriptionOfFact: 'Descrição do fato',
        reportDate: DateTime(2024, 1, 10),
        actionsTaken: 'Encaminhamento ao CREAS',
      );

      final json = request.toJson();

      expect(json['victimId'], 'victim-1');
      expect(json['descriptionOfFact'], 'Descrição do fato');
      expect(json.containsKey('reportDate'), isTrue);
      expect(json['actionsTaken'], 'Encaminhamento ao CREAS');
    });
  });

  group('UpdatePlacementHistoryRequest.toJson', () {
    test('serializes nested structures', () {
      final request = UpdatePlacementHistoryRequest(
        registries: [
          PlacementRegistryDto(
            memberId: 'm-1',
            startDate: DateTime(2023, 1, 1),
            reason: 'Acolhimento institucional',
          ),
        ],
        separationChecklist: const SeparationChecklistDto(
          adultInPrison: false,
          adolescentInInternment: true,
        ),
      );

      final json = request.toJson();

      expect(json['registries'], hasLength(1));
      final checklist = json['separationChecklist'] as Map<String, dynamic>;
      expect(checklist['adolescentInInternment'], isTrue);
      expect(json.containsKey('collectiveSituations'), isFalse);
    });
  });
}

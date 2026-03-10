import 'package:core/core.dart';
import 'package:social_care_bff/social_care_bff.dart';
import 'package:social_care_bff/testing.dart';
import 'package:test/test.dart';

void main() {
  group('InProcessBff via FakeSocialCareBff', () {
    // InProcessBff is a thin delegation layer over SocialCareApiClient.
    // It requires a real HTTP server for integration tests.
    // Here we test the contract abstraction via the Fake.

    late FakeSocialCareBff bff;

    setUp(() {
      bff = FakeSocialCareBff();
    });

    test('full patient lifecycle', () async {
      // 1. Register
      final registerResult = await bff.registerPatient(
        actorId: 'actor-1',
        request: const RegisterPatientRequest(
          personId: 'person-1',
          initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
          prRelationshipId: 'rel-1',
        ),
      );
      expect(registerResult.isSuccess, isTrue);
      final patientId = registerResult.valueOrNull!;

      // 2. Get by ID
      final getResult = await bff.getPatientById(patientId);
      expect(getResult.isSuccess, isTrue);
      expect(getResult.valueOrNull!.personId, 'person-1');

      // 3. Add family member
      final addResult = await bff.addFamilyMember(
        patientId: patientId,
        actorId: 'actor-1',
        request: AddFamilyMemberRequest(
          memberPersonId: 'member-1',
          relationship: 'filho',
          isResiding: true,
          isCaregiver: false,
          hasDisability: false,
          requiredDocuments: const [],
          birthDate: DateTime(2015),
          prRelationshipId: 'rel-1',
        ),
      );
      expect(addResult.isSuccess, isTrue);

      // 4. Update assessment
      const housingResult = UpdateHousingConditionRequest(
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
      );
      final updateResult = await bff.updateHousingCondition(
        patientId: patientId,
        actorId: 'actor-1',
        request: housingResult,
      );
      expect(updateResult.isSuccess, isTrue);

      // 5. Register appointment
      final appointResult = await bff.registerAppointment(
        patientId: patientId,
        actorId: 'actor-1',
        request: const RegisterAppointmentRequest(
          professionalId: 'prof-1',
          summary: 'Visita domiciliar',
        ),
      );
      expect(appointResult.isSuccess, isTrue);
      expect(appointResult.valueOrNull, isNotEmpty);

      // 6. Audit trail
      final auditResult = await bff.getAuditTrail(patientId);
      expect(auditResult.isSuccess, isTrue);
    });

    test('failure mode propagates errors', () async {
      bff.shouldFail = true;
      bff.failMessage = 'Server unavailable';

      final result = await bff.listLookupItems('dominio_parentesco');

      expect(result.isFailure, isTrue);
      switch (result) {
        case Failure(:final error):
          expect(error, 'Server unavailable');
        default:
          fail('Expected Failure');
      }
    });

    test('lookup tables work correctly', () async {
      bff.lookupTables['dominio_tipo_deficiencia'] = [
        const LookupItem(
          id: '1',
          codigo: 'VISUAL',
          descricao: 'Deficiência visual',
        ),
        const LookupItem(
          id: '2',
          codigo: 'AUDITIVA',
          descricao: 'Deficiência auditiva',
        ),
        const LookupItem(
          id: '3',
          codigo: 'FISICA',
          descricao: 'Deficiência física',
        ),
      ];

      final result = await bff.listLookupItems('dominio_tipo_deficiencia');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(3));
      expect(result.valueOrNull!.first.codigo, 'VISUAL');
    });
  });
}

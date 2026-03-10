import 'package:social_care_bff/social_care_bff.dart';
import 'package:social_care_bff/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeSocialCareBff', () {
    late FakeSocialCareBff bff;

    setUp(() {
      bff = FakeSocialCareBff();
    });

    test('registerPatient returns id and stores patient', () async {
      const request = RegisterPatientRequest(
        personId: 'person-1',
        initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
        prRelationshipId: 'rel-1',
      );

      final result = await bff.registerPatient(
        actorId: 'actor-1',
        request: request,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 'fake-patient-id');
      expect(bff.patients, hasLength(1));
      expect(bff.registerCallCount, 1);
    });

    test('getPatientById returns stored patient', () async {
      await bff.registerPatient(
        actorId: 'actor-1',
        request: const RegisterPatientRequest(
          personId: 'person-1',
          initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
          prRelationshipId: 'rel-1',
        ),
      );

      final result = await bff.getPatientById('fake-patient-id');

      expect(result.isSuccess, isTrue);
      final patient = result.valueOrNull!;
      expect(patient.personId, 'person-1');
      expect(patient.version, 1);
    });

    test('getPatientById fails for unknown id', () async {
      final result = await bff.getPatientById('unknown');

      expect(result.isFailure, isTrue);
    });

    test('getPatientByPersonId finds patient', () async {
      await bff.registerPatient(
        actorId: 'actor-1',
        request: const RegisterPatientRequest(
          personId: 'person-42',
          initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
          prRelationshipId: 'rel-1',
        ),
      );

      final result = await bff.getPatientByPersonId('person-42');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.personId, 'person-42');
    });

    test('listLookupItems returns configured items', () async {
      bff.lookupTables['dominio_parentesco'] = [
        const LookupItem(id: '1', codigo: 'PAI', descricao: 'Pai'),
        const LookupItem(id: '2', codigo: 'MAE', descricao: 'Mãe'),
      ];

      final result = await bff.listLookupItems('dominio_parentesco');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(2));
    });

    test('listLookupItems returns empty for unknown table', () async {
      final result = await bff.listLookupItems('unknown');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('shouldFail makes all operations return Failure', () async {
      bff.shouldFail = true;

      final result = await bff.registerPatient(
        actorId: 'actor-1',
        request: const RegisterPatientRequest(
          personId: 'person-1',
          initialDiagnoses: [InitialDiagnosisDto(icdCode: 'Q87.1')],
          prRelationshipId: 'rel-1',
        ),
      );

      expect(result.isFailure, isTrue);
    });

    test('mutation operations succeed', () async {
      final voidResult = await bff.addFamilyMember(
        patientId: 'p-1',
        actorId: 'a-1',
        request: AddFamilyMemberRequest(
          memberPersonId: 'm-1',
          relationship: 'filho',
          isResiding: true,
          isCaregiver: false,
          hasDisability: false,
          requiredDocuments: const [],
          birthDate: DateTime(2020),
          prRelationshipId: 'rel-1',
        ),
      );
      expect(voidResult.isSuccess, isTrue);

      final appointResult = await bff.registerAppointment(
        patientId: 'p-1',
        actorId: 'a-1',
        request: const RegisterAppointmentRequest(professionalId: 'prof-1'),
      );
      expect(appointResult.isSuccess, isTrue);
      expect(appointResult.valueOrNull, 'fake-appointment-id');

      final referralResult = await bff.createReferral(
        patientId: 'p-1',
        actorId: 'a-1',
        request: const CreateReferralRequest(
          referredPersonId: 'ref-1',
          destinationService: 'CREAS',
          reason: 'Encaminhamento',
        ),
      );
      expect(referralResult.isSuccess, isTrue);
      expect(referralResult.valueOrNull, 'fake-referral-id');
    });
  });
}

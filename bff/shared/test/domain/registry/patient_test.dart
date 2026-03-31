import 'package:core/core.dart';
import 'package:shared/src/domain/care/care_vos.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/domain/registry/family_member.dart';
import 'package:shared/src/domain/registry/patient.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('Patient - Invariantes de Agregado', () {
    final patientId = PatientId.create(
      '550e8400-e29b-41d4-a716-446655440000',
    ).valueOrNull!;
    final personId = PersonId.create(
      '550e8400-e29b-41d4-a716-446655440001',
    ).valueOrNull!;
    final prRelId = LookupId.create(
      '550e8400-e29b-41d4-a716-446655440002',
    ).valueOrNull!;
    final birthDate = TimeStamp.fromIso(
      '1980-01-01T00:00:00.000Z',
    ).valueOrNull!;

    final validDiagnosis = Diagnosis.create(
      id: IcdCode.create('B20').valueOrNull!,
      date: TimeStamp.now,
      description: 'HIV',
    ).valueOrNull!;

    final prMember = FamilyMember.create(
      personId: personId,
      relationshipId: prRelId,
      residesWithPatient: true,
      birthDate: birthDate,
    ).valueOrNull!;

    test(
      'Deve criar paciente com sucesso quando invariantes são respeitadas',
      () {
        final result = Patient.create(
          id: patientId,
          personId: personId,
          diagnoses: [validDiagnosis],
          familyMembers: [prMember],
          prRelationshipId: prRelId,
        );

        expect(result.isSuccess, isTrue);
      },
    );

    test('Deve rejeitar abertura de prontuário sem diagnósticos (PAT-003)', () {
      final result = Patient.create(
        id: patientId,
        personId: personId,
        diagnoses: [],
        familyMembers: [prMember],
        prRelationshipId: prRelId,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'PAT-003');
    });

    test('Deve rejeitar família sem Pessoa de Referência (PAT-008)', () {
      final otherRelId = LookupId.create(
        '550e8400-e29b-41d4-a716-446655440003',
      ).valueOrNull!;
      final otherMember = prMember.copyWith(relationshipId: otherRelId);

      final result = Patient.create(
        id: patientId,
        personId: personId,
        diagnoses: [validDiagnosis],
        familyMembers: [otherMember],
        prRelationshipId: prRelId,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'PAT-008');
    });

    test(
      'Deve rejeitar família com múltiplas Pessoas de Referência (PAT-009)',
      () {
        final pr2 = FamilyMember.create(
          personId: PersonId.create(
            '550e8400-e29b-41d4-a716-446655440004',
          ).valueOrNull!,
          relationshipId: prRelId,
          residesWithPatient: true,
          birthDate: birthDate,
        ).valueOrNull!;

        final result = Patient.create(
          id: patientId,
          personId: personId,
          diagnoses: [validDiagnosis],
          familyMembers: [prMember, pr2],
          prRelationshipId: prRelId,
        );

        expect(result.isFailure, isTrue);
        expect(((result as Failure).error as AppError).code, 'PAT-009');
      },
    );
  });
}

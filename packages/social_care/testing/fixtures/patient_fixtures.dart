import 'package:shared/shared.dart';

/// Reusable test fixtures for Patient-related tests.
///
/// Follows the same patterns as the staging integration test,
/// providing valid domain objects for predictable test scenarios.
class PatientFixtures {
  PatientFixtures._();

  // ─── IDs ──────────────────────────────────────────────────────────────

  static PatientId get patientId =>
      PatientId.create('550e8400-e29b-41d4-a716-000000000001').valueOrNull!;

  static PersonId get personId =>
      PersonId.create('550e8400-e29b-41d4-a716-000000000002').valueOrNull!;

  static PersonId get familyMemberPersonId =>
      PersonId.create('550e8400-e29b-41d4-a716-000000000003').valueOrNull!;

  static LookupId get prRelationshipId =>
      LookupId.create('550e8400-e29b-41d4-a716-000000000010').valueOrNull!;

  static String get validCpf => '12345678909';
  static String get validNis => '12345678901';
  static String get validRg => '12345678X';

  // ─── Value Objects ────────────────────────────────────────────────────

  static PersonalData get personalData => PersonalData.create(
    firstName: 'Maria',
    lastName: 'Silva',
    motherName: 'Ana Silva',
    nationality: 'Brasileira',
    sex: Sex.feminino,
    birthDate: TimeStamp.fromIso('1990-05-15T00:00:00.000Z').valueOrNull!,
  ).valueOrNull!;

  static Address get address => Address.create(
    cep: Cep.create('01001000').valueOrNull,
    state: 'SP',
    city: 'São Paulo',
    street: 'Praça da Sé',
    neighborhood: 'Sé',
    number: '1',
    residenceLocation: ResidenceLocation.urbano,
    isShelter: false,
  ).valueOrNull!;

  static CivilDocuments get civilDocuments => CivilDocuments.create(
    cpf: Cpf.create(validCpf).valueOrNull,
    nis: Nis.create(validNis).valueOrNull,
    rgDocument: RgDocument.create(
      number: validRg,
      issuingState: 'SP',
      issuingAgency: 'SSP',
      issueDate: TimeStamp.fromIso('2010-01-01T00:00:00.000Z').valueOrNull!,
    ).valueOrNull,
  ).valueOrNull!;

  static Diagnosis get diagnosis => Diagnosis.create(
    id: IcdCode.create('Q90.0').valueOrNull!,
    date: TimeStamp.fromIso('2020-03-10T00:00:00.000Z').valueOrNull!,
    description: 'Síndrome de Down — Trissomia 21',
  ).valueOrNull!;

  static FamilyMember get familyMember => FamilyMember.create(
    personId: familyMemberPersonId,
    relationshipId: prRelationshipId,
    residesWithPatient: true,
    isPrimaryCaregiver: true,
    birthDate: TimeStamp.fromIso('1965-08-20T00:00:00.000Z').valueOrNull!,
  ).valueOrNull!;

  // ─── Aggregates ───────────────────────────────────────────────────────

  /// A valid Patient that passes all domain invariants.
  static Patient get validPatient => Patient.reconstitute(
    id: patientId,
    personId: personId,
    prRelationshipId: prRelationshipId,
    version: 1,
    personalData: personalData,
    civilDocuments: civilDocuments,
    address: address,
    familyMembers: [familyMember],
    diagnoses: [diagnosis],
  );

  /// A Patient created via the [Patient.create] factory (with invariant checks).
  static Patient get createdPatient => Patient.create(
    id: patientId,
    personId: personId,
    prRelationshipId: prRelationshipId,
    personalData: personalData,
    civilDocuments: civilDocuments,
    address: address,
    diagnoses: [diagnosis],
    familyMembers: [familyMember],
  ).valueOrNull!;
}

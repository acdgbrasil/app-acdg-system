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

  // ─── Value Objects ────────────────────────────────────────────────────

  static PersonalData get personalData => PersonalData.create(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana Silva',
        nationality: 'Brasileira',
        sex: Sex.feminino,
        birthDate: TimeStamp.fromIso('1990-05-15T00:00:00.000Z').valueOrNull!,
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
        familyMembers: [familyMember],
        diagnoses: [diagnosis],
      );

  /// A Patient created via the [Patient.create] factory (with invariant checks).
  static Patient get createdPatient => Patient.create(
        id: patientId,
        personId: personId,
        prRelationshipId: prRelationshipId,
        personalData: personalData,
        diagnoses: [diagnosis],
        familyMembers: [familyMember],
      ).valueOrNull!;
}

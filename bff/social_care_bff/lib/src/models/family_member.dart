/// A family member associated with a patient.
final class FamilyMember {
  const FamilyMember({
    required this.personId,
    required this.relationshipId,
    required this.isPrimaryCaregiver,
    required this.residesWithPatient,
    required this.hasDisability,
    required this.requiredDocuments,
    this.birthDate,
  });

  final String personId;
  final String relationshipId;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final List<String> requiredDocuments;
  final DateTime? birthDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMember && other.personId == personId;

  @override
  int get hashCode => personId.hashCode;

  @override
  String toString() => 'FamilyMember(personId: $personId)';
}

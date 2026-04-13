/// Result returned from the add/edit member modal when saving.
class AddMemberResult {
  final String name;
  final DateTime birthDate;
  final String sex;
  final String relationshipCode;
  final bool residesWithPatient;
  final bool hasDisability;
  final bool isPrimaryCaregiver;
  final Set<String> requiredDocuments;
  final String? cpf;
  final String? linkedPersonId;

  const AddMemberResult({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.relationshipCode,
    required this.residesWithPatient,
    required this.hasDisability,
    required this.isPrimaryCaregiver,
    required this.requiredDocuments,
    this.cpf,
    this.linkedPersonId,
  });
}

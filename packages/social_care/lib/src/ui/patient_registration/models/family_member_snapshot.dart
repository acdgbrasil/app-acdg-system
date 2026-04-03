/// Immutable snapshot of a saved family member (for display in table).
class FamilyMemberSnapshot {
  const FamilyMemberSnapshot({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.relationshipCode,
    required this.hasDisability,
    required this.isResiding,
    required this.isCaregiver,
    required this.requiredDocuments,
  });

  final String name;
  final DateTime birthDate;
  final String sex;
  final String relationshipCode;
  final bool hasDisability;
  final bool isResiding;
  final bool isCaregiver;
  final Set<String> requiredDocuments;

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

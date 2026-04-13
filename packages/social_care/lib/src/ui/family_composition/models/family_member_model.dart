/// UI model representing a family member in the Composição Familiar screen.
///
/// Immutable. Derived from domain [FamilyMember] + lookup data.
final class FamilyMemberModel {
  const FamilyMemberModel({
    required this.personId,
    required this.relationshipLabel,
    required this.relationshipCode,
    required this.birthDate,
    required this.sex,
    required this.isReferencePerson,
    required this.isPrimaryCaregiver,
    required this.residesWithPatient,
    required this.hasDisability,
    required this.requiredDocuments,
    this.fullName,
  });

  final String personId;
  final String relationshipLabel;
  final String relationshipCode;
  final DateTime birthDate;
  final String sex;
  final bool isReferencePerson;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final Set<String> requiredDocuments;
  final String? fullName;

  /// Display name from People Context enrichment, or truncated personId as fallback.
  String get displayName => fullName ?? '${personId.substring(0, 8)}…';

  /// Precise age calculation considering whether birthday has passed this year.
  int get age {
    final now = DateTime.now();
    int a = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      a--;
    }
    return a;
  }

  FamilyMemberModel copyWith({
    String? personId,
    String? relationshipLabel,
    String? relationshipCode,
    DateTime? birthDate,
    String? sex,
    bool? isReferencePerson,
    bool? isPrimaryCaregiver,
    bool? residesWithPatient,
    bool? hasDisability,
    Set<String>? requiredDocuments,
    String? fullName,
  }) {
    return FamilyMemberModel(
      personId: personId ?? this.personId,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      relationshipCode: relationshipCode ?? this.relationshipCode,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      isReferencePerson: isReferencePerson ?? this.isReferencePerson,
      isPrimaryCaregiver: isPrimaryCaregiver ?? this.isPrimaryCaregiver,
      residesWithPatient: residesWithPatient ?? this.residesWithPatient,
      hasDisability: hasDisability ?? this.hasDisability,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
      fullName: fullName ?? this.fullName,
    );
  }
}

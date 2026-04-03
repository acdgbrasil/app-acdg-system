final class FamilyMemberDetail {
  final String id;
  final String relationshipId;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final String birthDate;

  const FamilyMemberDetail({
    required this.id,
    required this.relationshipId,
    required this.isPrimaryCaregiver,
    required this.residesWithPatient,
    required this.hasDisability,
    required this.birthDate,
  });

  factory FamilyMemberDetail.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDetail(
      id: json['id'] as String? ?? '',
      relationshipId: json['relationshipId'] as String? ?? '',
      isPrimaryCaregiver: json['isPrimaryCaregiver'] as bool? ?? false,
      residesWithPatient: json['residesWithPatient'] as bool? ?? false,
      hasDisability: json['hasDisability'] as bool? ?? false,
      birthDate: json['birthDate'] as String? ?? '',
    );
  }

  /// Raw JSON access for field extraction.
  Map<String, dynamic> get json => {
        'id': id,
        'relationshipId': relationshipId,
        'isPrimaryCaregiver': isPrimaryCaregiver,
        'residesWithPatient': residesWithPatient,
        'hasDisability': hasDisability,
        'birthDate': birthDate,
      };
}

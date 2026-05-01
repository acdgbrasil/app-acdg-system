import 'package:core/core.dart';

/// A member of a patient's family.
///
/// The member is identified by its People Context id ([personId]); the
/// relationship is resolved against a lookup table owned by the BFF.
class FamilyMember with Equatable {
  const FamilyMember({
    required this.personId,
    required this.relationshipId,
    required this.birthDate,
    this.isPrimaryCaregiver = false,
    this.residesWithPatient = false,
    this.hasDisability = false,
    this.requiredDocuments = const [],
  });

  final String personId;
  final String relationshipId;
  final String birthDate;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final List<String> requiredDocuments;

  FamilyMember copyWith({
    String? personId,
    String? relationshipId,
    String? birthDate,
    bool? isPrimaryCaregiver,
    bool? residesWithPatient,
    bool? hasDisability,
    List<String>? requiredDocuments,
  }) {
    return FamilyMember(
      personId: personId ?? this.personId,
      relationshipId: relationshipId ?? this.relationshipId,
      birthDate: birthDate ?? this.birthDate,
      isPrimaryCaregiver: isPrimaryCaregiver ?? this.isPrimaryCaregiver,
      residesWithPatient: residesWithPatient ?? this.residesWithPatient,
      hasDisability: hasDisability ?? this.hasDisability,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
    );
  }

  @override
  List<Object?> get props => [
    personId,
    relationshipId,
    birthDate,
    isPrimaryCaregiver,
    residesWithPatient,
    hasDisability,
    requiredDocuments,
  ];
}

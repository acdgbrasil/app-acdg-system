import 'dart:collection';

import 'package:equatable/equatable.dart';

/// Immutable snapshot of a saved family member (for display in table).
final class FamilyMemberSnapshot extends Equatable {
  FamilyMemberSnapshot({
    required this.name,
    required this.birthDate,
    required this.sex,
    required this.relationshipCode,
    required this.hasDisability,
    required this.isResiding,
    required this.isCaregiver,
    required Set<String> requiredDocuments,
  }) : requiredDocuments = UnmodifiableSetView(requiredDocuments);

  final String name;
  final DateTime birthDate;
  final String sex;
  final String relationshipCode;
  final bool hasDisability;
  final bool isResiding;
  final bool isCaregiver;
  final Set<String> requiredDocuments;

  /// Calculates the member's age relative to [referenceDate].
  int ageAt(DateTime referenceDate) {
    int age = referenceDate.year - birthDate.year;
    if (referenceDate.month < birthDate.month ||
        (referenceDate.month == birthDate.month &&
            referenceDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  FamilyMemberSnapshot copyWith({
    String? name,
    DateTime? birthDate,
    String? sex,
    String? relationshipCode,
    bool? hasDisability,
    bool? isResiding,
    bool? isCaregiver,
    Set<String>? requiredDocuments,
  }) {
    return FamilyMemberSnapshot(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      sex: sex ?? this.sex,
      relationshipCode: relationshipCode ?? this.relationshipCode,
      hasDisability: hasDisability ?? this.hasDisability,
      isResiding: isResiding ?? this.isResiding,
      isCaregiver: isCaregiver ?? this.isCaregiver,
      requiredDocuments: requiredDocuments ?? this.requiredDocuments,
    );
  }

  @override
  List<Object?> get props => [
    name,
    birthDate,
    sex,
    relationshipCode,
    hasDisability,
    isResiding,
    isCaregiver,
    requiredDocuments,
  ];
}

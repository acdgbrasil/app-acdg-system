import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Intent to add a new family member.
final class AddFamilyMemberIntent with Equatable {
  const AddFamilyMemberIntent({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.relationshipId,
    required this.birthDate,
    required this.prRelationshipId,
    this.isPrimaryCaregiver = false,
    this.residesWithPatient = true,
    this.hasDisability = false,
    this.requiredDocuments = const [],
  });

  final PatientId patientId;
  final String firstName;
  final String lastName;
  final String relationshipId;
  final DateTime birthDate;
  final String prRelationshipId;
  final bool isPrimaryCaregiver;
  final bool residesWithPatient;
  final bool hasDisability;
  final List<RequiredDocument> requiredDocuments;

  @override
  List<Object?> get props => [
    patientId,
    firstName,
    lastName,
    relationshipId,
    birthDate,
    prRelationshipId,
    isPrimaryCaregiver,
    residesWithPatient,
    hasDisability,
    requiredDocuments,
  ];
}

/// Intent to remove a family member.
final class RemoveFamilyMemberIntent with Equatable {
  const RemoveFamilyMemberIntent({
    required this.patientId,
    required this.memberPersonId,
  });

  final PatientId patientId;
  final PersonId memberPersonId;

  @override
  List<Object?> get props => [patientId, memberPersonId];
}

/// Intent to update the primary caregiver.
final class UpdatePrimaryCaregiverIntent with Equatable {
  const UpdatePrimaryCaregiverIntent({
    required this.patientId,
    required this.memberPersonId,
  });

  final PatientId patientId;
  final PersonId memberPersonId;

  @override
  List<Object?> get props => [patientId, memberPersonId];
}

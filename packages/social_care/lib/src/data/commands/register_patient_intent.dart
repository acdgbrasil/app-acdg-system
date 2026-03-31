import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// The final, immutable "Intent" to register a patient.
/// Captured as a snapshot of the form data at the moment of submission.
final class RegisterPatientIntent with Equatable {
  const RegisterPatientIntent({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    required this.prRelationshipId,
    this.personId,
    this.cpf,
    this.nis,
    this.rgNumber,
    this.rgAgency,
    this.rgState,
    this.rgDate,
    this.socialName,
    this.phone,
    this.cep,
    this.addressState,
    this.city,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
    this.residenceLocation,
    this.isShelter = false,
    this.diagnoses = const [],
    this.familyMembers = const [],
  });

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final Sex sex;
  final DateTime birthDate;
  final String prRelationshipId;
  final String? personId;
  final String? cpf;
  final String? nis;
  final String? rgNumber;
  final String? rgAgency;
  final String? rgState;
  final DateTime? rgDate;
  final String? socialName;
  final String? phone;

  // Address
  final String? cep;
  final String? addressState;
  final String? city;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final ResidenceLocation? residenceLocation;
  final bool isShelter;

  final List<Diagnosis> diagnoses;
  final List<FamilyMember> familyMembers;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    motherName,
    nationality,
    sex,
    birthDate,
    prRelationshipId,
    personId,
    cpf,
    nis,
    rgNumber,
    rgAgency,
    rgState,
    rgDate,
    socialName,
    phone,
    cep,
    addressState,
    city,
    street,
    neighborhood,
    number,
    complement,
    residenceLocation,
    isShelter,
    diagnoses,
    familyMembers,
  ];
}

/// Request to register a new patient.
final class RegisterPatientRequest {
  const RegisterPatientRequest({
    required this.personId,
    required this.initialDiagnoses,
    required this.prRelationshipId,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
  });

  final String personId;
  final List<InitialDiagnosisDto> initialDiagnoses;
  final String prRelationshipId;
  final PersonalDataDto? personalData;
  final CivilDocumentsDto? civilDocuments;
  final AddressDto? address;
  final SocialIdentityDto? socialIdentity;

  Map<String, dynamic> toJson() => {
    'personId': personId,
    'initialDiagnoses': initialDiagnoses.map((d) => d.toJson()).toList(),
    'prRelationshipId': prRelationshipId,
    if (personalData != null) 'personalData': personalData!.toJson(),
    if (civilDocuments != null) 'civilDocuments': civilDocuments!.toJson(),
    if (address != null) 'address': address!.toJson(),
    if (socialIdentity != null) 'socialIdentity': socialIdentity!.toJson(),
  };
}

final class InitialDiagnosisDto {
  const InitialDiagnosisDto({required this.icdCode, this.description});

  final String icdCode;
  final String? description;

  Map<String, dynamic> toJson() => {
    'icdCode': icdCode,
    if (description != null) 'description': description,
  };
}

final class PersonalDataDto {
  const PersonalDataDto({
    this.firstName,
    this.lastName,
    this.motherName,
    this.nationality,
    this.sex,
    this.socialName,
    this.phone,
    this.birthDate,
  });

  final String? firstName;
  final String? lastName;
  final String? motherName;
  final String? nationality;
  final String? sex;
  final String? socialName;
  final String? phone;
  final DateTime? birthDate;

  Map<String, dynamic> toJson() => {
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (motherName != null) 'motherName': motherName,
    if (nationality != null) 'nationality': nationality,
    if (sex != null) 'sex': sex,
    if (socialName != null) 'socialName': socialName,
    if (phone != null) 'phone': phone,
    if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
  };
}

final class CivilDocumentsDto {
  const CivilDocumentsDto({this.cpf, this.nis, this.rgDocument});

  final String? cpf;
  final String? nis;
  final RgDocumentDto? rgDocument;

  Map<String, dynamic> toJson() => {
    if (cpf != null) 'cpf': cpf,
    if (nis != null) 'nis': nis,
    if (rgDocument != null) 'rgDocument': rgDocument!.toJson(),
  };
}

final class RgDocumentDto {
  const RgDocumentDto({
    this.number,
    this.issuingState,
    this.issuingAgency,
    this.issueDate,
  });

  final String? number;
  final String? issuingState;
  final String? issuingAgency;
  final DateTime? issueDate;

  Map<String, dynamic> toJson() => {
    if (number != null) 'number': number,
    if (issuingState != null) 'issuingState': issuingState,
    if (issuingAgency != null) 'issuingAgency': issuingAgency,
    if (issueDate != null) 'issueDate': issueDate!.toIso8601String(),
  };
}

final class AddressDto {
  const AddressDto({
    this.cep,
    this.isShelter,
    this.residenceLocation,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
    this.state,
    this.city,
  });

  final String? cep;
  final bool? isShelter;
  final String? residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String? state;
  final String? city;

  Map<String, dynamic> toJson() => {
    if (cep != null) 'cep': cep,
    if (isShelter != null) 'isShelter': isShelter,
    if (residenceLocation != null) 'residenceLocation': residenceLocation,
    if (street != null) 'street': street,
    if (neighborhood != null) 'neighborhood': neighborhood,
    if (number != null) 'number': number,
    if (complement != null) 'complement': complement,
    if (state != null) 'state': state,
    if (city != null) 'city': city,
  };
}

final class SocialIdentityDto {
  const SocialIdentityDto({this.typeId, this.description});

  final String? typeId;
  final String? description;

  Map<String, dynamic> toJson() => {
    if (typeId != null) 'typeId': typeId,
    if (description != null) 'description': description,
  };
}

/// Request to add a family member.
final class AddFamilyMemberRequest {
  const AddFamilyMemberRequest({
    required this.memberPersonId,
    required this.relationship,
    required this.isResiding,
    required this.isCaregiver,
    required this.hasDisability,
    required this.requiredDocuments,
    required this.birthDate,
    required this.prRelationshipId,
  });

  final String memberPersonId;
  final String relationship;
  final bool isResiding;
  final bool isCaregiver;
  final bool hasDisability;
  final List<String> requiredDocuments;
  final DateTime birthDate;
  final String prRelationshipId;

  Map<String, dynamic> toJson() => {
    'memberPersonId': memberPersonId,
    'relationship': relationship,
    'isResiding': isResiding,
    'isCaregiver': isCaregiver,
    'hasDisability': hasDisability,
    'requiredDocuments': requiredDocuments,
    'birthDate': birthDate.toIso8601String(),
    'prRelationshipId': prRelationshipId,
  };
}

/// Request to assign primary caregiver.
final class AssignPrimaryCaregiverRequest {
  const AssignPrimaryCaregiverRequest({required this.memberPersonId});

  final String memberPersonId;

  Map<String, dynamic> toJson() => {'memberPersonId': memberPersonId};
}

/// Request to update social identity.
final class UpdateSocialIdentityRequest {
  const UpdateSocialIdentityRequest({required this.typeId, this.description});

  final String typeId;
  final String? description;

  Map<String, dynamic> toJson() => {
    'typeId': typeId,
    if (description != null) 'description': description,
  };
}

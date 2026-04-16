import 'package:json_annotation/json_annotation.dart';

part 'register_patient_request.g.dart';

@JsonSerializable()
class RegisterPatientRequest {
  const RegisterPatientRequest({
    required this.personId,
    required this.initialDiagnoses,
    required this.prRelationshipId,
    this.personalData,
    this.civilDocuments,
    this.address,
    this.socialIdentity,
  });

  factory RegisterPatientRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterPatientRequestFromJson(json);

  final String personId;
  final List<DiagnosisDraftDto> initialDiagnoses;
  final String prRelationshipId;
  final PersonalDataDraftDto? personalData;
  final CivilDocumentsDraftDto? civilDocuments;
  final AddressDraftDto? address;
  final SocialIdentityDraftDto? socialIdentity;

  Map<String, dynamic> toJson() => _$RegisterPatientRequestToJson(this);
}

@JsonSerializable()
class DiagnosisDraftDto {
  const DiagnosisDraftDto({
    required this.icdCode,
    required this.date,
    required this.description,
  });

  factory DiagnosisDraftDto.fromJson(Map<String, dynamic> json) =>
      _$DiagnosisDraftDtoFromJson(json);

  final String icdCode;
  final String date;
  final String description;

  Map<String, dynamic> toJson() => _$DiagnosisDraftDtoToJson(this);
}

@JsonSerializable()
class PersonalDataDraftDto {
  const PersonalDataDraftDto({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    this.socialName,
    this.phone,
  });

  factory PersonalDataDraftDto.fromJson(Map<String, dynamic> json) =>
      _$PersonalDataDraftDtoFromJson(json);

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final String birthDate;
  final String? socialName;
  final String? phone;

  Map<String, dynamic> toJson() => _$PersonalDataDraftDtoToJson(this);
}

@JsonSerializable()
class CivilDocumentsDraftDto {
  const CivilDocumentsDraftDto({this.cpf, this.nis, this.rgDocument, this.cns});

  factory CivilDocumentsDraftDto.fromJson(Map<String, dynamic> json) =>
      _$CivilDocumentsDraftDtoFromJson(json);

  final String? cpf;
  final String? nis;
  final RgDocumentDraftDto? rgDocument;
  final CnsDraftDto? cns;

  Map<String, dynamic> toJson() => _$CivilDocumentsDraftDtoToJson(this);
}

@JsonSerializable()
class RgDocumentDraftDto {
  const RgDocumentDraftDto({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  factory RgDocumentDraftDto.fromJson(Map<String, dynamic> json) =>
      _$RgDocumentDraftDtoFromJson(json);

  final String number;
  final String issuingState;
  final String issuingAgency;
  final String issueDate;

  Map<String, dynamic> toJson() => _$RgDocumentDraftDtoToJson(this);
}

@JsonSerializable()
class CnsDraftDto {
  const CnsDraftDto({required this.number, required this.cpf, this.qrCode});

  factory CnsDraftDto.fromJson(Map<String, dynamic> json) =>
      _$CnsDraftDtoFromJson(json);

  final String number;
  final String cpf;
  final String? qrCode;

  Map<String, dynamic> toJson() => _$CnsDraftDtoToJson(this);
}

@JsonSerializable()
class AddressDraftDto {
  const AddressDraftDto({
    required this.isShelter,
    required this.residenceLocation,
    required this.state,
    required this.city,
    this.cep,
    this.isHomeless = false,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
  });

  factory AddressDraftDto.fromJson(Map<String, dynamic> json) =>
      _$AddressDraftDtoFromJson(json);

  final String? cep;
  final bool isShelter;
  final bool isHomeless;
  final String residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String state;
  final String city;

  Map<String, dynamic> toJson() => _$AddressDraftDtoToJson(this);
}

@JsonSerializable()
class SocialIdentityDraftDto {
  const SocialIdentityDraftDto({required this.typeId, this.description});

  factory SocialIdentityDraftDto.fromJson(Map<String, dynamic> json) =>
      _$SocialIdentityDraftDtoFromJson(json);

  final String typeId;
  final String? description;

  Map<String, dynamic> toJson() => _$SocialIdentityDraftDtoToJson(this);
}

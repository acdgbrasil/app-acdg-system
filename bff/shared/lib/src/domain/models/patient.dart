import 'package:core/core.dart';
import '../value_objects/cep.dart';
import '../value_objects/cpf.dart';
import '../value_objects/nis.dart';

/// Agregado principal que representa um Paciente no domínio de Social Care.
final class Patient with Equatable {
  const Patient({
    required this.id,
    required this.personId,
    required this.personalData,
    required this.civilDocuments,
    required this.address,
    required this.prRelationshipId,
    this.initialDiagnoses = const [],
    this.socialIdentity,
  });

  /// Identificador único do paciente (gerado pelo backend).
  final String id;
  
  /// Identificador da pessoa (vínculo com o Identity).
  final String personId;
  
  /// Lista de diagnósticos iniciais.
  final List<Diagnosis> initialDiagnoses;
  
  /// Dados pessoais básicos.
  final PersonalData personalData;
  
  /// Documentos civis (CPF, NIS, RG).
  final CivilDocuments civilDocuments;
  
  /// Endereço de residência.
  final Address address;
  
  /// Identidade social (opcional).
  final SocialIdentity? socialIdentity;
  
  /// Relação da Pessoa de Referência.
  final String prRelationshipId;

  @override
  List<Object?> get props => [
        id,
        personId,
        initialDiagnoses,
        personalData,
        civilDocuments,
        address,
        socialIdentity,
        prRelationshipId,
      ];

  Patient copyWith({
    String? id,
    String? personId,
    List<Diagnosis>? initialDiagnoses,
    PersonalData? personalData,
    CivilDocuments? civilDocuments,
    Address? address,
    SocialIdentity? Function()? socialIdentity,
    String? prRelationshipId,
  }) {
    return Patient(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      initialDiagnoses: initialDiagnoses ?? this.initialDiagnoses,
      personalData: personalData ?? this.personalData,
      civilDocuments: civilDocuments ?? this.civilDocuments,
      address: address ?? this.address,
      socialIdentity: socialIdentity != null ? socialIdentity() : this.socialIdentity,
      prRelationshipId: prRelationshipId ?? this.prRelationshipId,
    );
  }
}

final class Diagnosis with Equatable {
  const Diagnosis({
    required this.icdCode,
    required this.date,
    required this.description,
  });

  final String icdCode;
  final DateTime date;
  final String description;

  @override
  List<Object?> get props => [icdCode, date, description];

  Diagnosis copyWith({
    String? icdCode,
    DateTime? date,
    String? description,
  }) {
    return Diagnosis(
      icdCode: icdCode ?? this.icdCode,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}

final class PersonalData with Equatable {
  const PersonalData({
    required this.firstName,
    required this.lastName,
    required this.motherName,
    required this.nationality,
    required this.sex,
    required this.birthDate,
    this.socialName,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String motherName;
  final String nationality;
  final String sex;
  final String? socialName;
  final DateTime birthDate;
  final String? phone;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        motherName,
        nationality,
        sex,
        socialName,
        birthDate,
        phone,
      ];

  PersonalData copyWith({
    String? firstName,
    String? lastName,
    String? motherName,
    String? nationality,
    String? sex,
    String? Function()? socialName,
    DateTime? birthDate,
    String? Function()? phone,
  }) {
    return PersonalData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      motherName: motherName ?? this.motherName,
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      socialName: socialName != null ? socialName() : this.socialName,
      birthDate: birthDate ?? this.birthDate,
      phone: phone != null ? phone() : this.phone,
    );
  }
}

final class CivilDocuments with Equatable {
  const CivilDocuments({
    this.cpf,
    this.nis,
    this.rgDocument,
  });

  final Cpf? cpf;
  final Nis? nis;
  final RgDocument? rgDocument;

  @override
  List<Object?> get props => [cpf, nis, rgDocument];

  CivilDocuments copyWith({
    Cpf? Function()? cpf,
    Nis? Function()? nis,
    RgDocument? Function()? rgDocument,
  }) {
    return CivilDocuments(
      cpf: cpf != null ? cpf() : this.cpf,
      nis: nis != null ? nis() : this.nis,
      rgDocument: rgDocument != null ? rgDocument() : this.rgDocument,
    );
  }
}

final class RgDocument with Equatable {
  const RgDocument({
    required this.number,
    required this.issuingState,
    required this.issuingAgency,
    required this.issueDate,
  });

  final String number;
  final String issuingState;
  final String issuingAgency;
  final DateTime issueDate;

  @override
  List<Object?> get props => [number, issuingState, issuingAgency, issueDate];

  RgDocument copyWith({
    String? number,
    String? issuingState,
    String? issuingAgency,
    DateTime? issueDate,
  }) {
    return RgDocument(
      number: number ?? this.number,
      issuingState: issuingState ?? this.issuingState,
      issuingAgency: issuingAgency ?? this.issuingAgency,
      issueDate: issueDate ?? this.issueDate,
    );
  }
}

final class Address with Equatable {
  const Address({
    required this.isShelter,
    required this.residenceLocation,
    required this.state,
    required this.city,
    this.cep,
    this.street,
    this.neighborhood,
    this.number,
    this.complement,
  });

  final Cep? cep;
  final bool isShelter;
  final String residenceLocation;
  final String? street;
  final String? neighborhood;
  final String? number;
  final String? complement;
  final String state;
  final String city;

  @override
  List<Object?> get props => [
        cep,
        isShelter,
        residenceLocation,
        street,
        neighborhood,
        number,
        complement,
        state,
        city,
      ];

  Address copyWith({
    Cep? Function()? cep,
    bool? isShelter,
    String? residenceLocation,
    String? Function()? street,
    String? Function()? neighborhood,
    String? Function()? number,
    String? Function()? complement,
    String? state,
    String? city,
  }) {
    return Address(
      cep: cep != null ? cep() : this.cep,
      isShelter: isShelter ?? this.isShelter,
      residenceLocation: residenceLocation ?? this.residenceLocation,
      street: street != null ? street() : this.street,
      neighborhood: neighborhood != null ? neighborhood() : this.neighborhood,
      number: number != null ? number() : this.number,
      complement: complement != null ? complement() : this.complement,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }
}

final class SocialIdentity with Equatable {
  const SocialIdentity({
    required this.typeId,
    this.description,
  });

  final String typeId;
  final String? description;

  @override
  List<Object?> get props => [typeId, description];

  SocialIdentity copyWith({
    String? typeId,
    String? Function()? description,
  }) {
    return SocialIdentity(
      typeId: typeId ?? this.typeId,
      description: description != null ? description() : this.description,
    );
  }
}

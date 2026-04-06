import 'package:collection/collection.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';

/// Mapper for the Registry bounded context:
/// PersonalData, CivilDocuments, Address, FamilyMember, Diagnosis, SocialIdentity.
abstract final class RegistryMapper {
  // ── To JSON ─────────────────────────────────────────────────

  static Map<String, dynamic> personalDataToJson(PersonalData d) => {
        'firstName': d.firstName,
        'lastName': d.lastName,
        'motherName': d.motherName,
        'nationality': d.nationality,
        'sex': d.sex.name,
        'socialName': d.socialName,
        'birthDate': d.birthDate.toIso8601(),
        'phone': d.phone,
      };

  static Map<String, dynamic> civilDocumentsToJson(CivilDocuments d) => {
        'cpf': d.cpf?.value,
        'nis': d.nis?.value,
        'rgDocument': d.rgDocument == null
            ? null
            : {
                'number': d.rgDocument!.number,
                'issuingState': d.rgDocument!.issuingState,
                'issuingAgency': d.rgDocument!.issuingAgency,
                'issueDate': d.rgDocument!.issueDate.toIso8601(),
              },
        'cns': d.cns == null
            ? null
            : {
                'number': d.cns!.number,
                'cpf': d.cns!.cpf?.value,
                'qrCode': d.cns!.qrCode,
              },
      };

  static Map<String, dynamic> addressToJson(Address a) => {
        'cep': a.cep?.value,
        'state': a.state,
        'city': a.city,
        'street': a.street,
        'neighborhood': a.neighborhood,
        'number': a.number,
        'complement': a.complement,
        'residenceLocation':
            a.residenceLocation == ResidenceLocation.urbano ? 'URBANO' : 'RURAL',
        'isShelter': a.isShelter,
      };

  static Map<String, dynamic> familyMemberToJson(FamilyMember m) => {
        'personId': m.personId.value,
        'memberPersonId': m.personId.value,
        'relationship': m.relationshipId.value,
        'isResiding': m.residesWithPatient,
        'isCaregiver': m.isPrimaryCaregiver,
        'hasDisability': m.hasDisability,
        'requiredDocuments': m.requiredDocuments.map((d) => d.value).toList(),
        'birthDate': m.birthDate.toIso8601(),
      };

  static Map<String, dynamic> diagnosisToJson(Diagnosis d) => {
        'icdCode': d.id.value,
        'date': d.date.toIso8601(),
        'description': d.description,
      };

  static Map<String, dynamic> socialIdentityToJson(SocialIdentity i) => {
        'typeId': i.typeId.value,
        'description': i.otherDescription,
      };

  // ── From JSON ───────────────────────────────────────────────

  static Result<PersonalData> personalDataFromJson(Map<String, dynamic> j) {
    final TimeStamp birthDate;
    switch (TimeStamp.fromIso(j['birthDate'])) {
      case Success(:final value): birthDate = value;
      case Failure(:final error): return Failure('personalData.birthDate: $error');
    }

    final sex = Sex.values.firstWhereOrNull((v) => v.name == j['sex']);
    if (sex == null) {
      return const Failure('personalData.sex: Valor inválido ou ausente');
    }

    return PersonalData.create(
      firstName: j['firstName'],
      lastName: j['lastName'],
      motherName: j['motherName'],
      nationality: j['nationality'],
      sex: sex,
      socialName: j['socialName'],
      birthDate: birthDate,
      phone: j['phone'],
    );
  }

  static Result<CivilDocuments> civilDocumentsFromJson(Map<String, dynamic> j) {
    Cpf? cpf;
    if (j['cpf'] != null) {
      switch (Cpf.create(j['cpf'])) {
        case Success(:final value): cpf = value;
        case Failure(:final error): return Failure('civilDocuments.cpf: $error');
      }
    }

    Nis? nis;
    if (j['nis'] != null) {
      switch (Nis.create(j['nis'])) {
        case Success(:final value): nis = value;
        case Failure(:final error): return Failure('civilDocuments.nis: $error');
      }
    }

    RgDocument? rgDocument;
    if (j['rgDocument'] != null) {
      switch (_rgDocumentFromJson(j['rgDocument'] as Map<String, dynamic>)) {
        case Success(:final value): rgDocument = value;
        case Failure(:final error): return Failure(error);
      }
    }

    Cns? cns;
    if (j['cns'] != null) {
      switch (_cnsFromJson(j['cns'] as Map<String, dynamic>)) {
        case Success(:final value): cns = value;
        case Failure(:final error): return Failure(error);
      }
    }

    return CivilDocuments.create(
      cpf: cpf,
      nis: nis,
      rgDocument: rgDocument,
      cns: cns,
    );
  }

  static Result<RgDocument> _rgDocumentFromJson(Map<String, dynamic> j) {
    final TimeStamp issueDate;
    switch (TimeStamp.fromIso(j['issueDate'])) {
      case Success(:final value): issueDate = value;
      case Failure(:final error):
        return Failure('civilDocuments.rgDocument.issueDate: $error');
    }

    return RgDocument.create(
      number: j['number'],
      issuingState: j['issuingState'],
      issuingAgency: j['issuingAgency'],
      issueDate: issueDate,
    );
  }

  static Result<Cns> _cnsFromJson(Map<String, dynamic> j) {
    Cpf? cpf;
    if (j['cpf'] != null) {
      switch (Cpf.create(j['cpf'])) {
        case Success(:final value): cpf = value;
        case Failure(:final error):
          return Failure('civilDocuments.cns.cpf: $error');
      }
    }

    return Cns.create(
      number: j['number'],
      cpf: cpf,
      qrCode: j['qrCode'],
    );
  }

  static Result<Address> addressFromJson(Map<String, dynamic> j) {
    Cep? cep;
    if (j['cep'] != null) {
      switch (Cep.create(j['cep'])) {
        case Success(:final value): cep = value;
        case Failure(:final error): return Failure('address.cep: $error');
      }
    }

    return Address.create(
      cep: cep,
      state: j['state'],
      city: j['city'],
      street: j['street'],
      neighborhood: j['neighborhood'],
      number: j['number'],
      complement: j['complement'],
      residenceLocation: j['residenceLocation'] == 'URBANO'
          ? ResidenceLocation.urbano
          : ResidenceLocation.rural,
      isShelter: j['isShelter'],
    );
  }

  static Result<FamilyMember> familyMemberFromJson(Map<String, dynamic> j) {
    final PersonId personId;
    switch (PersonId.create(j['personId'])) {
      case Success(:final value): personId = value;
      case Failure(:final error): return Failure('familyMember.personId: $error');
    }

    final LookupId relationshipId;
    switch (LookupId.create(j['relationship'] ?? j['relationshipId'])) {
      case Success(:final value): relationshipId = value;
      case Failure(:final error):
        return Failure('familyMember.relationship: $error');
    }

    final TimeStamp birthDate;
    switch (TimeStamp.fromIso(j['birthDate'])) {
      case Success(:final value): birthDate = value;
      case Failure(:final error):
        return Failure('familyMember.birthDate: $error');
    }

    final requiredDocs = (j['requiredDocuments'] as List? ?? [])
        .map((d) => RequiredDocument.values.firstWhereOrNull((v) => v.value == d))
        .nonNulls
        .toList();

    return Success(FamilyMember.reconstitute(
      personId: personId,
      relationshipId: relationshipId,
      residesWithPatient: j['isResiding'] ?? j['residesWithPatient'] ?? false,
      isPrimaryCaregiver: j['isCaregiver'] ?? j['isPrimaryCaregiver'] ?? false,
      hasDisability: j['hasDisability'] ?? false,
      requiredDocuments: requiredDocs,
      birthDate: birthDate,
    ));
  }

  static Result<Diagnosis> diagnosisFromJson(Map<String, dynamic> j) {
    final IcdCode icdCode;
    switch (IcdCode.create(j['icdCode'])) {
      case Success(:final value): icdCode = value;
      case Failure(:final error): return Failure('diagnosis.icdCode: $error');
    }

    final TimeStamp date;
    switch (TimeStamp.fromIso(j['date'])) {
      case Success(:final value): date = value;
      case Failure(:final error): return Failure('diagnosis.date: $error');
    }

    return Diagnosis.create(
      id: icdCode,
      date: date,
      description: j['description'],
    );
  }

  static Result<SocialIdentity> socialIdentityFromJson(Map<String, dynamic> j) {
    final LookupId typeId;
    switch (LookupId.create(j['typeId'])) {
      case Success(:final value): typeId = value;
      case Failure(:final error):
        return Failure('socialIdentity.typeId: $error');
    }

    return SocialIdentity.create(
      typeId: typeId,
      otherDescription: j['description'],
    );
  }
}

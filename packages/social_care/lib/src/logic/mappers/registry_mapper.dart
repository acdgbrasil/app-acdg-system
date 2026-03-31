import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../../data/commands/register_patient_intent.dart';
import '../../domain/schemas/social_care_schemas.dart';

/// Specialized mapper to assemble Registry-related domain aggregates.
abstract final class RegistryMapper {
  /// Converts a [RegisterPatientIntent] into a valid [Patient] domain object.
  static Result<Patient> toPatient(RegisterPatientIntent intent) {
    // 1. Schema Validation (zard)
    final validation = SocialCareSchemas.patientRegistration.safeParse({
      'firstName': intent.firstName,
      'lastName': intent.lastName,
      'motherName': intent.motherName,
      'nationality': intent.nationality,
      'sex': intent.sex.name,
      'cpf': intent.cpf ?? '',
      'birthDate': intent.birthDate,
      'addressState': intent.addressState ?? '',
      'city': intent.city ?? '',
      'residenceLocation': intent.residenceLocation?.name ?? '',
    });

    if (!validation.success) {
      return Failure(
        AppError(
          code: 'VAL-001',
          message: validation.error.toString(),
          module: 'social-care/mapper',
          kind: 'domainValidation',
          http: 422,
          observability: const Observability(
            category: ErrorCategory.domainRuleViolation,
            severity: ErrorSeverity.warning,
          ),
        ),
      );
    }

    // 2. TimeStamp conversion
    final birthTimeStampRes = TimeStamp.fromDate(intent.birthDate);
    if (birthTimeStampRes case Failure(:final error)) return Failure(error);
    final birthTimeStamp = (birthTimeStampRes as Success<TimeStamp>).value;

    // 3. Personal Data assembly
    final personalDataRes = PersonalData.create(
      firstName: intent.firstName.trim(),
      lastName: intent.lastName.trim(),
      motherName: intent.motherName.trim(),
      nationality: intent.nationality.trim(),
      sex: intent.sex,
      socialName: intent.socialName?.trim().isEmpty ?? true
          ? null
          : intent.socialName?.trim(),
      birthDate: birthTimeStamp,
      phone: intent.phone?.trim().isEmpty ?? true ? null : intent.phone?.trim(),
    );
    if (personalDataRes case Failure(:final error)) return Failure(error);
    final personalData = (personalDataRes as Success<PersonalData>).value;

    // 4. Civil Documents assembly
    Cpf? cpf;
    if (intent.cpf != null && intent.cpf!.isNotEmpty) {
      final res = Cpf.create(intent.cpf);
      if (res case Success(:final value)) cpf = value;
    }

    Nis? nis;
    if (intent.nis != null && intent.nis!.isNotEmpty) {
      final res = Nis.create(intent.nis);
      if (res case Success(:final value)) nis = value;
    }

    RgDocument? rg;
    if (intent.rgNumber != null && intent.rgNumber!.isNotEmpty) {
      final dateRes = TimeStamp.fromDate(intent.rgDate);
      if (dateRes case Success(:final value)) {
        final res = RgDocument.create(
          number: intent.rgNumber,
          issuingAgency: intent.rgAgency,
          issuingState: intent.rgState,
          issueDate: value,
        );
        if (res case Success(:final value)) rg = value;
      }
    }

    CivilDocuments? civilDocuments;
    if (cpf != null || nis != null || rg != null) {
      final civilRes = CivilDocuments.create(
        cpf: cpf,
        nis: nis,
        rgDocument: rg,
      );
      if (civilRes case Success(:final value)) civilDocuments = value;
    }

    // 5. Address assembly
    Address? address;
    if (intent.addressState != null && intent.city != null) {
      Cep? cep;
      if (intent.cep != null && intent.cep!.isNotEmpty) {
        final cepRes = Cep.create(intent.cep);
        if (cepRes case Success(:final value)) {
          cep = value;
        }
      }

      final addrRes = Address.create(
        cep: cep,
        state: intent.addressState,
        city: intent.city,
        street: intent.street,
        neighborhood: intent.neighborhood,
        number: intent.number,
        complement: intent.complement,
        residenceLocation: intent.residenceLocation ?? ResidenceLocation.urbano,
        isShelter: intent.isShelter,
      );
      if (addrRes case Success(:final value)) {
        address = value;
      }
    }

    // 6. IDs Generation
    final prRelIdRes = LookupId.create(intent.prRelationshipId);
    if (prRelIdRes case Failure(:final error)) return Failure(error);
    final prRelId = (prRelIdRes as Success<LookupId>).value;

    final patientIdRes = PatientId.create(UuidUtil.generateV4());
    final personIdStr = intent.personId ?? UuidUtil.generateV4();
    final personIdRes = PersonId.create(personIdStr);

    if (patientIdRes is Failure)
      return Failure((patientIdRes as Failure).error);
    if (personIdRes is Failure) return Failure((personIdRes as Failure).error);

    final patientId = (patientIdRes as Success<PatientId>).value;
    final personId = (personIdRes as Success<PersonId>).value;

    // 7. Mandatory PR Family Member
    final prMemberRes = FamilyMember.create(
      personId: personId,
      relationshipId: prRelId,
      isPrimaryCaregiver: true,
      residesWithPatient: true,
      birthDate: birthTimeStamp,
    );
    if (prMemberRes case Failure(:final error)) return Failure(error);
    final prMember = (prMemberRes as Success<FamilyMember>).value;

    return Patient.create(
      id: patientId,
      personId: personId,
      prRelationshipId: prRelId,
      personalData: personalData,
      civilDocuments: civilDocuments,
      address: address,
      diagnoses: intent.diagnoses,
      familyMembers: [prMember, ...intent.familyMembers],
    );
  }
}

import '../../models/family_member.dart';
import '../../models/patient.dart';
import '../../models/value_objects/cep.dart';
import '../../models/value_objects/cpf.dart';
import '../../models/value_objects/nis.dart';
import 'assessment_mappers.dart';
import 'care_mappers.dart';
import 'common_mappers.dart';
import 'protection_mappers.dart';

/// JSON → domain model mappers for Patient and related sub-models.
abstract final class PatientMapper {
  static Patient fromJson(Map<String, dynamic> json) => Patient(
    patientId: json['patientId'] as String,
    personId: json['personId'] as String,
    version: json['version'] as int,
    personalData: _parsePersonalData(json['personalData']),
    civilDocuments: _parseCivilDocuments(json['civilDocuments']),
    address: _parseAddress(json['address']),
    socialIdentity: _parseSocialIdentity(json['socialIdentity']),
    familyMembers: parseList(json['familyMembers'], _parseFamilyMember),
    diagnoses: parseList(json['diagnoses'], _parseDiagnosis),
    housingCondition: AssessmentMappers.housingConditionFromJson(
      json['housingCondition'],
    ),
    socioeconomicSituation: AssessmentMappers.socioEconomicSituationFromJson(
      json['socioeconomicSituation'],
    ),
    workAndIncome: AssessmentMappers.workAndIncomeFromJson(
      json['workAndIncome'],
    ),
    educationalStatus: AssessmentMappers.educationalStatusFromJson(
      json['educationalStatus'],
    ),
    healthStatus: AssessmentMappers.healthStatusFromJson(
      json['healthStatus'],
    ),
    communitySupportNetwork:
        AssessmentMappers.communitySupportNetworkFromJson(
          json['communitySupportNetwork'],
        ),
    socialHealthSummary: AssessmentMappers.socialHealthSummaryFromJson(
      json['socialHealthSummary'],
    ),
    placementHistory: ProtectionMappers.placementHistoryFromJson(
      json['placementHistory'],
    ),
    intakeInfo: CareMappers.intakeInfoFromJson(json['intakeInfo']),
    appointments: parseList(json['appointments'], CareMappers.appointmentFromJson),
    referrals: parseList(json['referrals'], ProtectionMappers.referralFromJson),
    violationReports: parseList(
      json['violationReports'],
      ProtectionMappers.violationReportFromJson,
    ),
    computedAnalytics: ComputedAnalyticsMapper.fromJson(
      json['computedAnalytics'],
    ),
  );

  static PersonalData? _parsePersonalData(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return PersonalData(
      firstName: m['firstName'] as String?,
      lastName: m['lastName'] as String?,
      motherName: m['motherName'] as String?,
      nationality: m['nationality'] as String?,
      sex: m['sex'] as String?,
      socialName: m['socialName'] as String?,
      phone: m['phone'] as String?,
      birthDate: parseDateTime(m['birthDate']),
    );
  }

  static CivilDocuments? _parseCivilDocuments(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return CivilDocuments(
      cpf: _parseVo<Cpf>(m['cpf'], Cpf.new),
      nis: _parseVo<Nis>(m['nis'], Nis.new),
      rgDocument: _parseRgDocument(m['rgDocument']),
    );
  }

  static RgDocument? _parseRgDocument(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return RgDocument(
      number: m['number'] as String?,
      issuingState: m['issuingState'] as String?,
      issuingAgency: m['issuingAgency'] as String?,
      issueDate: parseDateTime(m['issueDate']),
    );
  }

  static Address? _parseAddress(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return Address(
      cep: _parseVo<Cep>(m['cep'], Cep.new),
      isShelter: m['isShelter'] as bool?,
      residenceLocation: m['residenceLocation'] as String?,
      street: m['street'] as String?,
      neighborhood: m['neighborhood'] as String?,
      number: m['number'] as String?,
      complement: m['complement'] as String?,
      state: m['state'] as String?,
      city: m['city'] as String?,
    );
  }

  static SocialIdentity? _parseSocialIdentity(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return SocialIdentity(
      typeId: m['typeId'] as String?,
      otherDescription: m['otherDescription'] as String?,
    );
  }

  static FamilyMember _parseFamilyMember(Map<String, dynamic> json) =>
      FamilyMember(
        personId: json['personId'] as String,
        relationshipId: json['relationshipId'] as String,
        isPrimaryCaregiver: json['isPrimaryCaregiver'] as bool? ?? false,
        residesWithPatient: json['residesWithPatient'] as bool? ?? false,
        hasDisability: json['hasDisability'] as bool? ?? false,
        requiredDocuments:
            (json['requiredDocuments'] as List<dynamic>?)?.cast<String>() ?? [],
        birthDate: parseDateTime(json['birthDate']),
      );

  static Diagnosis _parseDiagnosis(Map<String, dynamic> json) => Diagnosis(
    icdCode: json['icdCode'] as String?,
    description: json['description'] as String?,
    date: parseDateTime(json['date']),
  );

  static T? _parseVo<T>(dynamic value, T Function(String) constructor) {
    if (value == null) return null;
    return constructor(value as String);
  }
}

/// Parses a nullable JSON list into a typed list using the given [parser].
List<T> parseList<T>(
  dynamic json,
  T Function(Map<String, dynamic>) parser,
) {
  if (json == null) return [];
  return (json as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(parser)
      .toList();
}

/// Parses a nullable ISO-8601 string into a [DateTime].
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.parse(value as String);
}

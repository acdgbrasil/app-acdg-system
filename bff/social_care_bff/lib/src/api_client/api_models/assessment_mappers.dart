import '../../models/assessment/community_support_network.dart';
import '../../models/assessment/educational_status.dart';
import '../../models/assessment/health_status.dart';
import '../../models/assessment/housing_condition.dart';
import '../../models/assessment/social_health_summary.dart';
import '../../models/assessment/socio_economic_situation.dart';
import '../../models/assessment/work_and_income.dart';
import 'patient_mapper.dart';

/// JSON → domain model mappers for Assessment bounded context.
abstract final class AssessmentMappers {
  static HousingCondition? housingConditionFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return HousingCondition(
      type: m['type'] as String,
      wallMaterial: m['wallMaterial'] as String,
      numberOfRooms: m['numberOfRooms'] as int,
      numberOfBedrooms: m['numberOfBedrooms'] as int,
      numberOfBathrooms: m['numberOfBathrooms'] as int,
      waterSupply: m['waterSupply'] as String,
      hasPipedWater: m['hasPipedWater'] as bool,
      electricityAccess: m['electricityAccess'] as String,
      sewageDisposal: m['sewageDisposal'] as String,
      wasteCollection: m['wasteCollection'] as String,
      accessibilityLevel: m['accessibilityLevel'] as String,
      isInGeographicRiskArea: m['isInGeographicRiskArea'] as bool,
      hasDifficultAccess: m['hasDifficultAccess'] as bool,
      isInSocialConflictArea: m['isInSocialConflictArea'] as bool,
      hasDiagnosticObservations: m['hasDiagnosticObservations'] as bool,
    );
  }

  static SocioEconomicSituation? socioEconomicSituationFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return SocioEconomicSituation(
      totalFamilyIncome: (m['totalFamilyIncome'] as num).toDouble(),
      incomePerCapita: (m['incomePerCapita'] as num).toDouble(),
      receivesSocialBenefit: m['receivesSocialBenefit'] as bool,
      hasUnemployed: m['hasUnemployed'] as bool,
      mainSourceOfIncome: m['mainSourceOfIncome'] as String,
      socialBenefits: parseList(m['socialBenefits'], _parseSocialBenefit),
    );
  }

  static SocialBenefit _parseSocialBenefit(Map<String, dynamic> json) =>
      SocialBenefit(
        benefitName: json['benefitName'] as String,
        amount: (json['amount'] as num).toDouble(),
        beneficiaryId: json['beneficiaryId'] as String,
      );

  static WorkAndIncome? workAndIncomeFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return WorkAndIncome(
      hasRetiredMembers: m['hasRetiredMembers'] as bool,
      individualIncomes: parseList(
        m['individualIncomes'],
        _parseIndividualIncome,
      ),
      socialBenefits: parseList(m['socialBenefits'], _parseWorkSocialBenefit),
    );
  }

  static IndividualIncome _parseIndividualIncome(Map<String, dynamic> json) =>
      IndividualIncome(
        memberId: json['memberId'] as String,
        occupationId: json['occupationId'] as String,
        hasWorkCard: json['hasWorkCard'] as bool,
        monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      );

  static WorkSocialBenefit _parseWorkSocialBenefit(
    Map<String, dynamic> json,
  ) => WorkSocialBenefit(
    benefitName: json['benefitName'] as String,
    amount: (json['amount'] as num).toDouble(),
    beneficiaryId: json['beneficiaryId'] as String,
  );

  static EducationalStatus? educationalStatusFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return EducationalStatus(
      memberProfiles: parseList(m['memberProfiles'], _parseEducationalProfile),
      programOccurrences: parseList(
        m['programOccurrences'],
        _parseProgramOccurrence,
      ),
    );
  }

  static EducationalMemberProfile _parseEducationalProfile(
    Map<String, dynamic> json,
  ) => EducationalMemberProfile(
    memberId: json['memberId'] as String,
    canReadWrite: json['canReadWrite'] as bool,
    attendsSchool: json['attendsSchool'] as bool,
    educationLevelId: json['educationLevelId'] as String,
  );

  static ProgramOccurrence _parseProgramOccurrence(
    Map<String, dynamic> json,
  ) => ProgramOccurrence(
    memberId: json['memberId'] as String,
    date: parseDateTime(json['date']),
    effectId: json['effectId'] as String,
    isSuspensionRequested: json['isSuspensionRequested'] as bool,
  );

  static HealthStatus? healthStatusFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return HealthStatus(
      foodInsecurity: m['foodInsecurity'] as bool,
      deficiencies: parseList(m['deficiencies'], _parseDeficiency),
      gestatingMembers: parseList(
        m['gestatingMembers'],
        _parseGestatingMember,
      ),
      constantCareNeeds:
          (m['constantCareNeeds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static Deficiency _parseDeficiency(Map<String, dynamic> json) => Deficiency(
    memberId: json['memberId'] as String,
    deficiencyTypeId: json['deficiencyTypeId'] as String,
    needsConstantCare: json['needsConstantCare'] as bool,
    responsibleCaregiverName: json['responsibleCaregiverName'] as String?,
  );

  static GestatingMember _parseGestatingMember(Map<String, dynamic> json) =>
      GestatingMember(
        memberId: json['memberId'] as String,
        monthsGestation: json['monthsGestation'] as int,
        startedPrenatalCare: json['startedPrenatalCare'] as bool,
      );

  static CommunitySupportNetwork? communitySupportNetworkFromJson(
    dynamic json,
  ) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return CommunitySupportNetwork(
      hasRelativeSupport: m['hasRelativeSupport'] as bool,
      hasNeighborSupport: m['hasNeighborSupport'] as bool,
      familyConflicts: m['familyConflicts'] as String,
      patientParticipatesInGroups: m['patientParticipatesInGroups'] as bool,
      familyParticipatesInGroups: m['familyParticipatesInGroups'] as bool,
      patientHasAccessToLeisure: m['patientHasAccessToLeisure'] as bool,
      facesDiscrimination: m['facesDiscrimination'] as bool,
    );
  }

  static SocialHealthSummary? socialHealthSummaryFromJson(dynamic json) {
    if (json == null) return null;
    final m = json as Map<String, dynamic>;
    return SocialHealthSummary(
      requiresConstantCare: m['requiresConstantCare'] as bool,
      hasMobilityImpairment: m['hasMobilityImpairment'] as bool,
      functionalDependencies:
          (m['functionalDependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      hasRelevantDrugTherapy: m['hasRelevantDrugTherapy'] as bool,
    );
  }
}

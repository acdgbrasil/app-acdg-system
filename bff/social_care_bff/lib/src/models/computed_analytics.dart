/// Server-calculated analytics based on patient data.
final class ComputedAnalytics {
  const ComputedAnalytics({
    this.housing,
    this.financial,
    this.ageProfile,
    this.educationalVulnerabilities,
  });

  final HousingAnalytics? housing;
  final FinancialAnalytics? financial;
  final AgeProfile? ageProfile;
  final EducationalVulnerabilities? educationalVulnerabilities;
}

final class HousingAnalytics {
  const HousingAnalytics({this.density, this.isOvercrowded});

  final double? density;
  final bool? isOvercrowded;
}

final class FinancialAnalytics {
  const FinancialAnalytics({
    this.totalWorkIncome,
    this.perCapitaWorkIncome,
    this.totalGlobalIncome,
    this.perCapitaGlobalIncome,
  });

  final double? totalWorkIncome;
  final double? perCapitaWorkIncome;
  final double? totalGlobalIncome;
  final double? perCapitaGlobalIncome;
}

final class AgeProfile {
  const AgeProfile({
    this.range0to6 = 0,
    this.range7to14 = 0,
    this.range15to17 = 0,
    this.range18to29 = 0,
    this.range30to59 = 0,
    this.range60to64 = 0,
    this.range65to69 = 0,
    this.range70Plus = 0,
    this.totalMembers = 0,
  });

  final int range0to6;
  final int range7to14;
  final int range15to17;
  final int range18to29;
  final int range30to59;
  final int range60to64;
  final int range65to69;
  final int range70Plus;
  final int totalMembers;
}

final class EducationalVulnerabilities {
  const EducationalVulnerabilities({
    this.notInSchool0to5 = 0,
    this.notInSchool6to14 = 0,
    this.notInSchool15to17 = 0,
    this.illiteracy10to17 = 0,
    this.illiteracy18to59 = 0,
    this.illiteracy60Plus = 0,
  });

  final int notInSchool0to5;
  final int notInSchool6to14;
  final int notInSchool15to17;
  final int illiteracy10to17;
  final int illiteracy18to59;
  final int illiteracy60Plus;
}

final class ComputedAnalyticsDetail {
  final HousingAnalyticsDetail? housing;
  final FinancialAnalyticsDetail? financial;
  final AgeProfileDetail ageProfile;
  final EducationalVulnerabilitiesDetail? educationalVulnerabilities;

  const ComputedAnalyticsDetail({
    this.housing,
    this.financial,
    required this.ageProfile,
    this.educationalVulnerabilities,
  });

  factory ComputedAnalyticsDetail.fromJson(Map<String, dynamic> json) {
    return ComputedAnalyticsDetail(
      housing: json['housing'] != null
          ? HousingAnalyticsDetail.fromJson(
              json['housing'] as Map<String, dynamic>,
            )
          : null,
      financial: json['financial'] != null
          ? FinancialAnalyticsDetail.fromJson(
              json['financial'] as Map<String, dynamic>,
            )
          : null,
      ageProfile: AgeProfileDetail.fromJson(
        json['ageProfile'] as Map<String, dynamic>,
      ),
      educationalVulnerabilities: json['educationalVulnerabilities'] != null
          ? EducationalVulnerabilitiesDetail.fromJson(
              json['educationalVulnerabilities'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

final class HousingAnalyticsDetail {
  final double density;
  final bool isOvercrowded;

  const HousingAnalyticsDetail({
    required this.density,
    required this.isOvercrowded,
  });

  factory HousingAnalyticsDetail.fromJson(Map<String, dynamic> json) {
    return HousingAnalyticsDetail(
      density: (json['density'] as num).toDouble(),
      isOvercrowded: json['isOvercrowded'] as bool,
    );
  }
}

final class FinancialAnalyticsDetail {
  final double totalWorkIncome;
  final double perCapitaWorkIncome;
  final double totalGlobalIncome;
  final double perCapitaGlobalIncome;

  const FinancialAnalyticsDetail({
    required this.totalWorkIncome,
    required this.perCapitaWorkIncome,
    required this.totalGlobalIncome,
    required this.perCapitaGlobalIncome,
  });

  factory FinancialAnalyticsDetail.fromJson(Map<String, dynamic> json) {
    return FinancialAnalyticsDetail(
      totalWorkIncome: (json['totalWorkIncome'] as num).toDouble(),
      perCapitaWorkIncome: (json['perCapitaWorkIncome'] as num).toDouble(),
      totalGlobalIncome: (json['totalGlobalIncome'] as num).toDouble(),
      perCapitaGlobalIncome: (json['perCapitaGlobalIncome'] as num).toDouble(),
    );
  }
}

final class AgeProfileDetail {
  final int range0to6;
  final int range7to14;
  final int range15to17;
  final int range18to29;
  final int range30to59;
  final int range60to64;
  final int range65to69;
  final int range70Plus;
  final int totalMembers;

  const AgeProfileDetail({
    required this.range0to6,
    required this.range7to14,
    required this.range15to17,
    required this.range18to29,
    required this.range30to59,
    required this.range60to64,
    required this.range65to69,
    required this.range70Plus,
    required this.totalMembers,
  });

  factory AgeProfileDetail.fromJson(Map<String, dynamic> json) {
    return AgeProfileDetail(
      range0to6: json['range0to6'] as int,
      range7to14: json['range7to14'] as int,
      range15to17: json['range15to17'] as int,
      range18to29: json['range18to29'] as int,
      range30to59: json['range30to59'] as int,
      range60to64: json['range60to64'] as int,
      range65to69: json['range65to69'] as int,
      range70Plus: json['range70Plus'] as int,
      totalMembers: json['totalMembers'] as int,
    );
  }
}

final class EducationalVulnerabilitiesDetail {
  final int notInSchool0to5;
  final int notInSchool6to14;
  final int notInSchool15to17;
  final int illiteracy10to17;
  final int illiteracy18to59;
  final int illiteracy60Plus;

  const EducationalVulnerabilitiesDetail({
    required this.notInSchool0to5,
    required this.notInSchool6to14,
    required this.notInSchool15to17,
    required this.illiteracy10to17,
    required this.illiteracy18to59,
    required this.illiteracy60Plus,
  });

  factory EducationalVulnerabilitiesDetail.fromJson(Map<String, dynamic> json) {
    return EducationalVulnerabilitiesDetail(
      notInSchool0to5: json['notInSchool0to5'] as int,
      notInSchool6to14: json['notInSchool6to14'] as int,
      notInSchool15to17: json['notInSchool15to17'] as int,
      illiteracy10to17: json['illiteracy10to17'] as int,
      illiteracy18to59: json['illiteracy18to59'] as int,
      illiteracy60Plus: json['illiteracy60Plus'] as int,
    );
  }
}

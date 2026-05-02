import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computed_analytics_response.g.dart';

@JsonSerializable()
class ComputedAnalyticsResponse with Equatable {
  const ComputedAnalyticsResponse({
    this.housing,
    this.financial,
    this.ageProfile,
    this.educationalVulnerabilities,
  });

  factory ComputedAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$ComputedAnalyticsResponseFromJson(json);

  final HousingAnalyticsResponse? housing;
  final FinancialIndicatorsResponse? financial;
  final AgeProfileResponse? ageProfile;
  final EducationalVulnerabilityResponse? educationalVulnerabilities;

  Map<String, dynamic> toJson() => _$ComputedAnalyticsResponseToJson(this);

  @override
  List<Object?> get props => [
    housing,
    financial,
    ageProfile,
    educationalVulnerabilities,
  ];
}

@JsonSerializable()
class HousingAnalyticsResponse with Equatable {
  const HousingAnalyticsResponse({
    this.density = 0,
    this.isOvercrowded = false,
  });

  factory HousingAnalyticsResponse.fromJson(Map<String, dynamic> json) =>
      _$HousingAnalyticsResponseFromJson(json);

  final double density;
  final bool isOvercrowded;

  Map<String, dynamic> toJson() => _$HousingAnalyticsResponseToJson(this);

  @override
  List<Object?> get props => [density, isOvercrowded];
}

@JsonSerializable()
class FinancialIndicatorsResponse with Equatable {
  const FinancialIndicatorsResponse({
    this.totalWorkIncome = 0,
    this.perCapitaWorkIncome = 0,
    this.totalGlobalIncome = 0,
    this.perCapitaGlobalIncome = 0,
  });

  factory FinancialIndicatorsResponse.fromJson(Map<String, dynamic> json) =>
      _$FinancialIndicatorsResponseFromJson(json);

  final double totalWorkIncome;
  final double perCapitaWorkIncome;
  final double totalGlobalIncome;
  final double perCapitaGlobalIncome;

  Map<String, dynamic> toJson() => _$FinancialIndicatorsResponseToJson(this);

  @override
  List<Object?> get props => [
    totalWorkIncome,
    perCapitaWorkIncome,
    totalGlobalIncome,
    perCapitaGlobalIncome,
  ];
}

@JsonSerializable()
class AgeProfileResponse with Equatable {
  const AgeProfileResponse({
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

  factory AgeProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$AgeProfileResponseFromJson(json);

  final int range0to6;
  final int range7to14;
  final int range15to17;
  final int range18to29;
  final int range30to59;
  final int range60to64;
  final int range65to69;
  final int range70Plus;
  final int totalMembers;

  Map<String, dynamic> toJson() => _$AgeProfileResponseToJson(this);

  @override
  List<Object?> get props => [
    range0to6,
    range7to14,
    range15to17,
    range18to29,
    range30to59,
    range60to64,
    range65to69,
    range70Plus,
    totalMembers,
  ];
}

@JsonSerializable()
class EducationalVulnerabilityResponse with Equatable {
  const EducationalVulnerabilityResponse({
    this.notInSchool0to5 = 0,
    this.notInSchool6to14 = 0,
    this.notInSchool15to17 = 0,
    this.illiteracy10to17 = 0,
    this.illiteracy18to59 = 0,
    this.illiteracy60Plus = 0,
  });

  factory EducationalVulnerabilityResponse.fromJson(
    Map<String, dynamic> json,
  ) => _$EducationalVulnerabilityResponseFromJson(json);

  final int notInSchool0to5;
  final int notInSchool6to14;
  final int notInSchool15to17;
  final int illiteracy10to17;
  final int illiteracy18to59;
  final int illiteracy60Plus;

  Map<String, dynamic> toJson() =>
      _$EducationalVulnerabilityResponseToJson(this);

  @override
  List<Object?> get props => [
    notInSchool0to5,
    notInSchool6to14,
    notInSchool15to17,
    illiteracy10to17,
    illiteracy18to59,
    illiteracy60Plus,
  ];
}

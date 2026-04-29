import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

import 'social_benefit_response.dart';

part 'socio_economic_response.g.dart';

@JsonSerializable()
class SocioEconomicResponse with Equatable {
  const SocioEconomicResponse({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.hasUnemployed,
    this.socialBenefits = const [],
    this.mainSourceOfIncome,
  });

  factory SocioEconomicResponse.fromJson(Map<String, dynamic> json) =>
      _$SocioEconomicResponseFromJson(json);

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final List<SocialBenefitResponse> socialBenefits;
  final String? mainSourceOfIncome;
  final bool hasUnemployed;

  Map<String, dynamic> toJson() => _$SocioEconomicResponseToJson(this);

  @override
  List<Object?> get props => [
    totalFamilyIncome,
    incomePerCapita,
    receivesSocialBenefit,
    socialBenefits,
    mainSourceOfIncome,
    hasUnemployed,
  ];
}

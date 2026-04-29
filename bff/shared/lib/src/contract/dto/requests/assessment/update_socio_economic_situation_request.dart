import 'package:core_contracts/core_contracts.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_socio_economic_situation_request.g.dart';

@JsonSerializable()
class UpdateSocioEconomicSituationRequest with Equatable {
  const UpdateSocioEconomicSituationRequest({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.mainSourceOfIncome,
    required this.hasUnemployed,
    this.socialBenefits = const [],
  });

  factory UpdateSocioEconomicSituationRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateSocioEconomicSituationRequestFromJson(json);

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final List<SocialBenefitDraftDto> socialBenefits;
  final String mainSourceOfIncome;
  final bool hasUnemployed;

  Map<String, dynamic> toJson() =>
      _$UpdateSocioEconomicSituationRequestToJson(this);

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

@JsonSerializable()
class SocialBenefitDraftDto with Equatable {
  const SocialBenefitDraftDto({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
    this.benefitTypeId,
    this.birthCertificateNumber,
    this.deceasedCpf,
  });

  factory SocialBenefitDraftDto.fromJson(Map<String, dynamic> json) =>
      _$SocialBenefitDraftDtoFromJson(json);

  final String benefitName;
  final double amount;
  final String beneficiaryId;
  final String? benefitTypeId;
  final String? birthCertificateNumber;
  final String? deceasedCpf;

  Map<String, dynamic> toJson() => _$SocialBenefitDraftDtoToJson(this);

  @override
  List<Object?> get props => [
    benefitName,
    amount,
    beneficiaryId,
    benefitTypeId,
    birthCertificateNumber,
    deceasedCpf,
  ];
}

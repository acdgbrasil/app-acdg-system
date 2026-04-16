import 'package:json_annotation/json_annotation.dart';

part 'social_benefit_response.g.dart';

@JsonSerializable()
class SocialBenefitResponse {
  const SocialBenefitResponse({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
    this.benefitTypeId,
    this.birthCertificateNumber,
    this.deceasedCpf,
  });

  factory SocialBenefitResponse.fromJson(Map<String, dynamic> json) =>
      _$SocialBenefitResponseFromJson(json);

  final String benefitName;
  final double amount;
  final String beneficiaryId;
  final String? benefitTypeId;
  final String? birthCertificateNumber;
  final String? deceasedCpf;

  Map<String, dynamic> toJson() => _$SocialBenefitResponseToJson(this);
}

final class SocialBenefitDetail {
  final String benefitName;
  final double amount;
  final String beneficiaryId;

  const SocialBenefitDetail({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
  });

  factory SocialBenefitDetail.fromJson(Map<String, dynamic> json) {
    return SocialBenefitDetail(
      benefitName: json['benefitName'] as String,
      amount: (json['amount'] as num).toDouble(),
      beneficiaryId: json['beneficiaryId'] as String,
    );
  }
}

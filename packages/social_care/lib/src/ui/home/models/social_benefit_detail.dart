final class SocialBenefitDetail {
  final String benefitName;
  final String benefitTypeId;
  final double amount;
  final String beneficiaryId;
  final String? birthCertificateNumber;
  final String? deceasedCpf;

  const SocialBenefitDetail({
    required this.benefitName,
    required this.benefitTypeId,
    required this.amount,
    required this.beneficiaryId,
    this.birthCertificateNumber,
    this.deceasedCpf,
  });

  factory SocialBenefitDetail.fromJson(Map<String, dynamic> json) {
    return SocialBenefitDetail(
      benefitName: json['benefitName'] as String,
      benefitTypeId: json['benefitTypeId'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      beneficiaryId: json['beneficiaryId'] as String,
      birthCertificateNumber: json['birthCertificateNumber'] as String?,
      deceasedCpf: json['deceasedCpf'] as String?,
    );
  }
}

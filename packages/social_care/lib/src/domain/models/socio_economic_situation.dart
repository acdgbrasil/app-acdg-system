import 'package:core/core.dart';

/// Socio-economic situation of a patient's household.
class SocioEconomicSituation with Equatable {
  const SocioEconomicSituation({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.hasUnemployed,
    this.socialBenefits = const [],
    this.mainSourceOfIncome,
  });

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final bool hasUnemployed;
  final List<SocialBenefit> socialBenefits;
  final String? mainSourceOfIncome;

  SocioEconomicSituation copyWith({
    double? totalFamilyIncome,
    double? incomePerCapita,
    bool? receivesSocialBenefit,
    bool? hasUnemployed,
    List<SocialBenefit>? socialBenefits,
    String? mainSourceOfIncome,
  }) {
    return SocioEconomicSituation(
      totalFamilyIncome: totalFamilyIncome ?? this.totalFamilyIncome,
      incomePerCapita: incomePerCapita ?? this.incomePerCapita,
      receivesSocialBenefit:
          receivesSocialBenefit ?? this.receivesSocialBenefit,
      hasUnemployed: hasUnemployed ?? this.hasUnemployed,
      socialBenefits: socialBenefits ?? this.socialBenefits,
      mainSourceOfIncome: mainSourceOfIncome ?? this.mainSourceOfIncome,
    );
  }

  @override
  List<Object?> get props => [
    totalFamilyIncome,
    incomePerCapita,
    receivesSocialBenefit,
    hasUnemployed,
    socialBenefits,
    mainSourceOfIncome,
  ];
}

/// Single social benefit received by a [SocioEconomicSituation] or
/// [WorkAndIncome]. Shared VO to avoid duplication.
class SocialBenefit with Equatable {
  const SocialBenefit({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
    this.benefitTypeId,
    this.birthCertificateNumber,
    this.deceasedCpf,
  });

  final String benefitName;
  final double amount;
  final String beneficiaryId;
  final String? benefitTypeId;
  final String? birthCertificateNumber;
  final String? deceasedCpf;

  SocialBenefit copyWith({
    String? benefitName,
    double? amount,
    String? beneficiaryId,
    String? benefitTypeId,
    String? birthCertificateNumber,
    String? deceasedCpf,
  }) {
    return SocialBenefit(
      benefitName: benefitName ?? this.benefitName,
      amount: amount ?? this.amount,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      benefitTypeId: benefitTypeId ?? this.benefitTypeId,
      birthCertificateNumber:
          birthCertificateNumber ?? this.birthCertificateNumber,
      deceasedCpf: deceasedCpf ?? this.deceasedCpf,
    );
  }

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

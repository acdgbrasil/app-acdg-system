/// Socioeconomic situation assessment data.
final class SocioEconomicSituation {
  const SocioEconomicSituation({
    required this.totalFamilyIncome,
    required this.incomePerCapita,
    required this.receivesSocialBenefit,
    required this.hasUnemployed,
    required this.mainSourceOfIncome,
    required this.socialBenefits,
  });

  final double totalFamilyIncome;
  final double incomePerCapita;
  final bool receivesSocialBenefit;
  final bool hasUnemployed;
  final String mainSourceOfIncome;
  final List<SocialBenefit> socialBenefits;
}

/// A social benefit received by a family member.
final class SocialBenefit {
  const SocialBenefit({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
  });

  final String benefitName;
  final double amount;
  final String beneficiaryId;
}

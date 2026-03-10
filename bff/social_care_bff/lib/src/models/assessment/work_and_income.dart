/// Work and income assessment data.
final class WorkAndIncome {
  const WorkAndIncome({
    required this.hasRetiredMembers,
    required this.individualIncomes,
    required this.socialBenefits,
  });

  final bool hasRetiredMembers;
  final List<IndividualIncome> individualIncomes;
  final List<WorkSocialBenefit> socialBenefits;
}

/// Individual income entry for a family member.
final class IndividualIncome {
  const IndividualIncome({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;
}

/// Social benefit in the work and income context.
final class WorkSocialBenefit {
  const WorkSocialBenefit({
    required this.benefitName,
    required this.amount,
    required this.beneficiaryId,
  });

  final String benefitName;
  final double amount;
  final String beneficiaryId;
}

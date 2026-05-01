import 'package:core/core.dart';

import 'socio_economic_situation.dart';

/// Work and income assessment for the household (ficha Trabalho e Renda).
class WorkAndIncome with Equatable {
  const WorkAndIncome({
    required this.hasRetiredMembers,
    this.individualIncomes = const [],
    this.socialBenefits = const [],
  });

  final bool hasRetiredMembers;
  final List<WorkIncome> individualIncomes;
  final List<SocialBenefit> socialBenefits;

  WorkAndIncome copyWith({
    bool? hasRetiredMembers,
    List<WorkIncome>? individualIncomes,
    List<SocialBenefit>? socialBenefits,
  }) {
    return WorkAndIncome(
      hasRetiredMembers: hasRetiredMembers ?? this.hasRetiredMembers,
      individualIncomes: individualIncomes ?? this.individualIncomes,
      socialBenefits: socialBenefits ?? this.socialBenefits,
    );
  }

  @override
  List<Object?> get props => [
    hasRetiredMembers,
    individualIncomes,
    socialBenefits,
  ];
}

/// Individual income entry tied to a family member.
class WorkIncome with Equatable {
  const WorkIncome({
    required this.memberId,
    required this.occupationId,
    required this.hasWorkCard,
    required this.monthlyAmount,
  });

  final String memberId;
  final String occupationId;
  final bool hasWorkCard;
  final double monthlyAmount;

  WorkIncome copyWith({
    String? memberId,
    String? occupationId,
    bool? hasWorkCard,
    double? monthlyAmount,
  }) {
    return WorkIncome(
      memberId: memberId ?? this.memberId,
      occupationId: occupationId ?? this.occupationId,
      hasWorkCard: hasWorkCard ?? this.hasWorkCard,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    occupationId,
    hasWorkCard,
    monthlyAmount,
  ];
}

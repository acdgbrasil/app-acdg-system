import 'dart:math';
import 'package:core/core.dart';
import '../assessment/assessment_vos.dart';
import '../assessment/work_and_income.dart';

/// Data structure for calculated financial indicators.
final class FinancialIndicators with Equatable {
  const FinancialIndicators({
    required this.totalWorkIncome,
    required this.perCapitaWorkIncome,
    required this.totalGlobalIncome,
    required this.perCapitaGlobalIncome,
  });

  final double totalWorkIncome;
  final double perCapitaWorkIncome;
  final double totalGlobalIncome;
  final double perCapitaGlobalIncome;

  @override
  List<Object?> get props => [
    totalWorkIncome,
    perCapitaWorkIncome,
    totalGlobalIncome,
    perCapitaGlobalIncome,
  ];
}

/// Service for calculating financial indicators based on household income and benefits.
abstract final class FinancialAnalyticsService {
  /// Calculates indicators using work incomes and social benefits.
  static FinancialIndicators calculate({
    required List<WorkIncomeVO> workIncomes,
    required List<SocialBenefit> socialBenefits,
    required int memberCount,
  }) {
    final totalWorkIncome = workIncomes.fold(
      0.0,
      (sum, item) => sum + item.monthlyAmount,
    );
    final totalBenefits = socialBenefits.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final divisor = max(memberCount, 1);

    return FinancialIndicators(
      totalWorkIncome: totalWorkIncome,
      perCapitaWorkIncome: totalWorkIncome / divisor,
      totalGlobalIncome: totalWorkIncome + totalBenefits,
      perCapitaGlobalIncome: (totalWorkIncome + totalBenefits) / divisor,
    );
  }
}

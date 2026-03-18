import 'package:shared/src/domain/analytics/financial_analytics_service.dart';
import 'package:shared/src/domain/assessment/assessment_vos.dart';
import 'package:shared/src/domain/assessment/work_and_income.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:test/test.dart';

void main() {
  group('FinancialAnalyticsService - Cálculos', () {
    final personId = PersonId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;

    test('Deve calcular indicadores financeiros corretamente', () {
      final workIncomes = [
        WorkIncomeVO.create(memberId: personId, occupationId: LookupId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!, hasWorkCard: true, monthlyAmount: 1000).valueOrNull!,
        WorkIncomeVO.create(memberId: personId, occupationId: LookupId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!, hasWorkCard: true, monthlyAmount: 500).valueOrNull!,
      ];

      final socialBenefits = [
        SocialBenefit.create(benefitName: 'BPC', amount: 600, beneficiaryId: personId).valueOrNull!,
      ];

      final result = FinancialAnalyticsService.calculate(
        workIncomes: workIncomes,
        socialBenefits: socialBenefits,
        memberCount: 4,
      );

      expect(result.totalWorkIncome, 1500.0);
      expect(result.perCapitaWorkIncome, 375.0);
      expect(result.totalGlobalIncome, 2100.0);
      expect(result.perCapitaGlobalIncome, 525.0);
    });
  });
}

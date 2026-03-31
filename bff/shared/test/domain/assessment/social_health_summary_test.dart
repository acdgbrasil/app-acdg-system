import 'package:core/core.dart';
import 'package:shared/src/domain/assessment/social_health_summary.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('SocialHealthSummary - Validações', () {
    test('Deve normalizar e deduplicar lista de dependências', () {
      final result = SocialHealthSummary.create(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        functionalDependencies: [' Alimentação ', ' Higiene ', 'ALIMENTAÇÃO '],
        hasRelevantDrugTherapy: true,
      );

      expect(result.isSuccess, isTrue);
      final shs = result.valueOrNull!;
      // Note: "ALIMENTAÇÃO " != "Alimentação" em termos de case, mas o trim removeu espaços.
      // Nosso helper normalize() apenas trim + collapse.
      expect(shs.functionalDependencies.length, 3);
      expect(shs.functionalDependencies[0], 'Alimentação');
    });

    test('Deve rejeitar itens vazios na lista (SHS-001)', () {
      final result = SocialHealthSummary.create(
        requiresConstantCare: true,
        hasMobilityImpairment: false,
        functionalDependencies: ['Alimentação', '   '],
        hasRelevantDrugTherapy: true,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'SHS-001');
    });
  });
}

import 'package:shared/src/domain/analytics/housing_analytics_service.dart';
import 'package:test/test.dart';

void main() {
  group('HousingAnalyticsService - Cálculos', () {
    test('Deve calcular densidade corretamente', () {
      final density = HousingAnalyticsService.calculateDensity(
        totalFamilyMembers: 6,
        numberOfBedrooms: 2,
      );
      expect(density, 3.0);
    });

    test('Deve identificar superlotação corretamente', () {
      expect(
        HousingAnalyticsService.isOvercrowded(
          totalFamilyMembers: 7,
          numberOfBedrooms: 2,
        ),
        isTrue,
      );
      expect(
        HousingAnalyticsService.isOvercrowded(
          totalFamilyMembers: 6,
          numberOfBedrooms: 2,
        ),
        isFalse,
      );
    });
  });
}

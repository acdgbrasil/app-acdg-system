import 'package:core/core.dart';
import 'package:shared/src/domain/assessment/assessment_vos.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('HousingCondition - Validações', () {
    test('Deve criar com sucesso quando invariantes são respeitadas', () {
      final result = HousingCondition.create(
        type: ConditionType.owned,
        wallMaterial: WallMaterial.masonry,
        numberOfRooms: 5,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: WaterSupply.publicNetwork,
        hasPipedWater: true,
        electricityAccess: ElectricityAccess.meteredConnection,
        sewageDisposal: SewageDisposal.publicSewer,
        wasteCollection: WasteCollection.directCollection,
        accessibilityLevel: AccessibilityLevel.fullyAccessible,
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );

      expect(result.isSuccess, isTrue);
    });

    test('Deve rejeitar número de quartos superior ao de cômodos (HC-004)', () {
      final result = HousingCondition.create(
        type: ConditionType.owned,
        wallMaterial: WallMaterial.masonry,
        numberOfRooms: 3,
        numberOfBedrooms: 5, // Inválido
        numberOfBathrooms: 1,
        waterSupply: WaterSupply.publicNetwork,
        hasPipedWater: true,
        electricityAccess: ElectricityAccess.meteredConnection,
        sewageDisposal: SewageDisposal.publicSewer,
        wasteCollection: WasteCollection.directCollection,
        accessibilityLevel: AccessibilityLevel.fullyAccessible,
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'HC-004');
    });
  });

  group('SocialBenefit - Validações', () {
    final personId = PersonId.create(
      '550e8400-e29b-41d4-a716-446655440000',
    ).valueOrNull!;

    test('Deve rejeitar valor zero ou negativo (SB-002)', () {
      final result = SocialBenefit.create(
        benefitName: 'BPC',
        amount: 0,
        beneficiaryId: personId,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'SB-002');
    });
  });

  group('SocioEconomicSituation - Validações', () {
    final benefits = SocialBenefitsCollection.create([]).valueOrNull!;

    test('Deve rejeitar renda per capita superior à total (SES-006)', () {
      final result = SocioEconomicSituation.create(
        totalFamilyIncome: 1000,
        incomePerCapita: 1500, // Inválido
        receivesSocialBenefit: false,
        socialBenefits: benefits,
        mainSourceOfIncome: 'Trabalho',
        hasUnemployed: false,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'SES-006');
    });

    test(
      'Deve rejeitar inconsistência entre flag e lista de benefícios (SES-002)',
      () {
        final result = SocioEconomicSituation.create(
          totalFamilyIncome: 1000,
          incomePerCapita: 500,
          receivesSocialBenefit: true, // Diz que recebe
          socialBenefits: benefits, // Mas a lista está vazia
          mainSourceOfIncome: 'Trabalho',
          hasUnemployed: false,
        );

        expect(result.isFailure, isTrue);
        expect(((result as Failure).error as AppError).code, 'SES-002');
      },
    );
  });
}

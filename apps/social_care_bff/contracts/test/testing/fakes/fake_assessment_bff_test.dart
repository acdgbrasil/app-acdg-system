import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAssessmentBff', () {
    test('implements AssessmentContract', () {
      final AssessmentContract fake = FakeAssessmentBff();
      expect(fake, isA<AssessmentContract>());
    });

    test('updateHousingCondition: returns Success', () async {
      final fake = FakeAssessmentBff();
      final request = UpdateHousingConditionRequest(
        type: 'own',
        wallMaterial: 'brick',
        numberOfRooms: 3,
        numberOfBedrooms: 2,
        numberOfBathrooms: 1,
        waterSupply: 'public',
        hasPipedWater: true,
        electricityAccess: 'regular',
        sewageDisposal: 'public',
        wasteCollection: 'regular',
        accessibilityLevel: 'full',
        isInGeographicRiskArea: false,
        hasDifficultAccess: false,
        isInSocialConflictArea: false,
        hasDiagnosticObservations: false,
      );

      final result = await fake.updateHousingCondition('patient-1', request);

      expect(result, isA<Success<void>>());
    });
  });
}

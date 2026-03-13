import 'package:core/core.dart';
import 'package:shared/src/domain/assessment/community_support.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('CommunitySupportNetwork - Validações', () {
    test('Deve rejeitar conflitos familiares muito longos (CSN-002)', () {
      final longText = 'a' * 301;
      final result = CommunitySupportNetwork.create(
        hasRelativeSupport: true,
        hasNeighborSupport: true,
        familyConflicts: longText,
        patientParticipatesInGroups: true,
        familyParticipatesInGroups: true,
        patientHasAccessToLeisure: true,
        facesDiscrimination: false,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CSN-002');
    });
  });
}

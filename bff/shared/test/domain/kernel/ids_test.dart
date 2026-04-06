import 'package:core_contracts/core_contracts.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('IDs - Validações', () {
    const validUuid = '550e8400-e29b-41d4-a716-446655440000';

    test('Deve criar PersonId válido e normalizar', () {
      final result = PersonId.create(
        '  550E8400-E29B-41D4-A716-446655440000  ',
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, validUuid);
    });

    test('Deve rejeitar PersonId vazio', () {
      final result = PersonId.create('');
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'PID-001');
    });

    test('Deve rejeitar formato inválido', () {
      final result = PersonId.create('invalid-uuid');
      expect(result.isFailure, isTrue);
    });

    test('Testa todos os tipos de ID com UUID válido', () {
      expect(ProfessionalId.create(validUuid).isSuccess, isTrue);
      expect(PatientId.create(validUuid).isSuccess, isTrue);
      expect(LookupId.create(validUuid).isSuccess, isTrue);
      expect(AppointmentId.create(validUuid).isSuccess, isTrue);
      expect(ReferralId.create(validUuid).isSuccess, isTrue);
      expect(ViolationReportId.create(validUuid).isSuccess, isTrue);
    });
  });
}

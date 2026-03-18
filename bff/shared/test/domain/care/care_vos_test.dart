import 'package:core/core.dart';
import 'package:shared/src/domain/care/care_vos.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('IcdCode - Validações', () {
    test('Deve inserir ponto automaticamente (auto-dot)', () {
      final result = IcdCode.create('A169');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, 'A16.9');
    });

    test('Deve manter ponto existente', () {
      final result = IcdCode.create('B20.1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, 'B20.1');
    });

    test('isEquivalent compara corretamente', () {
      final a = IcdCode.create('A16.9').valueOrNull!;
      final b = IcdCode.create('A169').valueOrNull!;
      expect(a.isEquivalent(b), isTrue);
    });
  });

  group('SocialCareAppointment - Validações', () {
    final id = AppointmentId.create('550e8400-e29b-41d4-a716-446655440000').valueOrNull!;
    final profId = ProfessionalId.create('550e8400-e29b-41d4-a716-446655440001').valueOrNull!;
    final date = TimeStamp.now;

    test('Deve rejeitar quando resumo e plano de ação estão vazios (SCA-003)', () {
      final result = SocialCareAppointment.create(
        id: id,
        date: date,
        professionalInChargeId: profId,
        type: AppointmentType.homeVisit,
        summary: '   ',
        actionPlan: null,
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'SCA-003');
    });
  });
}

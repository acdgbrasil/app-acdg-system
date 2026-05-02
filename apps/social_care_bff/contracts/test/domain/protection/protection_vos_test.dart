import 'package:core_contracts/core_contracts.dart';
import 'package:shared/src/domain/protection/protection_vos.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('Referral - Máquina de Estado', () {
    final id = ReferralId.create(
      '550e8400-e29b-41d4-a716-446655440000',
    ).valueOrNull!;
    final profId = ProfessionalId.create(
      '550e8400-e29b-41d4-a716-446655440001',
    ).valueOrNull!;
    final personId = PersonId.create(
      '550e8400-e29b-41d4-a716-446655440002',
    ).valueOrNull!;
    final date = TimeStamp.now;

    test('Deve transitar de PENDING para COMPLETED', () {
      final ref = Referral.create(
        id: id,
        date: date,
        requestingProfessionalId: profId,
        referredPersonId: personId,
        destinationService: DestinationService.cras,
        reason: 'Teste',
      ).valueOrNull!;

      expect(ref.status, ReferralStatus.pending);

      final completed = ref.complete().valueOrNull!;
      expect(completed.status, ReferralStatus.completed);
    });

    test('Deve rejeitar transição a partir de estado final (REF-003)', () {
      final ref = Referral.create(
        id: id,
        date: date,
        requestingProfessionalId: profId,
        referredPersonId: personId,
        destinationService: DestinationService.cras,
        reason: 'Teste',
        status: ReferralStatus.completed,
      ).valueOrNull!;

      final result = ref.cancel();
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'REF-003');
    });
  });

  group('RightsViolationReport - Validações', () {
    final id = ViolationReportId.create(
      '550e8400-e29b-41d4-a716-446655440000',
    ).valueOrNull!;
    final victimId = PersonId.create(
      '550e8400-e29b-41d4-a716-446655440001',
    ).valueOrNull!;
    final reportDate = TimeStamp.fromIso(
      '2025-01-01T00:00:00.000Z',
    ).valueOrNull!;

    test('Deve rejeitar incidente posterior à notificação (RVR-002)', () {
      final incidentDate = TimeStamp.fromIso(
        '2025-06-01T00:00:00.000Z',
      ).valueOrNull!;

      final result = RightsViolationReport.create(
        id: id,
        reportDate: reportDate,
        incidentDate: incidentDate,
        victimId: victimId,
        violationType: ViolationType.neglect,
        descriptionOfFact: 'Teste',
      );

      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RVR-002');
    });
  });
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/src/domain/kernel/ids.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/domain/registry/registry_vos.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('PersonalData - Validações', () {
    final validDate = TimeStamp.fromIso(
      '1990-01-01T00:00:00.000Z',
    ).valueOrNull!;
    final now = TimeStamp.fromIso('2026-03-12T00:00:00.000Z').valueOrNull!;

    test('Deve criar com dados válidos e normalizar nomes', () {
      final result = PersonalData.create(
        firstName: '  Maria   Luísa  ',
        lastName: '  da   Silva  ',
        motherName: '  Ana   Maria  ',
        nationality: '  Brasileira  ',
        sex: Sex.feminino,
        birthDate: validDate,
        now: now,
      );

      expect(result.isSuccess, isTrue);
      final pd = result.valueOrNull!;
      expect(pd.firstName, 'Maria Luísa');
      expect(pd.lastName, 'da Silva');
      expect(pd.motherName, 'Ana Maria');
      expect(pd.nationality, 'Brasileira');
    });

    test('Deve tratar campos opcionais vazios como nulos', () {
      final result = PersonalData.create(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana',
        nationality: 'BR',
        sex: Sex.feminino,
        socialName: '   ',
        phone: '  ',
        birthDate: validDate,
        now: now,
      );

      final pd = result.valueOrNull!;
      expect(pd.socialName, isNull);
      expect(pd.phone, isNull);
    });

    test('Deve rejeitar nome vazio', () {
      final result = PersonalData.create(
        firstName: '',
        lastName: 'Silva',
        motherName: 'Ana',
        nationality: 'BR',
        sex: Sex.feminino,
        birthDate: validDate,
        now: now,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'PDT-001');
    });

    test('Deve rejeitar data de nascimento no futuro', () {
      final future = TimeStamp.fromIso('2030-01-01T00:00:00.000Z').valueOrNull!;
      final result = PersonalData.create(
        firstName: 'Maria',
        lastName: 'Silva',
        motherName: 'Ana',
        nationality: 'BR',
        sex: Sex.feminino,
        birthDate: future,
        now: now,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'PDT-004');
    });
  });

  group('CivilDocuments - Validações', () {
    test('Deve rejeitar quando nenhum documento é fornecido', () {
      final result = CivilDocuments.create();
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CVD-001');
    });
  });

  group('SocialIdentity - Validações', () {
    final typeId = LookupId.create(
      '550e8400-e29b-41d4-a716-446655440000',
    ).valueOrNull!;

    test('Deve rejeitar tipo Outras sem descrição', () {
      final result = SocialIdentity.create(
        typeId: typeId,
        isOtherType: true,
        otherDescription: '   ',
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'SID-003');
    });
  });
}

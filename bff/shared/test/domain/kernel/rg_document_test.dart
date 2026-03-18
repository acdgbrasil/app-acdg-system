import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/rg_document.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('RGDocument - Validações', () {
    late TimeStamp validDate;
    late TimeStamp now;

    setUp(() {
      validDate = TimeStamp.fromIso('2020-01-01T00:00:00.000Z').valueOrNull!;
      now = TimeStamp.fromIso('2026-03-12T00:00:00.000Z').valueOrNull!;
    });

    test('Deve criar RG válido (check digit numérico)', () {
      // 1*2 + 2*3 + 3*4 + 4*5 + 5*6 + 6*7 + 7*8 + 8*9
      // 2 + 6 + 12 + 20 + 30 + 42 + 56 + 72 = 240
      // 240 % 11 = 9
      // 11 - 9 = 2. Logo o check digit esperado é 2.
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'sp',
        issuingAgency: '  ssp   sp  ',
        issueDate: validDate,
        now: now,
      );
      
      expect(result.isSuccess, isTrue);
      final rg = result.valueOrNull!;
      expect(rg.number, '123456782');
      expect(rg.issuingState, 'SP');
      expect(rg.issuingAgency, 'SSP SP');
      expect(rg.formattedNumber, '12345678-2');
    });

    test('Deve rejeitar número vazio', () {
      final result = RgDocument.create(number: ' ', issuingState: 'SP', issuingAgency: 'SSP', issueDate: validDate, now: now);
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-001');
    });

    test('Deve rejeitar formato inválido', () {
      final result = RgDocument.create(number: '123', issuingState: 'SP', issuingAgency: 'SSP', issueDate: validDate, now: now);
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-005');
    });

    test('Deve rejeitar check digit inválido', () {
      final result = RgDocument.create(number: '12345678-3', issuingState: 'SP', issuingAgency: 'SSP', issueDate: validDate, now: now);
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-006');
    });

    test('Deve rejeitar estado inválido', () {
      final result = RgDocument.create(number: '12345678-2', issuingState: 'XX', issuingAgency: 'SSP', issueDate: validDate, now: now);
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-002');
    });

    test('Deve rejeitar data no futuro', () {
      final futureDate = TimeStamp.fromIso('2030-01-01T00:00:00.000Z').valueOrNull!;
      final result = RgDocument.create(number: '12345678-2', issuingState: 'SP', issuingAgency: 'SSP', issueDate: futureDate, now: now);
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-004');
    });
  });
}

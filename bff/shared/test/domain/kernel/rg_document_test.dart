import 'package:core_contracts/core_contracts.dart';
import 'package:shared/src/domain/kernel/rg_document.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('RGDocument - Validações (alinhadas ao contrato OpenAPI)', () {
    late TimeStamp validDate;

    setUp(() {
      validDate = TimeStamp.fromIso('2020-01-01T00:00:00.000Z').valueOrNull!;
    });

    test('Aceita RG livre — sem regex/check digit', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'sp',
        issuingAgency: '  ssp   sp  ',
        issueDate: validDate,
      );

      expect(result.isSuccess, isTrue);
      final rg = result.valueOrNull!;
      expect(rg.number, '123456782');
      expect(rg.issuingState, 'SP');
      expect(rg.issuingAgency, 'SSP SP');
    });

    test('Aceita formato curto (3 chars) — número é livre', () {
      final result = RgDocument.create(
        number: '123',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.number, '123');
    });

    test('Aceita check digit "errado" — sem cálculo', () {
      final result = RgDocument.create(
        number: '12345678-3',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
      );
      expect(result.isSuccess, isTrue);
    });

    test('Aceita UF fora da whitelist — sem enum', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'XX',
        issuingAgency: 'SSP',
        issueDate: validDate,
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.issuingState, 'XX');
    });

    test('Aceita data no futuro — sem regra not_future', () {
      final futureDate = TimeStamp.fromIso(
        '2099-01-01T00:00:00.000Z',
      ).valueOrNull!;
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: futureDate,
      );
      expect(result.isSuccess, isTrue);
    });

    // Os 4 campos seguem obrigatórios pelo contrato OpenAPI
    // (RegisterPatientRequest.rgDocument.required = [number, issuingState,
    // issuingAgency, issueDate]).

    test('Rejeita número vazio', () {
      final result = RgDocument.create(
        number: ' ',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-001');
    });

    test('Rejeita UF vazia', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: '   ',
        issuingAgency: 'SSP',
        issueDate: validDate,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-002');
    });

    test('Rejeita órgão emissor vazio', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'SP',
        issuingAgency: '   ',
        issueDate: validDate,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-003');
    });

    test('Rejeita data nula', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: null,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-004');
    });
  });
}

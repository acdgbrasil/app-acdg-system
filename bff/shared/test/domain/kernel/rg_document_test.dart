import 'package:core_contracts/core_contracts.dart';
import 'package:shared/src/domain/kernel/rg_document.dart';
import 'package:shared/src/domain/kernel/time_stamp.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

/// Alinhado com `fix(domain)!: relax RGDocument validation` do backend Swift.
/// RG não tem padrão nacional — aceitar alfanumérico 4–15 caracteres.
void main() {
  group('RgDocument - Validações relaxadas (alinhamento Swift)', () {
    late TimeStamp validDate;
    late TimeStamp now;

    setUp(() {
      validDate = TimeStamp.fromIso('2020-01-01T00:00:00.000Z').valueOrNull!;
      now = TimeStamp.fromIso('2026-03-12T00:00:00.000Z').valueOrNull!;
    });

    // ─── Felizes ───────────────────────────────────────────────────────────

    test('aceita RG numérico clássico (9 dígitos) — formato SP antigo', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'sp',
        issuingAgency: '  ssp   sp  ',
        issueDate: validDate,
        now: now,
      );

      expect(result.isSuccess, isTrue);
      final rg = result.valueOrNull!;
      expect(rg.number, '123456782'); // compacto, sem separadores
      expect(rg.issuingState, 'SP');
      expect(rg.issuingAgency, 'SSP SP');
    });

    test('aceita RG alfanumérico (formato RJ, MG, etc.)', () {
      final result = RgDocument.create(
        number: 'MG12.345.678',
        issuingState: 'MG',
        issuingAgency: 'SSP MG',
        issueDate: validDate,
        now: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.number, 'MG12345678');
    });

    test('aceita RG curto (4 caracteres, limite inferior)', () {
      final result = RgDocument.create(
        number: '1234',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
        now: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.number, '1234');
    });

    test('aceita RG longo (15 caracteres, limite superior)', () {
      final result = RgDocument.create(
        number: '123456789012345',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
        now: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.number, '123456789012345');
    });

    test(
      'aceita RG com separadores variados — normaliza para compacto uppercase',
      () {
        final result = RgDocument.create(
          number: 'mg-12.345 678',
          issuingState: 'MG',
          issuingAgency: 'SSP',
          issueDate: validDate,
          now: now,
        );

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull!.number, 'MG12345678');
      },
    );

    // ─── Tristes ───────────────────────────────────────────────────────────

    test('rejeita número vazio com RGD-001', () {
      final result = RgDocument.create(
        number: ' ',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
        now: now,
      );
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'RGD-001');
    });

    test('rejeita RG curto demais (3 caracteres) com RGD-005 + mask em PII', () {
      final result = RgDocument.create(
        number: '123',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: validDate,
        now: now,
      );
      expect(result.isFailure, isTrue);
      final error = (result as Failure).error as AppError;
      expect(error.code, 'RGD-005');

      // PII masking: context expõe apenas metadados seguros.
      expect(error.context['providedLength'], 3);
      expect(error.context.containsKey('number'), isFalse);
      // safeContext carrega a versão mascarada para correlação em logs.
      expect(error.safeContext?['maskedNumber'], '***');
    });

    test(
      'rejeita caracteres inválidos (símbolos) com RGD-005 + mask coerente',
      () {
        final result = RgDocument.create(
          number: 'ABC!@#123',
          issuingState: 'SP',
          issuingAgency: 'SSP',
          issueDate: validDate,
          now: now,
        );
        expect(result.isFailure, isTrue);
        final error = (result as Failure).error as AppError;
        expect(error.code, 'RGD-005');
        // `!@#` não são separadores, ficam e invalidam.
        expect(error.context['providedLength'], 9);
      },
    );

    test('rejeita UF inválida com RGD-002', () {
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'XX',
        issuingAgency: 'SSP',
        issueDate: validDate,
        now: now,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-002');
    });

    test('rejeita data no futuro com RGD-004', () {
      final futureDate =
          TimeStamp.fromIso('2030-01-01T00:00:00.000Z').valueOrNull!;
      final result = RgDocument.create(
        number: '12345678-2',
        issuingState: 'SP',
        issuingAgency: 'SSP',
        issueDate: futureDate,
        now: now,
      );
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'RGD-004');
    });
  });
}

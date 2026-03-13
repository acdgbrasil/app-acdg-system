import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/cpf.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('CPF - Validações', () {
    test('Deve criar CPF válido a partir de string formatada', () {
      final result = Cpf.create('529.982.247-25');
      expect(result.isSuccess, isTrue);
      final cpf = result.valueOrNull!;
      expect(cpf.value, '52998224725');
      expect(cpf.formatted, '529.982.247-25');
      expect(cpf.fiscalRegion, FiscalRegion.region7);
    });

    test('Deve rejeitar CPF vazio', () {
      final result = Cpf.create('   ');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CPF-001');
    });

    test('Deve rejeitar CPF com caracteres inválidos', () {
      final result = Cpf.create('529.982.247-2A');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CPF-005');
    });

    test('Deve rejeitar CPF com tamanho incorreto', () {
      final result = Cpf.create('1234567890');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CPF-002');
    });

    test('Deve rejeitar CPF com todos dígitos iguais', () {
      final result = Cpf.create('111.111.111-11');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CPF-003');
    });

    test('Deve rejeitar CPF com dígitos verificadores inválidos', () {
      final result = Cpf.create('529.982.247-26');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CPF-004');
    });
  });
}

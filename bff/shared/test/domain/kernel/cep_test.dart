import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/cep.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('CEP - Validações', () {
    test('Deve criar CEP válido a partir de string formatada', () {
      final result = Cep.create('01310-100');
      expect(result.isSuccess, isTrue);
      final cep = result.valueOrNull!;
      expect(cep.value, '01310100');
      expect(cep.formatted, '01310-100');
      expect(cep.distributionKind, DistributionKind.streetRange);
    });

    test('Deve rejeitar CEP vazio', () {
      final result = Cep.create('   ');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CEP-001');
    });

    test('Deve rejeitar CEP com caracteres inválidos', () {
      final result = Cep.create('0131A-100');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CEP-002');
    });

    test('Deve rejeitar CEP com tamanho incorreto', () {
      final result = Cep.create('01310-10');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CEP-003');
    });

    test('Deve rejeitar CEP fora da faixa estadual válida', () {
      final result = Cep.create('00000-000');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'CEP-004');
    });
  });
}

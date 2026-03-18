import 'package:core/core.dart';
import 'package:shared/src/domain/kernel/nis.dart';
import 'package:shared/src/utils/app_error.dart';
import 'package:test/test.dart';

void main() {
  group('NIS - Validações', () {
    test('Deve criar NIS válido a partir de string formatada', () {
      final result = Nis.create('120.66020.58-5');
      expect(result.isSuccess, isTrue);
      final nis = result.valueOrNull!;
      expect(nis.value, '12066020585');
      expect(nis.formatted, '120.66020.58-5');
    });

    test('Deve rejeitar NIS vazio', () {
      final result = Nis.create('   ');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'NIS-001');
    });

    test('Deve rejeitar NIS com tamanho incorreto', () {
      final result = Nis.create('1234567890');
      expect(result.isFailure, isTrue);
      expect(((result as Failure).error as AppError).code, 'NIS-002');
    });
  });
}

import 'package:core/core.dart';
import 'package:shared/src/domain/value_objects/cpf.dart';
import 'package:test/test.dart';

void main() {
  group('Cpf Value Object', () {
    test('creates successfully for a valid CPF', () {
      final validCpf = '52998224725'; 
      final result = Cpf.create(validCpf);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, validCpf);
      expect(result.valueOrNull!.formatted, '529.982.247-25');
    });

    test('fails for empty input', () {
      final result = Cpf.create('');
      expect(result.isFailure, isTrue);
      expect((result as Failure).error, 'O CPF não pode estar vazio.');
    });

    test('fails for invalid length', () {
      final result = Cpf.create('123');
      expect(result.isFailure, isTrue);
      expect((result as Failure).error, 'O CPF deve conter exatamente 11 dígitos.');
    });

    test('fails for blacklisted sequence', () {
      final result = Cpf.create('111.111.111-11');
      expect(result.isFailure, isTrue);
      expect((result as Failure).error, 'CPF inválido.');
    });

    test('fails for invalid checksum', () {
      final result = Cpf.create('52998224726'); // Altered last digit
      expect(result.isFailure, isTrue);
    });
  });
}

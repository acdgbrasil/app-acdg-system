import 'package:shared/src/domain/value_objects/cep.dart';
import 'package:test/test.dart';

void main() {
  group('Cep Value Object', () {
    test('creates successfully for a valid CEP', () {
      final result = Cep.create('01001-000'); // Praça da Sé
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, '01001000');
      expect(result.valueOrNull!.formatted, '01001-000');
    });

    test('fails for empty input', () {
      final result = Cep.create(null);
      expect(result.isFailure, isTrue);
    });

    test('fails for invalid length', () {
      final result = Cep.create('1234567');
      expect(result.isFailure, isTrue);
    });

    test('ignores non-digit characters', () {
      final result = Cep.create('A01.001-000');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.value, '01001000');
    });
  });
}

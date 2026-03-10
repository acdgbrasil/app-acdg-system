import 'package:social_care_bff/social_care_bff.dart';
import 'package:test/test.dart';

void main() {
  group('Cpf', () {
    test('valid 11-digit CPF', () {
      const cpf = Cpf('12345678901');
      expect(cpf.isValid, isTrue);
      expect(cpf.value, '12345678901');
    });

    test('formatted output', () {
      const cpf = Cpf('12345678901');
      expect(cpf.formatted, '123.456.789-01');
    });

    test('invalid CPF returns raw value in formatted', () {
      const cpf = Cpf('123');
      expect(cpf.isValid, isFalse);
      expect(cpf.formatted, '123');
    });

    test('equality by value', () {
      const a = Cpf('12345678901');
      const b = Cpf('12345678901');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality', () {
      const a = Cpf('12345678901');
      const b = Cpf('98765432100');
      expect(a, isNot(equals(b)));
    });

    test('toString', () {
      const cpf = Cpf('12345678901');
      expect(cpf.toString(), 'Cpf(12345678901)');
    });
  });

  group('Nis', () {
    test('valid 11-digit NIS', () {
      const nis = Nis('12345678901');
      expect(nis.isValid, isTrue);
    });

    test('formatted output', () {
      const nis = Nis('12345678901');
      expect(nis.formatted, '123.45678.90-1');
    });

    test('invalid NIS', () {
      const nis = Nis('abc');
      expect(nis.isValid, isFalse);
      expect(nis.formatted, 'abc');
    });

    test('equality by value', () {
      const a = Nis('12345678901');
      const b = Nis('12345678901');
      expect(a, equals(b));
    });
  });

  group('Cep', () {
    test('valid 8-digit CEP', () {
      const cep = Cep('01310100');
      expect(cep.isValid, isTrue);
    });

    test('formatted output', () {
      const cep = Cep('01310100');
      expect(cep.formatted, '01310-100');
    });

    test('invalid CEP', () {
      const cep = Cep('123');
      expect(cep.isValid, isFalse);
      expect(cep.formatted, '123');
    });

    test('equality by value', () {
      const a = Cep('01310100');
      const b = Cep('01310100');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString', () {
      const cep = Cep('01310100');
      expect(cep.toString(), 'Cep(01310100)');
    });
  });
}

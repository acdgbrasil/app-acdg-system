import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `Cpf` as an `extension type`:
///   - `Cpf.create(String?)` → `Result<Cpf>`
///   - `Cpf.trusted(String)` zero-cost constructor for trusted origins
///   - `toString()` returning the raw value
///   - native value equality via the wrapped String
///
/// Current state (A06c): `Cpf` is a `final class with Equatable`.
/// The `.trusted` named constructor does NOT exist yet — compile RED expected.
void main() {
  group('Cpf (extension type)', () {
    // Real valid CPF (mod11 verifier digits check out).
    const validCpf = '52998224725';
    // Same digits, last one flipped — breaks mod11.
    const invalidCpf = '52998224726';

    test('create(valid) returns Success', () {
      final result = Cpf.create(validCpf);
      expect(result, isA<Success<Cpf>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validCpf));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code CPF-004', () {
      final result = Cpf.create(invalidCpf);
      expect(result, isA<Failure<Cpf>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('CPF-004'));
      }
    });

    test('create(null) returns Failure', () {
      expect(Cpf.create(null), isA<Failure<Cpf>>());
    });

    test('create(empty) returns Failure', () {
      expect(Cpf.create(''), isA<Failure<Cpf>>());
    });

    test('two Cpf from same string are equal (value semantics)', () {
      final a = Cpf.trusted(validCpf);
      final b = Cpf.trusted(validCpf);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final cpf = Cpf.trusted(validCpf);
      expect(cpf.toString(), equals(validCpf));
    });
  });
}

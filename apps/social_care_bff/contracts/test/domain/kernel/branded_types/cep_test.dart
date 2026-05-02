import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `Cep` as an `extension type`:
///   - `Cep.create(String?)` → `Result<Cep>`
///   - `Cep.trusted(String)` zero-cost constructor for trusted origins
///   - `toString()` returning the raw value
///   - native value equality via the wrapped String
///
/// Current state (A06c): `Cep` is a `final class with Equatable`.
/// The `.trusted` named constructor does NOT exist yet — compile RED expected.
void main() {
  group('Cep (extension type)', () {
    const validCepFormatted = '01310-100';
    const validCepDigits = '01310100';
    const invalidCepChars = 'abc';

    test('create(valid) returns Success', () {
      final result = Cep.create(validCepFormatted);
      expect(result, isA<Success<Cep>>());
      switch (result) {
        case Success(:final value):
          // Canonical storage is digits-only (8 chars).
          expect(value.value, equals(validCepDigits));
        case Failure():
          fail('Expected Success');
      }
    });

    test(
      'create(invalid characters) returns Failure with AppError code CEP-002',
      () {
        final result = Cep.create(invalidCepChars);
        expect(result, isA<Failure<Cep>>());
        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error):
            expect(error, isA<AppError>());
            expect((error as AppError).code, equals('CEP-002'));
        }
      },
    );

    test('create(null) returns Failure', () {
      expect(Cep.create(null), isA<Failure<Cep>>());
    });

    test('create(empty) returns Failure', () {
      expect(Cep.create(''), isA<Failure<Cep>>());
    });

    test('two Cep from same string are equal (value semantics)', () {
      final a = Cep.trusted(validCepDigits);
      final b = Cep.trusted(validCepDigits);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final cep = Cep.trusted(validCepDigits);
      expect(cep.toString(), equals(validCepDigits));
    });
  });
}

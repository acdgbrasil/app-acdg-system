import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `Nis` as an `extension type`:
///   - `Nis.create(String?)` → `Result<Nis>`
///   - `Nis.trusted(String)` zero-cost constructor for trusted origins
///   - `toString()` returning the raw value
///   - native value equality via the wrapped String
///
/// Current state (A06c): `Nis` is a `final class with Equatable`.
/// The `.trusted` named constructor does NOT exist yet — compile RED expected.
void main() {
  group('Nis (extension type)', () {
    // Valid NIS (mod11 verifier checks out — see existing nis_test.dart).
    const validNis = '12066020585';
    // Same digits, last one flipped — breaks mod11.
    const invalidNis = '12066020586';

    test('create(valid) returns Success', () {
      final result = Nis.create(validNis);
      expect(result, isA<Success<Nis>>());
      switch (result) {
        case Success(:final value):
          expect(value.value, equals(validNis));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code NIS-002', () {
      final result = Nis.create(invalidNis);
      expect(result, isA<Failure<Nis>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('NIS-002'));
      }
    });

    test('create(null) returns Failure', () {
      expect(Nis.create(null), isA<Failure<Nis>>());
    });

    test('create(empty) returns Failure', () {
      expect(Nis.create(''), isA<Failure<Nis>>());
    });

    test('two Nis from same string are equal (value semantics)', () {
      final a = Nis.trusted(validNis);
      final b = Nis.trusted(validNis);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final nis = Nis.trusted(validNis);
      expect(nis.toString(), equals(validNis));
    });
  });
}

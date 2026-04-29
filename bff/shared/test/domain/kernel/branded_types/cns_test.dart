import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

/// Wave 0 TDD — shape of `Cns` as an `extension type`:
///   - `Cns.create({required String? number, Cpf? cpf, String? qrCode})`
///     → `Result<Cns>`
///   - `Cns.trusted(String)` zero-cost constructor for trusted origins
///   - `toString()` returning the raw CNS number value
///   - native value equality via the wrapped String
///
/// Current state (A06c): `Cns` is a `final class with Equatable` holding
/// `{ number, cpf, qrCode }`. Wave 1 should collapse it to a pure value
/// wrapping only the 15-digit CNS number (cpf / qrCode live elsewhere).
///
/// The `.trusted` named constructor does NOT exist yet — compile RED expected.
void main() {
  group('Cns (extension type)', () {
    // Valid CNS per SUS algorithm (starts with 7).
    const validCns = '700000000000005';
    // Same digits, last one flipped — breaks DV.
    const invalidCns = '700000000000004';

    test('create(valid) returns Success', () {
      final result = Cns.create(number: validCns);
      expect(result, isA<Success<Cns>>());
      switch (result) {
        case Success(:final value):
          // Wave 1 must expose the raw 15-digit value either as `.value`
          // (extension-type convention) or keep `.number` (legacy). The test
          // asserts the canonical shape `.value` — this is the contract.
          expect(value.toString(), equals(validCns));
        case Failure():
          fail('Expected Success');
      }
    });

    test('create(invalid) returns Failure with AppError code CNS-005', () {
      final result = Cns.create(number: invalidCns);
      expect(result, isA<Failure<Cns>>());
      switch (result) {
        case Success():
          fail('Expected Failure');
        case Failure(:final error):
          expect(error, isA<AppError>());
          expect((error as AppError).code, equals('CNS-005'));
      }
    });

    test('create(null) returns Failure', () {
      expect(Cns.create(number: null), isA<Failure<Cns>>());
    });

    test('create(empty) returns Failure', () {
      expect(Cns.create(number: ''), isA<Failure<Cns>>());
    });

    test('two Cns from same string are equal (value semantics)', () {
      final a = Cns.trusted(validCns);
      final b = Cns.trusted(validCns);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns the raw value', () {
      final cns = Cns.trusted(validCns);
      expect(cns.toString(), equals(validCns));
    });
  });
}

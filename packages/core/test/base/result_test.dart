import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('isSuccess returns true', () {
        const result = Success(42);
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
      });

      test('valueOrNull returns the value', () {
        const result = Success('hello');
        expect(result.valueOrNull, 'hello');
      });

      test('map transforms the value', () {
        const Result<int> result = Success(10);
        final mapped = result.map((v) => v * 2);
        expect(mapped, const Success(20));
      });

      test('flatMap chains results', () {
        const Result<int> result = Success(10);
        final chained = result.flatMap(
          (v) => v > 5 ? Success(v.toString()) : const Failure('too small'),
        );
        expect(chained, const Success('10'));
      });

      test('getOrElse returns the value', () {
        const Result<int> result = Success(42);
        expect(result.getOrElse((_) => 0), 42);
      });

      test('equality works', () {
        expect(const Success(1), const Success(1));
        expect(const Success(1), isNot(const Success(2)));
      });

      test('toString is descriptive', () {
        expect(const Success(42).toString(), 'Success<int>(42)');
      });
    });

    group('Failure', () {
      test('isFailure returns true', () {
        const Result<int> result = Failure('error');
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('valueOrNull returns null', () {
        const Result<int> result = Failure('error');
        expect(result.valueOrNull, isNull);
      });

      test('map propagates the failure', () {
        const Result<int> result = Failure('oops');
        final mapped = result.map((v) => v * 2);
        expect(mapped.isFailure, isTrue);
      });

      test('flatMap propagates the failure', () {
        const Result<int> result = Failure('oops');
        final chained = result.flatMap((v) => Success(v.toString()));
        expect(chained.isFailure, isTrue);
      });

      test('getOrElse returns fallback', () {
        const Result<int> result = Failure('error');
        expect(result.getOrElse((_) => -1), -1);
      });

      test('preserves stackTrace', () {
        final trace = StackTrace.current;
        final result = Failure<int>('err', stackTrace: trace);
        expect(result.stackTrace, trace);
      });

      test('equality works', () {
        expect(const Failure<int>('a'), const Failure<int>('a'));
        expect(const Failure<int>('a'), isNot(const Failure<int>('b')));
      });

      test('toString is descriptive', () {
        expect(const Failure<int>('oops').toString(), 'Failure<int>(oops, null)');
      });
    });

    group('pattern matching', () {
      test('switch expression works', () {
        const Result<int> result = Success(42);
        final message = switch (result) {
          Success(:final value) => 'Got $value',
          Failure(:final error) => 'Error: $error',
        };
        expect(message, 'Got 42');
      });
    });
  });
}

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result2Combinator', () {
    group('combineWith', () {
      test('invokes transform with both values when both are Success', () {
        const Result<int> a = Success(2);
        const Result<int> b = Success(3);

        final result = (a, b).combineWith((x, y) => x + y);

        expect(result, const Success(5));
      });

      test('short-circuits to first Failure preserving stackTrace', () {
        final stack = StackTrace.current;
        final Result<int> a = Failure('first', stackTrace: stack);
        const Result<int> b = Success(3);

        final result = (a, b).combineWith((x, y) => x + y);

        switch (result) {
          case Success():
            fail('Expected Failure when first arg is Failure');
          case Failure(:final error, :final stackTrace):
            expect(error, 'first');
            expect(stackTrace, same(stack));
        }
      });

      test('surfaces second Failure when first is Success', () {
        final stack = StackTrace.current;
        const Result<int> a = Success(2);
        final Result<int> b = Failure('second', stackTrace: stack);

        final result = (a, b).combineWith((x, y) => x + y);

        switch (result) {
          case Success():
            fail('Expected Failure when second arg is Failure');
          case Failure(:final error, :final stackTrace):
            expect(error, 'second');
            expect(stackTrace, same(stack));
        }
      });

      test('discards subsequent failures when first is Failure', () {
        final firstStack = StackTrace.current;
        final secondStack = StackTrace.current;
        final Result<int> a = Failure('first', stackTrace: firstStack);
        final Result<int> b = Failure('second', stackTrace: secondStack);

        final result = (a, b).combineWith((x, y) => x + y);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error, :final stackTrace):
            expect(
              error,
              'first',
              reason: 'first failure must short-circuit',
            );
            expect(stackTrace, same(firstStack));
        }
      });

      test('does NOT invoke transform when any side is Failure', () {
        var invocations = 0;
        const Result<int> a = Success(2);
        const Result<int> b = Failure('boom');

        (a, b).combineWith((x, y) {
          invocations++;
          return x + y;
        });

        expect(invocations, 0);
      });

      test('preserves type parameter inference from transform', () {
        const Result<int> a = Success(2);
        const Result<String> b = Success('x');

        final Result<List<Object>> result =
            (a, b).combineWith((x, y) => <Object>[x, y]);

        expect(result, const Success<List<Object>>([2, 'x']));
      });
    });

    group('flatCombineWith', () {
      test('flattens transform-returned Result on Success path', () {
        const Result<int> a = Success(2);
        const Result<int> b = Success(3);

        final result = (a, b).flatCombineWith<int>(
          (x, y) => x + y > 0 ? Success(x + y) : const Failure('non-positive'),
        );

        expect(result, const Success(5));
      });

      test('propagates Failure from inner transform', () {
        const Result<int> a = Success(2);
        const Result<int> b = Success(3);

        final result = (a, b).flatCombineWith<int>(
          (_, _) => const Failure('inner-rejected'),
        );

        switch (result) {
          case Success():
            fail('Expected inner Failure to propagate');
          case Failure(:final error):
            expect(error, 'inner-rejected');
        }
      });

      test('short-circuits on outer Failure without invoking transform', () {
        var invocations = 0;
        const Result<int> a = Failure('outer');
        const Result<int> b = Success(3);

        (a, b).flatCombineWith<int>((x, y) {
          invocations++;
          return Success(x + y);
        });

        expect(invocations, 0);
      });
    });
  });

  group('Result3Combinator', () {
    group('combineWith', () {
      test('invokes transform with all three values on Success', () {
        const Result<int> a = Success(1);
        const Result<int> b = Success(2);
        const Result<int> c = Success(3);

        final result = (a, b, c).combineWith((x, y, z) => x + y + z);

        expect(result, const Success(6));
      });

      test('short-circuits to first Failure (left to right)', () {
        final stack = StackTrace.current;
        final Result<int> a = Failure('first', stackTrace: stack);
        const Result<int> b = Failure('second');
        const Result<int> c = Failure('third');

        final result = (a, b, c).combineWith((x, y, z) => x + y + z);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error, :final stackTrace):
            expect(error, 'first');
            expect(stackTrace, same(stack));
        }
      });

      test('surfaces middle Failure when first is Success', () {
        final stack = StackTrace.current;
        const Result<int> a = Success(1);
        final Result<int> b = Failure('middle', stackTrace: stack);
        const Result<int> c = Success(3);

        final result = (a, b, c).combineWith((x, y, z) => x + y + z);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error, :final stackTrace):
            expect(error, 'middle');
            expect(stackTrace, same(stack));
        }
      });

      test('surfaces third Failure when first two are Success', () {
        final stack = StackTrace.current;
        const Result<int> a = Success(1);
        const Result<int> b = Success(2);
        final Result<int> c = Failure('third', stackTrace: stack);

        final result = (a, b, c).combineWith((x, y, z) => x + y + z);

        switch (result) {
          case Success():
            fail('Expected Failure');
          case Failure(:final error, :final stackTrace):
            expect(error, 'third');
            expect(stackTrace, same(stack));
        }
      });

      test('does NOT invoke transform when any side is Failure', () {
        var invocations = 0;
        const Result<int> a = Success(1);
        const Result<int> b = Success(2);
        const Result<int> c = Failure('boom');

        (a, b, c).combineWith((x, y, z) {
          invocations++;
          return x + y + z;
        });

        expect(invocations, 0);
      });
    });

    group('flatCombineWith', () {
      test('flattens transform-returned Result on Success path', () {
        const Result<int> a = Success(1);
        const Result<int> b = Success(2);
        const Result<int> c = Success(3);

        final result = (a, b, c).flatCombineWith<int>(
          (x, y, z) => Success(x + y + z),
        );

        expect(result, const Success(6));
      });

      test('propagates inner Failure', () {
        const Result<int> a = Success(1);
        const Result<int> b = Success(2);
        const Result<int> c = Success(3);

        final result = (a, b, c).flatCombineWith<int>(
          (_, _, _) => const Failure('inner'),
        );

        switch (result) {
          case Success():
            fail('Expected inner Failure');
          case Failure(:final error):
            expect(error, 'inner');
        }
      });
    });
  });
}

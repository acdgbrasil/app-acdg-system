/// W0.5 RED — `JsonFormatter` behaviour.
///
/// W1 must create `apps/cli/lib/src/formatters/json_formatter.dart` with:
///
/// ```dart
/// final class JsonFormatter implements OutputFormatter {
///   const JsonFormatter();
///   @override
///   String format(Object? data) => '${jsonEncode(data)}\n';
/// }
/// ```
///
/// Trailing newline is mandatory — pipe-friendly output (POSIX line orientation).
library;

import 'package:test/test.dart';

import 'package:cli/src/formatters/json_formatter.dart';

void main() {
  group('JsonFormatter', () {
    test('formats Map → compact JSON ending in newline', () {
      const f = JsonFormatter();
      expect(f.format({'key': 'value'}), equals('{"key":"value"}\n'));
    });

    test('formats List → compact JSON array ending in newline', () {
      const f = JsonFormatter();
      expect(f.format([1, 2, 3]), equals('[1,2,3]\n'));
    });

    test('formats null → "null" + newline', () {
      const f = JsonFormatter();
      expect(f.format(null), equals('null\n'));
    });

    test('formats nested structures', () {
      const f = JsonFormatter();
      final out = f.format({
        'patient': {'id': 'abc', 'age': 7},
      });
      expect(out, equals('{"patient":{"id":"abc","age":7}}\n'));
    });
  });
}

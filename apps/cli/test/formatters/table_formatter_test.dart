/// W0.5 RED — `TableFormatter` behaviour.
///
/// W1 must create `apps/cli/lib/src/formatters/table_formatter.dart` with an
/// ASCII table renderer for `Map`, `List<Map>`, and an empty-list sentinel.
/// The exact column-width algorithm is W1's call — these tests pin only the
/// observable contract:
///
/// * Single Map → 2-column table (KEY / VALUE) listing each entry.
/// * `List<Map<String, dynamic>>` → header row of shared keys + body rows.
/// * Empty list → `"(no results)"` (or equivalent sentinel — assert exact text).
library;

import 'package:test/test.dart';

import 'package:cli/src/formatters/table_formatter.dart';

void main() {
  group('TableFormatter', () {
    test('formats single Map as 2-column key/value table', () {
      const f = TableFormatter();
      final out = f.format({'id': 'abc', 'name': 'Maria'});

      // Both keys and values must appear in the rendered output.
      expect(out, contains('id'));
      expect(out, contains('abc'));
      expect(out, contains('name'));
      expect(out, contains('Maria'));
    });

    test('formats List<Map> with shared header row', () {
      const f = TableFormatter();
      final out = f.format([
        {'id': 'a', 'name': 'Alice'},
        {'id': 'b', 'name': 'Bob'},
      ]);

      // Header keys present once each (case-sensitive).
      expect(out, contains('id'));
      expect(out, contains('name'));
      // All four values rendered.
      expect(out, contains('Alice'));
      expect(out, contains('Bob'));
      expect(out, contains('a'));
      expect(out, contains('b'));
    });

    test('empty List → "(no results)" sentinel', () {
      const f = TableFormatter();
      expect(f.format(<Map<String, dynamic>>[]), contains('(no results)'));
    });
  });
}

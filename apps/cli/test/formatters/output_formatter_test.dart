/// W0.5 RED — `OutputFormatter` abstract interface contract (ENCAPSULATION_POLICY H5).
///
/// W1 must declare in `apps/cli/lib/src/formatters/output_formatter.dart`:
///
/// ```dart
/// abstract interface class OutputFormatter {
///   const OutputFormatter();
///   String format(Object? data);
/// }
/// ```
///
/// Three impls (`JsonFormatter`, `TableFormatter`, `YamlFormatter`) `implements
/// OutputFormatter`. This test asserts the contract is implementable from
/// outside the library (H5 — `abstract interface class`, no implementation
/// inheritance).
library;

import 'package:test/test.dart';

import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/formatters/table_formatter.dart';
import 'package:cli/src/formatters/yaml_formatter.dart';

void main() {
  group('OutputFormatter (abstract interface — H5)', () {
    test('every concrete formatter implements OutputFormatter', () {
      expect(const JsonFormatter(), isA<OutputFormatter>());
      expect(const TableFormatter(), isA<OutputFormatter>());
      expect(const YamlFormatter(), isA<OutputFormatter>());
    });

    test(
      'OutputFormatter is implementable from foreign code (H5 contract)',
      () {
        // If `OutputFormatter` is not `abstract interface class`, this line
        // either won't compile (abstract class with hidden state) or will
        // accept inheritance (`extends` — wrong shape per H5).
        const OutputFormatter f = _ExternalFakeFormatter();
        expect(f.format('anything'), equals('fake'));
      },
    );
  });
}

/// Lives outside `package:cli/...` to prove the interface is implementable
/// across library boundaries (H5 — sub-contracts must be `implements`-able by
/// any package, including this test file).
class _ExternalFakeFormatter implements OutputFormatter {
  const _ExternalFakeFormatter();

  @override
  String format(Object? data) => 'fake';
}

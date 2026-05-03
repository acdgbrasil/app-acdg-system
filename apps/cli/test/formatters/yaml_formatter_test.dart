/// W0.5 RED — `YamlFormatter` behaviour.
///
/// W1 must create `apps/cli/lib/src/formatters/yaml_formatter.dart`. The
/// `package:yaml` dep doesn't ship a *writer*; W1 either pulls `yaml_writer`
/// or writes a minimal emitter — the test only asserts the observable shape.
library;

import 'package:test/test.dart';

import 'package:cli/src/formatters/yaml_formatter.dart';

void main() {
  group('YamlFormatter', () {
    test('formats Map → YAML mapping with key:value lines', () {
      const f = YamlFormatter();
      final out = f.format({'id': 'abc', 'name': 'Maria'});

      // Canonical YAML mapping uses `key: value` lines.
      expect(out, contains('id:'));
      expect(out, contains('abc'));
      expect(out, contains('name:'));
      expect(out, contains('Maria'));
    });

    test('formats List → YAML sequence (`-` items)', () {
      const f = YamlFormatter();
      final out = f.format(['a', 'b', 'c']);

      // YAML sequence dash markers — at least one per item.
      expect(out, contains('- a'));
      expect(out, contains('- b'));
      expect(out, contains('- c'));
    });
  });
}

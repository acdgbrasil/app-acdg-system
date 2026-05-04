/// W0.5 RED — `resolveFormatter` auto-detect logic (D4).
///
/// W1 must create `apps/cli/lib/src/formatters/auto_formatter.dart` with a
/// top-level function:
///
/// ```dart
/// OutputFormatter resolveFormatter({
///   String? explicitFormat,
///   required bool isTerminal,
/// });
/// ```
///
/// * The ticket spec hints at `IOSink stdout` — but `IOSink` does NOT expose
///   `hasTerminal` (only `Stdout` does). W1 must abstract the terminal probe
///   to a primitive (`bool isTerminal`) so this test can drive auto-detect
///   without smuggling `dart:io` `Stdout` into the unit suite.
/// * Auto-detect (no `explicitFormat`) per `gh CLI`: tty → table, pipe → json.
/// * Invalid `explicitFormat` (e.g. `'xml'`) MUST throw `CliError.invalidArg`
///   (a sealed-class variant — see errors/cli_error.dart).
library;

import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';
import 'package:cli/src/formatters/auto_formatter.dart';
import 'package:cli/src/formatters/json_formatter.dart';
import 'package:cli/src/formatters/output_formatter.dart';
import 'package:cli/src/formatters/table_formatter.dart';
import 'package:cli/src/formatters/yaml_formatter.dart';

void main() {
  group('resolveFormatter — explicit override', () {
    test('"json" returns JsonFormatter', () {
      final f = resolveFormatter(explicitFormat: 'json', isTerminal: true);
      expect(f, isA<JsonFormatter>());
    });

    test('"table" returns TableFormatter', () {
      final f = resolveFormatter(explicitFormat: 'table', isTerminal: false);
      expect(f, isA<TableFormatter>());
    });

    test('"yaml" returns YamlFormatter', () {
      final f = resolveFormatter(explicitFormat: 'yaml', isTerminal: true);
      expect(f, isA<YamlFormatter>());
    });

    test('invalid format ("xml") throws CliError', () {
      expect(
        () => resolveFormatter(explicitFormat: 'xml', isTerminal: true),
        throwsA(isA<CliError>()),
      );
    });
  });

  group('resolveFormatter — auto-detect (D4 — gh CLI parity)', () {
    test('no explicit + isTerminal=true → TableFormatter', () {
      final f = resolveFormatter(isTerminal: true);
      expect(f, isA<TableFormatter>());
    });

    test('no explicit + isTerminal=false (pipe) → JsonFormatter', () {
      final f = resolveFormatter(isTerminal: false);
      expect(f, isA<JsonFormatter>());
    });

    test('return type is OutputFormatter — no caller leaks concrete branch', () {
      // OutputFormatter (abstract interface — H5) must be the public return type
      // so callers don't pattern-match on concrete formatters.
      final OutputFormatter f = resolveFormatter(isTerminal: false);
      expect(f, isNotNull);
    });
  });
}

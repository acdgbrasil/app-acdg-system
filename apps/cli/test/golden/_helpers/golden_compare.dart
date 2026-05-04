/// W0 RED — golden comparison helper.
///
/// Compares captured CLI output against a `.golden` file under
/// `test/golden/<verb>/...`. Supports two modes:
///
///   * **Compare** (default): if the golden file exists, `expect`s the
///     captured text to match its content byte-for-byte. If missing, the
///     test fails with a clear message pointing at the path.
///
///   * **Update** (env `UPDATE_GOLDENS=1`): writes the captured text to the
///     golden path and passes. Used by the maintainer to refresh goldens
///     after intentional changes.
///
/// Why an env var instead of a CLI flag: `dart test` swallows positional
/// args after the file pattern, so a flag would force callers to use the
/// `--define` syntax that varies per IDE. `UPDATE_GOLDENS=1` is the
/// universal escape hatch.
///
/// Goldens are stored verbatim — including trailing newline. Tests compare
/// the FULL captured stdout (and optionally stderr) so newline policy is
/// part of the contract.
library;

import 'dart:io';

import 'package:test/test.dart';

/// Root of the golden tree (relative to package).
const String goldenRoot = 'test/golden';

/// True when the suite is running in "update goldens" mode.
bool get isUpdatingGoldens => Platform.environment['UPDATE_GOLDENS'] == '1';

/// Compares [actual] with the file at `test/golden/[relativePath]`.
///
/// In update mode, writes [actual] to disk and returns. In compare mode,
/// fails the test if the file is missing or the content differs.
///
/// The [reason] is forwarded to the underlying `expect` so a failing
/// golden surfaces a useful breadcrumb (e.g. `'patient list table'`).
void expectGolden(String actual, String relativePath, {String? reason}) {
  final file = File('$goldenRoot/$relativePath');
  if (isUpdatingGoldens) {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(actual);
    return;
  }
  if (!file.existsSync()) {
    fail(
      'Golden file missing: $goldenRoot/$relativePath\n'
      'Run with UPDATE_GOLDENS=1 to create it, or check the test path.',
    );
  }
  final expected = file.readAsStringSync();
  expect(
    actual,
    equals(expected),
    reason:
        reason ??
        'golden mismatch at $goldenRoot/$relativePath '
            '(run UPDATE_GOLDENS=1 to refresh if intentional)',
  );
}

/// JSON output formatter — pipe-friendly default for non-tty stdout.
library;

import 'dart:convert';

import 'output_formatter.dart';

/// Compact JSON encoder + trailing newline (POSIX line orientation).
///
/// Trailing `\n` lets downstream tools (`jq`, `grep`, shell `read`) treat
/// each invocation's output as a single record without special-casing EOF.
final class JsonFormatter implements OutputFormatter {
  const JsonFormatter();

  @override
  String format(Object? data) => '${jsonEncode(data)}\n';
}

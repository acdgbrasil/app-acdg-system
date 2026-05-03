/// Auto-detect output formatter — D4 (gh-CLI parity).
///
/// `--output=auto` (or unset) inspects whether stdout is attached to a
/// terminal: tty → table (human reader), pipe/redirect → json (machine
/// reader). Explicit `json|table|yaml` always wins; anything else throws
/// [InvalidArgError].
library;

import '../errors/cli_error.dart';
import 'json_formatter.dart';
import 'output_formatter.dart';
import 'table_formatter.dart';
import 'yaml_formatter.dart';

/// Picks the right [OutputFormatter] based on user choice + tty state.
///
/// * [explicitFormat] — value of `--output=<x>`. `null` or `'auto'` triggers
///   auto-detection.
/// * [isTerminal] — caller's `stdout.hasTerminal` (or test fake). Kept as a
///   primitive so unit tests don't need to construct a real `Stdout`.
///
/// Throws [InvalidArgError] (a [CliError] variant) when [explicitFormat]
/// is none of `json|table|yaml|auto`.
OutputFormatter resolveFormatter({
  String? explicitFormat,
  required bool isTerminal,
}) {
  final format = explicitFormat ?? 'auto';
  return switch (format) {
    'json' => const JsonFormatter(),
    'table' => const TableFormatter(),
    'yaml' => const YamlFormatter(),
    'auto' => isTerminal ? const TableFormatter() : const JsonFormatter(),
    _ => throw InvalidArgError('--output=$format'),
  };
}

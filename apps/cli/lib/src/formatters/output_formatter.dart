/// Output formatter contract — sub-contract per ENCAPSULATION_POLICY H5.
///
/// `abstract interface class` so foreign packages (and the CLI test suite)
/// can `implements OutputFormatter` without inheriting any implementation
/// state. There is exactly one method — `format` — keeping the surface
/// minimal and trivially mockable.
library;

/// Formats arbitrary CLI payloads (Map/List/scalar) as a printable string.
///
/// Implementations are pure (no I/O, no global state). The CLI runner picks
/// an implementation per request via [resolveFormatter].
abstract interface class OutputFormatter {
  /// Allows `const` implementations (`const JsonFormatter()`).
  const OutputFormatter();

  /// Returns the formatted representation of [data].
  ///
  /// Implementations decide the trailing-newline policy. Pipe-friendly
  /// formatters (json) end with `\n` so `acdg ... | jq` works.
  String format(Object? data);
}

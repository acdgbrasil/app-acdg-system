/// Presentation port — commands emit through this, not directly to stdout.
///
/// Decouples commands from terminal infrastructure so the same command
/// logic can run in test (with a capturing sink), in JSON-only mode, or
/// as a library without a terminal.
library;

/// Abstraction over stdout/stderr for all CLI commands.
abstract interface class CliOutput {
  /// Write [text] to standard output without a trailing newline.
  void write(String text);

  /// Write [text] to standard output with a trailing newline.
  void writeln(String text);

  /// Write [text] to standard error without a trailing newline.
  void writeErr(String text);

  /// Write [text] to standard error with a trailing newline.
  void writeErrLn(String text);
}

/// Terminal adapter — writes to injected [StringSink]s.
///
/// This is the production implementation used by `bin/acdg.dart`.
final class TerminalCliOutput implements CliOutput {
  /// Creates a terminal output adapter.
  const TerminalCliOutput(this._stdout, this._stderr);

  final StringSink? _stdout;
  final StringSink? _stderr;

  @override
  void write(String text) => _stdout?.write(text);

  @override
  void writeln(String text) => _stdout?.writeln(text);

  @override
  void writeErr(String text) => _stderr?.write(text);

  @override
  void writeErrLn(String text) => _stderr?.writeln(text);
}

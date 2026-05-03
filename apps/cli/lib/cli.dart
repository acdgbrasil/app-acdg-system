/// ACDG CLI public API — exported by the `cli` package.
///
/// The barrel re-exports the surface that external callers (including the
/// `bin/acdg.dart` entrypoint and any future embedding) need:
///   * [CliRunner] — top-level wiring of CommandRunner + global flags.
///   * [CliError] family — sealed error hierarchy used across the CLI.
///   * Formatters — interface + concrete impls + the auto-detect resolver.
///   * Session — credential persistence + BFF HTTP client scaffold.
library;

export 'src/cli_runner.dart';
export 'src/errors/cli_error.dart';
export 'src/formatters/auto_formatter.dart';
export 'src/formatters/json_formatter.dart';
export 'src/formatters/output_formatter.dart';
export 'src/formatters/table_formatter.dart';
export 'src/formatters/yaml_formatter.dart';
export 'src/session/bff_client.dart';
export 'src/session/credential_store.dart';

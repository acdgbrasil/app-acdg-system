/// ACDG CLI public API — exported by the `cli` package.
///
/// Intentionally minimal surface for external callers:
///   * [CliRunner] — top-level wiring of CommandRunner + global flags.
///   * [CliError] family — sealed error hierarchy used across the CLI.
///   * Formatters — interface + auto-detect resolver.
///   * Session — credential persistence scaffold.
library;

export 'src/cli_runner.dart' show CliRunner;
export 'src/commands/mcp_command.dart' show McpCommand;
export 'src/errors/cli_error.dart';
export 'src/errors/exit_code.dart';
export 'src/formatters/output_formatter.dart';
export 'src/formatters/auto_formatter.dart' show resolveFormatter;
export 'src/session/credential_store.dart' show CredentialStore;
export 'src/session/oidc_session.dart' show OidcSession;

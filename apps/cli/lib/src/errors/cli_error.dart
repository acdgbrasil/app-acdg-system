/// Sealed [CliError] family — every CLI failure lives in this hierarchy.
///
/// Per [PATTERN_MATCHING_POLICY P5], call-sites must use exhaustive `switch`
/// (or the [Result.map]/[Result.flatMap] combinators) — never downcast with
/// `as`. The `acdg_lints/no_sealed_class_downcast` rule enforces this.
///
/// Each variant carries its own [exitCode] and [stderrMessage] so there is
/// no external helper to update when a new variant is added.
library;

/// Root of the sealed CLI error family.
///
/// `implements Exception` so `throw CliError.invalidArg(...)` from
/// `resolveFormatter` flows through the existing exception machinery (without
/// crossing into `Error` territory, which is reserved for programmer faults).
sealed class CliError implements Exception {
  const CliError(this.message);

  /// Human-readable message — safe to surface on stderr / `--help`.
  final String message;

  /// Exit code for this error category.
  int get exitCode;

  /// Human-readable message intended for stderr.
  String get stderrMessage;

  /// Convenience builder — `--output=xml` → [InvalidArgError].
  const factory CliError.invalidArg(String message) = InvalidArgError;

  /// Convenience builder — caller hit a 401 / no credentials yet.
  const factory CliError.authRequired() = AuthRequiredError;

  /// Convenience builder — connection refused / DNS / TLS handshake failure.
  const factory CliError.network(String message) = NetworkError;

  /// Convenience builder — BFF responded with a 5xx / unexpected status.
  const factory CliError.server(int statusCode, String message) = ServerError;

  @override
  String toString() => '$runtimeType: $message';
}

/// User passed an argument the CLI rejects (e.g. `--output=xml`).
final class InvalidArgError extends CliError {
  const InvalidArgError(super.message);

  @override
  int get exitCode => 64;

  @override
  String get stderrMessage => 'Invalid argument: $message';
}

/// Credentials missing or expired — caller must `acdg auth login` first.
final class AuthRequiredError extends CliError {
  const AuthRequiredError()
    : super('Authentication required. Run: acdg auth login');

  @override
  int get exitCode => 2;

  @override
  String get stderrMessage => 'Authentication required. Run: acdg auth login';
}

/// Transport-level failure (connection, DNS, TLS, timeout).
final class NetworkError extends CliError {
  const NetworkError(super.message);

  @override
  int get exitCode => 3;

  @override
  String get stderrMessage => 'Network error: $message';
}

/// BFF returned a non-success status the CLI cannot handle locally.
final class ServerError extends CliError {
  const ServerError(this.statusCode, super.message);

  /// HTTP status code returned by the BFF.
  final int statusCode;

  @override
  int get exitCode => 1;

  @override
  String get stderrMessage => 'Server error ($statusCode): $message';
}

/// Refresh token rotated or revoked at the IdP — the local session is
/// dead and the user MUST run `acdg auth login` again.
///
/// Distinct from [AuthRequiredError] so commands can tell apart "no
/// session yet" (run login) from "session was invalidated" (run login
/// again — the previous one is stale on the IdP).
final class RefreshTokenInvalidError extends CliError {
  const RefreshTokenInvalidError([String? detail])
    : super(detail ?? 'Refresh token rotated or revoked. Run: acdg auth login');

  @override
  int get exitCode => 2;

  @override
  String get stderrMessage =>
      'Authentication required (refresh token rotated). '
      'Run: acdg auth login';
}

// ---------------------------------------------------------------------------
// B4 — Keychain adapter errors
// ---------------------------------------------------------------------------

/// The platform's keychain backend is not available (binary missing,
/// `LOCALAPPDATA` unset, unsupported OS).
///
/// Surfaced fail-loud — the CLI never falls back to plaintext on missing
/// backend. Operator gets [installHint] in the error message.
final class KeychainUnavailable extends CliError {
  const KeychainUnavailable(this.binary, this.installHint)
    : super('Keychain unavailable.');

  /// Name of the missing executable / capability (e.g. `secret-tool`,
  /// `powershell.exe`, `none`).
  final String binary;

  /// Human-readable remediation copy — install instructions or env-var
  /// hint surfaced in `toString()` so the operator sees actionable copy.
  final String installHint;

  @override
  int get exitCode => 5;

  @override
  String get stderrMessage =>
      'Keychain unavailable: $binary not found. $installHint';
}

/// The keychain backend was reachable but the operation failed (non-zero
/// exit code, denied, dbus error, etc.).
///
/// [stderrSummary] is sanitized + truncated to a fixed length so a runaway
/// stderr cannot dominate the user's terminal. The secret content NEVER
/// flows into [stderrSummary] in either success or failure paths — the
/// keychain binary either never read the secret (write-time failure) or
/// never echoes it back (read-time stderr is metadata only).
final class KeychainOperationFailed extends CliError {
  const KeychainOperationFailed(this.keychainExitCode, this.stderrSummary)
    : super('Keychain operation failed.');

  /// Exit code returned by the keychain binary.
  final int keychainExitCode;

  /// Sanitized stderr from the binary. Never contains the secret blob.
  final String stderrSummary;

  @override
  int get exitCode => 5;

  @override
  String get stderrMessage =>
      'Keychain operation failed (exit $keychainExitCode): $stderrSummary';
}

/// The keychain entry exists but does not parse as a valid `OidcSession`
/// JSON blob. The user must `acdg auth login` again to recover.
final class KeychainCorruptEntry extends CliError {
  const KeychainCorruptEntry()
    : super(
        'Keychain entry exists but is unreadable. '
        'Run "acdg auth login" to recover.',
      );

  @override
  int get exitCode => 5;

  @override
  String get stderrMessage => message;
}

// ---------------------------------------------------------------------------
// CLI-MCP-INTEGRATION (W3) — `McpAdapterError` sealed sub-family
// ---------------------------------------------------------------------------
//
// DESIGN §2.8 — `acdg mcp serve` boundary failures live in their own sealed
// sub-tree of [CliError]. Each variant carries a BSD `sysexits.h` exit code
// so the binary returns a meaningful `$?` when the MCP server crashes.
//
// Variants (4):
//   * McpProtocolError  → 70 (EX_SOFTWARE) — JSON-RPC malformed / unexpected.
//   * McpTransportError → 74 (EX_IOERR)    — stdio peer closed, transport.
//   * McpToolError      → 1                — handler could not produce a result.
//   * McpAuthError      → 2                — RBAC denial / no session.
//
// Adding a fifth variant trips the exhaustive switch in
// `test/errors/cli_error_test.dart::_tagOf` (compile-time guard).

/// Root for `acdg mcp serve` boundary failures.
///
/// Sealed so every place handling MCP errors must enumerate every variant
/// (`McpErrorMapper`, the `_tagOf` switch in the cli_error tests).
sealed class McpAdapterError extends CliError {
  const McpAdapterError(super.message);
}

/// JSON-RPC framing or schema error.
///
/// Surfaces when a frame fails to parse, when a request lacks required
/// fields, or when the mapper falls back for an unrecognised exception
/// type (DESIGN §2.7 — last switch arm).
final class McpProtocolError extends McpAdapterError {
  const McpProtocolError(super.message);

  @override
  int get exitCode => 70; // EX_SOFTWARE

  @override
  String get stderrMessage => 'MCP protocol error: $message';
}

/// Stdio peer closed unexpectedly or the transport layer reported a
/// connection-level failure.
final class McpTransportError extends McpAdapterError {
  const McpTransportError(super.message);

  @override
  int get exitCode => 74; // EX_IOERR

  @override
  String get stderrMessage => 'MCP transport error: $message';
}

/// A registered tool handler could not produce a valid result. The registry
/// catches handler exceptions and wraps them as `CallToolResult(isError: true)`,
/// so this variant is rare; it surfaces only when the boundary itself is
/// the source of the failure.
final class McpToolError extends McpAdapterError {
  const McpToolError(super.message);

  @override
  int get exitCode => 1;

  @override
  String get stderrMessage => 'MCP tool error: $message';
}

/// The caller has no active session OR the session lacks every required
/// role for the tool being invoked. `McpToolRegistry.dispatch` returns this
/// as a `CallToolResult(isError: true)` — this typed variant exists so the
/// adapter / process surface can also report the same condition.
final class McpAuthError extends McpAdapterError {
  const McpAuthError(super.message);

  @override
  int get exitCode => 2;

  @override
  String get stderrMessage => 'MCP auth error: $message';
}

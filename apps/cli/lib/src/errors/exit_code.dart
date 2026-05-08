/// Semantic exit codes for the ACDG CLI.
///
/// Aligned with [CliError.exitCode] polymorphic property.
library;

/// Exit-code constants used by tests and the orchestrator.
abstract final class ExitCode {
  ExitCode._();

  /// Success — command completed without error.
  static const int success = 0;

  /// Server or unexpected error.
  static const int serverError = 1;

  /// Authentication required (no session or session expired).
  static const int authRequired = 2;

  /// Network-level failure (DNS, TLS, connection refused, timeout).
  static const int networkError = 3;

  /// Keychain or credential-store failure.
  static const int keychainError = 5;

  /// Invalid arguments or usage error (aligned with EX_USAGE = 64).
  static const int invalidUsage = 64;
}

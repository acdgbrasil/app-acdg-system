/// Sealed [CliError] family — every CLI failure lives in this hierarchy.
///
/// Per [PATTERN_MATCHING_POLICY P5], call-sites must use exhaustive `switch`
/// (or the [Result.map]/[Result.flatMap] combinators) — never downcast with
/// `as`. The `acdg_lints/no_sealed_class_downcast` rule enforces this.
///
/// C01 ships with four variants. C02+ may extend the family; every new
/// variant must surface in every existing exhaustive switch (compiler-enforced).
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

  /// Convenience builder — `--output=xml` → [InvalidArgError].
  const factory CliError.invalidArg(String message) = InvalidArgError;

  /// Convenience builder — caller hit a 401 / no credentials yet.
  const factory CliError.authRequired() = AuthRequiredError;

  /// Convenience builder — connection refused / DNS / TLS handshake failure.
  const factory CliError.network(String message) = NetworkError;

  /// Convenience builder — BFF responded with a 5xx / unexpected status.
  const factory CliError.server(int statusCode, String message) = ServerError;

  @override
  String toString() => message;
}

/// User passed an argument the CLI rejects (e.g. `--output=xml`).
final class InvalidArgError extends CliError {
  const InvalidArgError(super.message);
}

/// Credentials missing or expired — caller must `acdg auth login` first.
final class AuthRequiredError extends CliError {
  const AuthRequiredError()
    : super('Authentication required. Run: acdg auth login');
}

/// Transport-level failure (connection, DNS, TLS, timeout).
final class NetworkError extends CliError {
  const NetworkError(super.message);
}

/// BFF returned a non-success status the CLI cannot handle locally.
final class ServerError extends CliError {
  const ServerError(this.statusCode, super.message);

  /// HTTP status code returned by the BFF.
  final int statusCode;
}

/// Refresh token rotated or revoked at the IdP — the local session is
/// dead and the user MUST run `acdg auth login` again.
///
/// Distinct from [AuthRequiredError] so commands can tell apart "no
/// session yet" (run login) from "session was invalidated" (run login
/// again — the previous one is stale on the IdP). The CLI maps this
/// to exit code 7 in `acdg auth refresh`.
final class RefreshTokenInvalidError extends CliError {
  const RefreshTokenInvalidError([String? detail])
    : super(detail ?? 'Refresh token rotated or revoked. Run: acdg auth login');
}

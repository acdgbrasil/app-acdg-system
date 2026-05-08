/// W0.5 RED — `CliError` sealed class contract.
///
/// W1 must create `apps/cli/lib/src/errors/cli_error.dart` with:
///
/// ```dart
/// sealed class CliError implements Exception {
///   const CliError(this.message);
///   final String message;
///
///   /// Convenience builders. W1 may either keep these factories on the
///   /// parent OR drop them in favour of direct `InvalidArgError(...)`
///   /// constructors. The tests below assert the *types* exist; if W1
///   /// chooses different names/granularity, this suite fails and W1
///   /// must justify in the GREEN handoff.
///   const factory CliError.invalidArg(String message) = InvalidArgError;
///   const factory CliError.authRequired() = AuthRequiredError;
///   const factory CliError.network(String message) = NetworkError;
///   const factory CliError.server(int statusCode, String message) = ServerError;
/// }
///
/// final class InvalidArgError extends CliError { ... }
/// final class AuthRequiredError extends CliError { ... }
/// final class NetworkError extends CliError { ... }
/// final class ServerError extends CliError { ... }
/// ```
///
/// **Open question for W1:** the 4 variants above are the test-writer's
/// proposal. If the C03+ implementation needs more (e.g. `RateLimitError`,
/// `TimeoutError`), W1 may extend the sealed family — but every variant
/// MUST appear in an exhaustive `switch`. The lint
/// `acdg_lints/no_sealed_class_downcast` (P5) prevents `as InvalidArgError`
/// shortcuts from creeping in.
library;

import 'package:test/test.dart';

import 'package:cli/src/errors/cli_error.dart';

void main() {
  group('CliError variants', () {
    test('InvalidArgError carries the offending arg in its message', () {
      const err = InvalidArgError('--output=xml');
      expect(err.message, contains('xml'));
      expect(err, isA<CliError>());
      expect(err, isA<Exception>());
    });

    test('AuthRequiredError exists as a singleton-friendly variant', () {
      const err = AuthRequiredError();
      expect(err, isA<CliError>());
      expect(err, isA<Exception>());
    });

    test('NetworkError carries a message', () {
      const err = NetworkError('connection refused');
      expect(err.message, contains('connection refused'));
      expect(err, isA<CliError>());
    });

    test('ServerError carries a status code and message', () {
      const err = ServerError(503, 'service unavailable');
      expect(err.statusCode, equals(503));
      expect(err.message, contains('service unavailable'));
      expect(err, isA<CliError>());
    });
  });

  group('CliError exhaustive switch (P5 — sealed)', () {
    test('switch over CliError covers every variant — compiler enforced', () {
      // The compiler will refuse this switch if `CliError` ever loses
      // exhaustiveness or if W1 adds a variant without a case here.
      const CliError invalid = InvalidArgError('bad');
      final tag = _tagOf(invalid);
      expect(tag, equals('invalid'));

      const CliError auth = AuthRequiredError();
      expect(_tagOf(auth), equals('auth'));

      const CliError network = NetworkError('boom');
      expect(_tagOf(network), equals('network'));

      const CliError server = ServerError(500, 'oops');
      expect(_tagOf(server), equals('server'));
    });
  });

  _mcpTests();
}

/// Helper that forces an exhaustive switch — analyzer fails this file if a
/// new variant is added without a matching arm.
///
/// C02 added [RefreshTokenInvalidError] to the sealed family; this switch
/// caught it (compiler-enforced), and the new arm is the W1 migration.
/// B4 added [KeychainUnavailable], [KeychainOperationFailed],
/// [KeychainCorruptEntry] — each gets its own tag here.
/// CLI-MCP-INTEGRATION (W2) adds the sealed `McpAdapterError` family with
/// 4 subtypes — each gets its own tag here so adding a 5th will fail the
/// compiler at this file (intentional).
String _tagOf(CliError error) => switch (error) {
  InvalidArgError() => 'invalid',
  AuthRequiredError() => 'auth',
  NetworkError() => 'network',
  ServerError() => 'server',
  RefreshTokenInvalidError() => 'refresh_invalid',
  KeychainUnavailable() => 'keychain_unavailable',
  KeychainOperationFailed() => 'keychain_op_failed',
  KeychainCorruptEntry() => 'keychain_corrupt',
  McpProtocolError() => 'mcp_protocol',
  McpTransportError() => 'mcp_transport',
  McpToolError() => 'mcp_tool',
  McpAuthError() => 'mcp_auth',
};

// ---------------------------------------------------------------------------
// CLI-MCP-INTEGRATION (W2 RED) — McpAdapterError sealed family.
// ---------------------------------------------------------------------------
//
// DESIGN §2.8 declares 4 variants under a sealed `McpAdapterError extends
// CliError` parent. Each carries its own exitCode following the BSD sysexits
// taxonomy:
//   * McpProtocolError  → 70 (EX_SOFTWARE) — JSON-RPC malformed
//   * McpTransportError → 74 (EX_IOERR)    — stdio peer closed
//   * McpToolError      → 1                — handler could not produce a result
//   * McpAuthError      → 2                — RBAC denial / no session

void _mcpTests() {
  group('McpAdapterError sealed family (W2 RED — DESIGN §2.8)', () {
    test('is exhaustively switchable through CliError root', () {
      const McpAdapterError protocol = McpProtocolError('bad frame');
      const McpAdapterError transport = McpTransportError('peer closed');
      const McpAdapterError tool = McpToolError('handler crashed');
      const McpAdapterError auth = McpAuthError('forbidden');

      // Tagging each variant via the same exhaustive switch as the rest
      // of CliError proves every arm is reachable from the root.
      expect(_tagOf(protocol), equals('mcp_protocol'));
      expect(_tagOf(transport), equals('mcp_transport'));
      expect(_tagOf(tool), equals('mcp_tool'));
      expect(_tagOf(auth), equals('mcp_auth'));
    });

    test(
      'each variant exposes the BSD sysexits exit code from DESIGN §2.8',
      () {
        expect(const McpProtocolError('x').exitCode, equals(70));
        expect(const McpTransportError('x').exitCode, equals(74));
        expect(const McpToolError('x').exitCode, equals(1));
        expect(const McpAuthError('x').exitCode, equals(2));
      },
    );
  });
}

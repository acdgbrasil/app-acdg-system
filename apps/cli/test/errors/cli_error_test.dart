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

}

/// Helper that forces an exhaustive switch — analyzer fails this file if a
/// new variant is added without a matching arm.
///
/// C02 added [RefreshTokenInvalidError] to the sealed family; this switch
/// caught it (compiler-enforced), and the new arm is the W1 migration.
/// B4 added [KeychainUnavailable], [KeychainOperationFailed],
/// [KeychainCorruptEntry] — each gets its own tag here.
String _tagOf(CliError error) => switch (error) {
  InvalidArgError() => 'invalid',
  AuthRequiredError() => 'auth',
  NetworkError() => 'network',
  ServerError() => 'server',
  RefreshTokenInvalidError() => 'refresh_invalid',
  KeychainUnavailable() => 'keychain_unavailable',
  KeychainOperationFailed() => 'keychain_op_failed',
  KeychainCorruptEntry() => 'keychain_corrupt',
};


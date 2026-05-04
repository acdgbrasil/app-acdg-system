/// W0 RED — golden tests for `acdg auth ...` (status, refresh, logout).
///
/// `auth login` is excluded from goldens — it spawns a loopback HTTP server,
/// opens a browser, and waits for OIDC callback. Already covered by
/// integration tests under `test/commands/auth_login_command_test.dart`.
library;

import 'package:test/test.dart';

import '_helpers/golden_compare.dart';
import '_helpers/golden_runner.dart';
import '_helpers/mock_bff_server.dart';

void main() {
  group('acdg auth status', () {
    test('signed in (table) — shows email + roles', () async {
      // No BFF call — `auth status` reads only the local credential store.
      final server = MockBffServer();

      // Frozen clock pinned 24h before the fake's `accessExpiresAt`
      // (`DateTime.utc(2099, 1, 1)`), so the rendered relative time is
      // deterministic — `in 24h0m`. Without this, the relative-time helper
      // drifts every minute the suite runs.
      final result = await runCliForGolden(
        const ['auth', 'status', '--output=table'],
        mockAdapter: server.asAdapter(),
        credentialStore: FakeCredentialStore.signedIn(),
        clock: () =>
            DateTime.utc(2099, 1, 1).subtract(const Duration(hours: 24)),
      );

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'auth/status_signed_in.golden');
    });

    test('signed out — non-zero exit', () async {
      final server = MockBffServer();

      final result = await runCliForGolden(
        const ['auth', 'status', '--output=table'],
        mockAdapter: server.asAdapter(),
        credentialStore: FakeCredentialStore.signedOut(),
      );

      expect(result.exitCode, isNot(equals(0)));
      expectGolden(result.stderr, 'auth/status_signed_out.golden');
    });
  });

  group('acdg auth logout', () {
    test('clears local session', () async {
      final server = MockBffServer();

      final result = await runCliForGolden(
        const ['auth', 'logout', '--output=table'],
        mockAdapter: server.asAdapter(),
        credentialStore: FakeCredentialStore.signedIn(),
      );

      expect(result.exitCode, equals(0));
      expectGolden(result.stdout, 'auth/logout_success.golden');
    });
  });
}

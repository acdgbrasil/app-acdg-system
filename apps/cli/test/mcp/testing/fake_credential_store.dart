/// W2 RED helper — in-memory [CredentialStore] for MCP RBAC tests.
///
/// `CredentialStore` is an `abstract interface class`, so a manual fake
/// `implements CredentialStore` is the canonical Fake pattern (ADR-013 — no
/// magic mocks). `read()` returns whatever was last written or seeded; tests
/// compose roles via [seededSession].
library;

import 'package:cli/src/session/credential_store.dart';
import 'package:cli/src/session/oidc_session.dart';

/// In-memory [CredentialStore]. Default state: empty (read returns null).
final class FakeCredentialStore implements CredentialStore {
  FakeCredentialStore({OidcSession? seed}) : _stored = seed;

  OidcSession? _stored;

  /// Convenience builder used by RBAC tests — produces an [OidcSession]
  /// with the requested [roles] and an obviously-synthetic identity.
  static OidcSession seededSession({
    List<String> roles = const ['social_worker'],
    String userId = 'test-user-FAKE',
    String email = 'test@example.invalid',
  }) => OidcSession(
    accessToken: 'test-access-token-FAKE',
    refreshToken: 'test-refresh-token-FAKE',
    idToken: 'test-id-token-FAKE',
    accessExpiresAt: DateTime.utc(2099, 1, 1),
    sub: userId,
    email: email,
    roles: roles,
  );

  @override
  Future<OidcSession?> read() async => _stored;

  @override
  Future<void> write(OidcSession session) async {
    _stored = session;
  }

  @override
  Future<void> clear() async {
    _stored = null;
  }
}

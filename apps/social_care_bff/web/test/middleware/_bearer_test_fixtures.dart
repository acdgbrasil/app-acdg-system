/// Constant fixtures for BearerAuthMiddleware tests.
///
/// All tests share a single in-memory RSA key pair (generated lazily inside
/// [_bearer_test_helpers.dart]) — fixtures here are configuration constants
/// only.  Keep this file dependency-free so it compiles even before the
/// production code exists (RED phase).
library;

/// Issuer URL — must match `ServerConfig.oidcIssuer` in tests.
const String kValidIssuer = 'https://auth.acdgbrasil.com.br';

/// CLI client ID — matches `ServerConfig.oidcCliClientId` (D1).
///
/// New env var `OIDC_CLI_CLIENT_ID` introduced by ticket C00.
const String kValidCliClientId = 'acdg-cli-client-id-fixture';

/// A different client id, used to simulate audience-mismatch attacks.
const String kOtherClientId = 'some-other-app-client-id';

/// `sub` claim — opaque user identifier from Zitadel.
const String kValidSubject = 'user-uuid-1234';

/// Roles array as carried in the JWT claim.
const List<String> kValidRoles = <String>['social_worker'];

/// Custom claim path Zitadel uses to ship roles (D3, mirrors the Swift backend
/// `ZitadelJWTPayload.swift:13`).
const String kJwtRolesClaim = 'urn:zitadel:iam:org:project:roles';

/// Session HMAC secret — must match `ServerConfig.sessionSecret`.
///
/// Fixed test secret so that HMAC-derived session ids are deterministic
/// across runs.
const String kSessionSecret =
    'test-session-secret-32-bytes-long-aaa';

/// `kid` (JWKS key id) for the primary signing key. Tests reference it by
/// name to keep fixtures stable.
const String kValidKid = 'test-kid-primary';

/// `kid` for the rotated/secondary key in JWKS rotation tests (Group G).
const String kSecondaryKid = 'test-kid-secondary';

/// Fixed reference time used by tests with an injectable clock.
///
/// Picked to be far enough in the future that real wall-clock drift in CI
/// never collides with the deterministic `iat`/`exp` values built around it.
final DateTime kNow = DateTime.utc(2026, 6, 1, 12, 0, 0);

/// Default leeway for `exp` / `nbf` validation (D7) — 30s per ticket.
const Duration kDefaultLeeway = Duration(seconds: 30);

/// Maximum accepted Authorization Bearer payload size, in bytes (constraint #1).
const int kMaxTokenBytes = 8192;

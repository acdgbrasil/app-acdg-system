# C02 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** RED state achieved. 191 analyzer errors (all `uri_does_not_exist` / `undefined_class` / `undefined_function` against missing W1 impl symbols). 5 info-level lints (all `depend_on_referenced_packages` for `http` / `crypto` — W1 must add to pubspec). No syntactic, lint, or unrelated failures. C01 tests not modified are green.

## 1. Test files created / modified

| File (path under repo root) | Tests | Status |
|------|-------|--------|
| `apps/cli/test/oidc/pkce_pair_test.dart` | 8 | NEW |
| `apps/cli/test/oidc/oidc_discovery_test.dart` | 6 | NEW |
| `apps/cli/test/oidc/loopback_listener_test.dart` | 11 | NEW |
| `apps/cli/test/oidc/token_client_test.dart` | 12 | NEW |
| `apps/cli/test/session/oidc_session_test.dart` | 8 | NEW |
| `apps/cli/test/commands/auth_command_test.dart` | 4 | **REPLACED** (C01 stub → C02 parent) |
| `apps/cli/test/commands/auth_login_command_test.dart` | 6 | NEW |
| `apps/cli/test/commands/auth_status_command_test.dart` | 4 | NEW |
| `apps/cli/test/commands/auth_logout_command_test.dart` | 5 | NEW |
| `apps/cli/test/commands/auth_refresh_command_test.dart` | 5 | NEW |
| `apps/cli/test/session/bff_client_test.dart` | 5 → 8 | EXTENDED (C01 tests untouched, +3 C02 tests + 4 fakes appended) |

**Net new C02 tests:** ~68. Above DoD floor of 30.

## 2. Public surface declared (the contract W1 must implement)

### `apps/cli/lib/src/oidc/pkce_pair.dart`
```dart
final class PkcePair with Equatable {
  const PkcePair({required this.verifier, required this.challenge});
  final String verifier;
  final String challenge;
  static const String method = 'S256';
  factory PkcePair.generate();        // 64 random bytes, b64url no-pad
}
```

### `apps/cli/lib/src/oidc/oidc_discovery.dart`
```dart
class OidcDiscovery with Equatable {  // NOT `final` — fakes implement it
  const OidcDiscovery({required this.issuer, required this.authorizationEndpoint, ... 8 fields});
  static Future<Result<OidcDiscovery>> load({required http.Client httpClient, required String issuer});
}
```
Failure paths: HTTP non-200; issuer mismatch (anti-spoofing); malformed JSON; missing endpoint; httpClient throws.

### `apps/cli/lib/src/oidc/loopback_listener.dart`
```dart
class LoopbackListener {              // NOT `final` — fakes implement it
  LoopbackListener({required this.expectedState, this.timeout = const Duration(minutes: 5), void Function(String)? logger});
  final String expectedState;
  final Duration timeout;
  Future<int> bindEphemeralPort();
  Future<Result<String>> awaitCallback();
}
```
Defensive behaviors tested: multi-hit, `_rsc=` filter (204), state CSRF (204), wrong path (404), wrong method (405), authorize-error pass-through (Failure), hard timeout (Failure), logger never receives raw `code=` query string.

### `apps/cli/lib/src/oidc/token_client.dart`
```dart
final class TokenResponse with Equatable {
  const TokenResponse({required this.accessToken, required this.refreshToken, required this.idToken,
                       required this.tokenType, required this.expiresIn});
}

class TokenClient {                   // NOT `final` — fakes implement it
  TokenClient({required OidcDiscovery discovery, required http.Client httpClient});
  OidcDiscovery get discovery;
  Future<Result<TokenResponse>> exchangeCode({required String code, required String codeVerifier, required String redirectUri, String clientId});
  Future<Result<TokenResponse>> refresh({required String refreshToken, String clientId, String scopes});
}
```
Form-body invariants asserted: `grant_type=authorization_code` / `grant_type=refresh_token`; includes `client_id`, `code_verifier`, `redirect_uri`; **never `client_secret`** (PKCE-only).

### `apps/cli/lib/src/errors/cli_error.dart` — extension
```dart
final class RefreshTokenInvalidError extends CliError {
  const RefreshTokenInvalidError([String? detail])
      : super(detail ?? 'Refresh token rotated or revoked. Run: acdg auth login');
}
```
Surface specifically when `refresh()` receives 400 + `error: invalid_grant` AND `error_description` contains `RefreshTokenInvalid`. Tests key off `isA<RefreshTokenInvalidError>()` to drive exit-7 branch.

### `apps/cli/lib/src/session/oidc_session.dart`
```dart
final class OidcSession with Equatable {
  const OidcSession({required this.accessToken, required this.refreshToken, required this.idToken,
                     required this.accessExpiresAt, required this.sub, required this.email, required this.roles});
  factory OidcSession.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
  bool isExpired({DateTime? now});    // now >= accessExpiresAt - 60s
}
```

### `apps/cli/lib/src/session/credential_store.dart` — migration
```dart
abstract interface class CredentialStore {
  Future<OidcSession?> read();
  Future<void> write(OidcSession session);
  Future<void> clear();
}
```
See §4.1 for migration strategy.

### `apps/cli/lib/src/session/bff_client.dart` — refresh-retry
```dart
BffClient({
  required this.baseUrl,
  required CredentialStore credentialStore,
  TokenClient? tokenClient,        // NEW — optional (keeps C01 tests compiling)
  OidcDiscovery? discovery,        // NEW — required if tokenClient != null
  Dio? dio,
});
```
On 401: refresh once, retry once with new bearer; on `RefreshTokenInvalidError`, clear store + return `Failure(AuthRequiredError)`; refresh path invoked at most once per request.

### Auth subcommands (4 new files + AuthCommand refactor)
`AuthCommand` becomes parent registering `AuthLoginCommand`, `AuthStatusCommand`, `AuthLogoutCommand`, `AuthRefreshCommand` as subcommands.

**Exit code matrix:**
| Command | Exit | Condition |
|---------|-----:|-----------|
| `auth login` | 0 / non-zero | success / discovery+authorize+exchange failure |
| `auth status` | 0 / 1 / 2 | valid / no session / expired |
| `auth logout` | 0 | always (idempotent, best-effort revoke) |
| `auth refresh` | 0 / 1 / 7 / non-zero | success / no session / RefreshTokenInvalid (clears local) / other (keeps session) |

## 3. New deps for `apps/cli/pubspec.yaml` (W1 must add)

```yaml
dependencies:
  http: ^1.4.0          # OIDC discovery + token endpoint
  crypto: ^3.0.6        # SHA-256 for PKCE challenge
```

Both already used at the same versions by `apps/social_care_bff/web` — pin consistently.

## 4. Open questions / migration notes

### 4.1 `Credentials` → `OidcSession` (BLOCKER for W1 to decide)

C01 has `Credentials` (3 fields). C02 needs `OidcSession` (7 fields).

**Strategy A (RECOMMENDED): clean break.** Delete `Credentials`, introduce `OidcSession`, update `CredentialStore`, and have W1 also migrate `apps/cli/test/session/credential_store_test.dart` to use `OidcSession` fixtures inside the same C02 commit. W0 deliberately did not touch the C01 test; W1 owns that migration.

**Strategy B: keep both.** `Credentials` survives as deprecated low-level struct; `OidcSession` is the new authoritative type. Avoid — surface-area bloat.

### 4.2 `bff_client_test.dart` extension (no test removed; appended only)

Existing C01 tests use `Credentials`. Appended C02 tests use `OidcSession`. If W1 picks Strategy A, the C01 part will fail to compile until W1 migrates fakes to use `OidcSession`. W0 left C01 tests intact — W1 owns the migration commit.

### 4.3 `LoopbackListener` / `OidcDiscovery` / `TokenClient` are `class` (not `final class`)

Command-level orchestration tests use Fakes that `implements` these types. A `final class` would block `implements`. W1 must declare them as plain `class`. Optional: separate `abstract interface class XxxContract` for stricter boundaries.

### 4.4 No `LoopbackListener.dispose()` in current contract

Two listener tests don't call `awaitCallback()`. Without `close()`, the bound port lingers until process exit. Benign in `dart test`, but if W1 hits flaky port-collision, add a public `Future<void> close()`.

### 4.5 `StringSink` vs `Stdout`

All command tests inject `StringSink` (a `StringBuffer` for assertions). W1 must keep the C01 pattern — never write to `Stdio.stdout` directly inside a Command's `run()`.

### 4.6 No `Process.run` inside commands

`AuthLoginCommand` takes a `Future<void> Function(Uri) browserOpener` collaborator. Tests inject a no-op closure. W1 must inject the real `openBrowser(Uri)` at wiring level (`cli_runner.dart`/`bin/acdg.dart`), NOT inside the command.

### 4.7 Fixed state/nonce in tests

`AuthLoginCommand` accepts a `({String state, String nonce}) Function() stateNonceFactory`. Real impl uses `Random.secure()` for both (32 random bytes hex). Tests inject a constant factory so authorize-URL invariants are deterministic.

## 5. RED state evidence

```
$ dart analyze apps/cli/test/
191 errors:
  56 undefined_function       — symbols not yet implemented
  44 non_type_as_type_argument — types not yet declared
  32 undefined_class
  24 uri_does_not_exist        — files W1 will create
  16 undefined_identifier
   6 undefined_named_parameter
   5 const_initialized_with_non_constant_value (downstream of undefined OidcDiscovery)
   4 implements_non_class       (fakes can't implement undeclared types)
   2 invalid_constant
   2 creation_with_non_type
5 infos: all `depend_on_referenced_packages` for `http`/`crypto` (W1 adds to pubspec)
0 warnings
```

`dart test` aborts at compile-time with `Method not found: 'PkcePair'` — exact RED state W1 needs to flip green.

C01 untouched files compile cleanly:
- `apps/cli/test/session/credential_store_test.dart` → "No issues found".
- All non-auth command tests still parse.

## 6. Confirmation: no impl files were touched

`git status apps/cli/lib/` clean — no impl edits.

Edits confined to:
- `apps/cli/test/oidc/*.dart` (4 new files, new directory)
- `apps/cli/test/commands/auth_*_command_test.dart` (4 new files)
- `apps/cli/test/commands/auth_command_test.dart` (replaced C01 stub contract)
- `apps/cli/test/session/oidc_session_test.dart` (1 new file)
- `apps/cli/test/session/bff_client_test.dart` (append-only)

No edits to `apps/cli/lib/src/`, `apps/cli/lib/cli.dart`, `apps/cli/pubspec.yaml`, or any sibling package.

## 7. Suggested W1 build order

1. `pkce_pair.dart` (zero deps)
2. `oidc_session.dart` + migrate `credential_store.dart` + update `apps/cli/test/session/credential_store_test.dart` (Strategy A)
3. `oidc_discovery.dart` (uses `package:http`)
4. `loopback_listener.dart` (uses `dart:io`)
5. `token_client.dart` (uses `package:http` + `OidcDiscovery`)
6. `cli_error.dart` extension — add `RefreshTokenInvalidError`
7. `bff_client.dart` refresh-retry path
8. Four `auth_*_command.dart` files + refactor `auth_command.dart` parent
9. Wire everything in `cli_runner.dart` / `bin/acdg.dart`
10. Add `http: ^1.4.0` and `crypto: ^3.0.6` to `apps/cli/pubspec.yaml`

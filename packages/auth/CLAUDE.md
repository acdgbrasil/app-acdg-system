# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

Standalone authentication package for the ACDG frontend monorepo. Extracted from `packages/core` to isolate auth concerns. Provides OIDC integration with Zitadel, auth state management, role-based access models, and token handling.

**Consulte `frontend/CLAUDE.md` e `frontend/handbook/` para convenções do monorepo.**

## Commands

```bash
flutter test                              # Run all tests
flutter test test/models/auth_role_test.dart  # Run a single test file
flutter test --coverage                   # Tests with coverage report
flutter analyze                           # Lint
```

This package uses workspace resolution (`resolution: workspace` in pubspec.yaml) — dependencies are resolved from the monorepo root.

## Architecture

### Public API (`lib/auth.dart`)

All types exported from a single barrel file. Consumers import `package:auth/auth.dart`.

### Folder Structure

```
lib/src/
  models/            — Pure data: AuthRole, AuthUser, AuthToken, AuthStatus
  services/          — Contract (AuthService interface)
    oidc/            — Zitadel OIDC impl (OidcAuthService, OidcAuthConfig, OidcClaimsParser)

test/                — Mirrors lib/src/ structure exactly
  models/            — Model unit tests (no mocks needed)
  services/oidc/     — Service tests (config, parsers, lifecycle, login, logout, session)
```

### Key Types

| Type | Location | Role |
|------|----------|------|
| `AuthService` | `services/` | Abstract contract — the only type features/shell depend on for auth |
| `OidcAuthService` | `services/oidc/` | Production impl using `package:oidc` (Bdaya-Dev) against Zitadel OIDC PKCE |
| `AuthStatus` | `models/` | Sealed class: `Authenticated`, `Unauthenticated`, `AuthLoading`, `AuthError` |
| `AuthUser` | `models/` | Immutable user with identity claims + resolved `AuthRole` set |
| `AuthToken` | `models/` | Immutable token set with injectable `isExpired({DateTime? now})` |
| `AuthRole` | `models/` | Enum: `socialWorker`, `owner`, `admin` — from JWT claim `urn:zitadel:iam:org:project:roles` |
| `OidcClaimsParser` | `services/oidc/` | Pure functions: JWT claims → `AuthUser`, raw token data → `AuthToken` |
| `OidcAuthConfig` | `services/oidc/` | Config VO (issuer, clientId, redirectUri, scopes) via `--dart-define` |

### Lifecycle

`AuthService.init()` → `tryRestoreSession()` → ready. The `init()` method is part of the contract — all implementations (real and fake) must honor it. Auth state flows through `statusStream` (broadcast `Stream<AuthStatus>`).

### Patterns

- **copyWith with ValueGetter** for nullable fields: `user.copyWith(name: () => null)` clears, `user.copyWith(name: () => 'Ana')` sets
- **Injectable time** on `AuthToken.isExpired({DateTime? now})` and `expiresWithin(threshold, {now})` for deterministic tests
- **Sealed class** `AuthStatus` for exhaustive pattern matching
- **Stateless const classes** (`Unauthenticated`, `AuthLoading`) rely on const canonicalization for equality

### Platform Differences

- **Web:** Refresh token in HttpOnly cookie (Split-Token) — `AuthToken.refreshToken` may be `null`
- **Desktop:** Tokens via `flutter_secure_storage` (Keychain/DPAPI/libsecret)

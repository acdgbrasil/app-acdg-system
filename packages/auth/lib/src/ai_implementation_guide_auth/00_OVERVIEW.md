# 00 - OVERVIEW: Auth Package — Guia de Implementacao para IA

> **Objetivo:** Permitir que uma IA reproduza 1:1 todo o package `auth` do app Flutter "Conecta Raros" (ACDG Technology). Este package e responsavel por autenticacao OIDC com Zitadel, gerenciamento de sessao, roles e tokens.

---

## INDICE DOS DOCUMENTOS

| Doc | Conteudo |
|-----|----------|
| `00_OVERVIEW.md` | Este arquivo. Arquitetura, estrutura, dependencias |
| `01_MODELS.md` | AuthRole, AuthStatus, AuthToken, AuthUser — todos os campos, metodos, padroes |
| `02_SERVICES.md` | AuthService (interface), OidcAuthService, BffAuthService, OidcClaimsParser, configs |
| `03_REPOSITORY_AND_PATTERNS.md` | AuthRepository, error handling, testing contract, padroes transversais |

---

## STACK E DEPENDENCIAS

```yaml
name: auth
version: 0.1.2

dependencies:
  flutter: sdk
  core: path ../core         # Result<T>, Equatable, AcdgLogger
  http: ^1.4.0               # HTTP client (para BffAuthService)
  oidc: ^0.14.0+2            # Bdaya-Dev OIDC (Authorization Code + PKCE)
  oidc_default_store: ^0.6.0+2  # Token persistence (Keychain/DPAPI/libsecret)
  url_launcher: ^6.3.1       # Abrir URL de login no browser (BFF flow)

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^6.0.0
```

---

## PROPOSITO DO PACKAGE

O `auth` package encapsula toda autenticacao do app:
- **OIDC com Zitadel** (Authorization Code + PKCE) para Desktop nativo
- **BFF server-side auth** para Web (tokens NUNCA no browser)
- **Models de dominio** imutaveis (user, roles, tokens, status)
- **Repository** como ponte entre UI e services (Result<T>, ChangeNotifier)

---

## ARQUITETURA

```
┌─────────────────────────────────────────────┐
│                   UI Layer                   │
│  (GoRouter redirect, Provider, Widgets)      │
├─────────────────────────────────────────────┤
│              AuthRepository                  │
│  (ChangeNotifier, Result<T>, Stream)         │
├─────────────────────────────────────────────┤
│              AuthService (abstract)          │
├────────────────────┬────────────────────────┤
│  OidcAuthService   │   BffAuthService        │
│  (Desktop)         │   (Web)                 │
│  package:oidc      │   HTTP + cookies        │
│  Zitadel PKCE      │   Server-side tokens    │
├────────────────────┴────────────────────────┤
│         Models (AuthUser, AuthToken,         │
│          AuthRole, AuthStatus)               │
└─────────────────────────────────────────────┘
```

### Fluxo de Dados

```
[Zitadel IdP]
     │
     ▼
[AuthService] ← implementacao varia por plataforma
     │ Stream<AuthStatus>
     ▼
[AuthRepository] ← wraps em Result<T>, extends ChangeNotifier
     │ notifyListeners()
     ▼
[UI] ← GoRouter redirect, Provider listen, widget rebuild
```

---

## ESTRUTURA DE PASTAS

```
auth/
├── lib/
│   ├── auth.dart                          # Barrel file (re-exports tudo)
│   └── src/
│       ├── models/
│       │   ├── auth_role.dart             # Enum: socialWorker, owner, admin
│       │   ├── auth_status.dart           # Sealed: Authenticated, Unauthenticated, Loading, Error
│       │   ├── auth_token.dart            # Final class: access/refresh/id tokens + expiry
│       │   └── auth_user.dart             # Final class: id, name, email, roles, permissions
│       │
│       ├── repositories/
│       │   └── auth_repository.dart       # Abstract + impl (ChangeNotifier, Result<T>)
│       │
│       └── services/
│           ├── auth_service.dart          # Abstract interface (lifecycle completo)
│           ├── bff/
│           │   ├── bff_auth_config.dart   # Config: bffBaseUrl
│           │   └── bff_auth_service.dart  # Web impl: server-side tokens, HTTP cookies
│           └── oidc/
│               ├── oidc_auth_config.dart  # Config: issuer, clientId, redirectUri, scopes
│               ├── oidc_auth_service.dart # Desktop impl: package:oidc, Zitadel PKCE
│               └── oidc_claims_parser.dart # Pure functions: JWT claims → domain models
│
├── test/
│   ├── models/                            # 4 test files (role, status, token, user)
│   └── services/
│       ├── bff/                           # 1 test file (full coverage)
│       └── oidc/                          # 6 test files (config, parsers, service stubs)
│
└── handbook/
    ├── BEST_PRACTICES.md                  # 10 padroes consolidados de code reviews
    └── code_review/                       # 5 reviews detalhados com antes/depois
```

---

## PUBLIC API (auth.dart)

O barrel file exporta TUDO:

```dart
library auth;

// Models
export 'src/models/auth_role.dart';
export 'src/models/auth_status.dart';
export 'src/models/auth_token.dart';
export 'src/models/auth_user.dart';

// Repository
export 'src/repositories/auth_repository.dart';

// Services
export 'src/services/auth_service.dart';
export 'src/services/bff/bff_auth_config.dart';
export 'src/services/bff/bff_auth_service.dart';
export 'src/services/oidc/oidc_auth_config.dart';
export 'src/services/oidc/oidc_auth_service.dart';
export 'src/services/oidc/oidc_claims_parser.dart';
```

---

## PLATAFORMAS

| Plataforma | AuthService | Token Storage | Login Flow |
|------------|-------------|---------------|------------|
| **Desktop** (macOS/Windows/Linux) | `OidcAuthService` | `flutter_secure_storage` (Keychain/DPAPI/libsecret) via `oidc_default_store` | Authorization Code + PKCE, redirect `http://localhost:0` |
| **Web** | `BffAuthService` | HttpOnly cookie (server-side) | Browser redirect para BFF `/auth/login` → Zitadel → callback → session cookie |

### Zitadel IdP

- **Issuer:** `https://auth.acdgbrasil.com.br`
- **Client type:** Public (sem client secret)
- **Auth method:** `OidcClientAuthentication.none(clientId: ...)`
- **Grant type:** Authorization Code + PKCE
- **Scopes:** `openid`, `profile`, `email`, `offline_access`, `urn:zitadel:iam:org:project:roles`
- **Roles claim:** `urn:zitadel:iam:org:project:roles` (nested map: `{roleKey: {orgId: domain}}`)
- **3 Roles:** `social_worker` (CRUD), `owner` (read-only), `admin` (read + gestao)

---

## DIAGRAMA DE CLASSE COMPLETO

```
AuthRole (enum)
├── socialWorker ('social_worker')
├── owner ('owner')
└── admin ('admin')
    Methods: fromString(), fromJwtClaim()

AuthStatus (sealed, Equatable)
├── Authenticated(AuthUser user)
├── Unauthenticated()
├── AuthLoading()
└── AuthError(String message)

AuthToken (final class, Equatable)
├── accessToken: String (required)
├── refreshToken: String? (nullable on web)
├── idToken: String?
├── expiresAt: DateTime (required)
    Methods: isExpired(), expiresWithin(), copyWith()

AuthUser (final class, Equatable)
├── id: String (required, sub claim)
├── name: String?
├── email: String?
├── preferredUsername: String?
├── roles: Set<AuthRole> (required)
    Methods: displayName, hasRole(), hasAnyRole(), canWrite, canRead, copyWith()

AuthService (abstract)
    Methods: init(), login(), logout(), tryRestoreSession(), refreshToken(), dispose()
    Properties: statusStream, currentStatus, currentUser, currentToken
    ├── OidcAuthService (uses OidcAuthConfig + OidcClaimsParser)
    └── BffAuthService (uses BffAuthConfig + http.Client)

AuthRepository (abstract, Listenable)
    Methods: init(), login(), logout(), tryRestoreSession(), dispose()
    Properties: statusStream, currentStatus, currentUser, currentToken
    └── AuthRepositoryImpl (extends ChangeNotifier, wraps AuthService)

OidcClaimsParser (stateless, pure functions)
    Methods: userFromClaims(), tokenFromRaw()
```

---

## COMO USAR ESTA DOCUMENTACAO

1. **Comece por `01_MODELS.md`** — entenda os 4 domain models (role, status, token, user)
2. **Leia `02_SERVICES.md`** — entenda as 2 implementacoes (OIDC desktop, BFF web) + parser
3. **Consulte `03_REPOSITORY_AND_PATTERNS.md`** — entenda o repository, error handling, e padroes

Cada documento inclui:
- Assinaturas completas de classes/metodos
- Todos os campos com tipos e valores default
- Strings hardcoded (PT-BR e EN)
- Padroes de implementacao (ValueGetter, sealed, injectable time)
- Contrato de teste (o que DEVE funcionar e como)

# A07 — Web: Auth (handler + intents + use_cases + observability)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A06d ✅

## Escopo

**5 endpoints** de auth consumindo o kernel estabilizado:
- `GET  /api/auth/login`
- `GET  /api/auth/callback`
- `POST /api/auth/logout`
- `GET  /api/auth/me`
- `POST /api/auth/refresh`

**Estado atual:**
- `auth_handler.dart` tem 279L com 5 rotas funcionais
- Somente `AuthCallbackIntent` + `AuthCallbackUseCase` existem (Phase 2)
- Faltam: `LoginIntent/UseCase`, `LogoutIntent/UseCase`, `MeIntent/UseCase`, `RefreshIntent/UseCase`
- Consumo direto de `OidcServerClient` + `SessionStore` (camada remote)

**Objetivo do ticket:**
1. Criar os 4 Intents/UseCases faltantes seguindo Contract B
2. Refatorar handler para orquestração limpa (thin handler)
3. **Adicionar observabilidade estratégica desde o nascimento** (dor declarada do usuário)
4. Aplicar TODAS as novas políticas
5. TDD com fakes (usando `FakeAuthBff` e auth fakes)

## Políticas aplicáveis (consultar antes de escrever código)

- **ENCAPSULATION_POLICY.md** §H1 `implements > extends`; §H2 composition; §H4 sealed; §H5 `abstract interface class`
- **PATTERN_MATCHING_POLICY.md** §P1 state matrix para result → response; §P2 `if case` para parse de query/body; §P3 tear-offs em `.map`; §P4 `unreachable` do `package:core`
- **CONCURRENCY_AND_PERFORMANCE_POLICY.md** §C2 `base class` para AuthHandler se fizer sentido

## Observabilidade — nova política embutida

A dor é: **"não saber o que acontece quando chega nas views"**. Este ticket introduz o padrão canônico a ser replicado em todos os handlers da Onda 3.

### Conceitos

Cada request HTTP do BFF Web deve deixar um **rastro estruturado** cobrindo:

| Momento | Evento | Exemplo |
|---------|--------|---------|
| Request received | breadcrumb | `auth.login.received { pkceState, requestId }` |
| Intent parse | breadcrumb (on parse error: error) | `auth.callback.parse_failed { reason }` |
| UseCase start | breadcrumb | `auth.callback.orchestrating` |
| Backend call (OIDC) | breadcrumb | `oidc.token_exchange.issued` |
| Response dispatched | breadcrumb | `auth.callback.response_sent { status }` |
| Exception | error + stack | propagado via `unreachable` ou `Failure` |

### Implementação

Criar **middleware** `observabilityMiddleware(Handler inner)` em `bff/social_care_web/lib/src/middleware/observability.dart`:
- Gera `requestId` por request (UUID ou nanoid) e injeta em `Request.context['requestId']`
- Abre escopo estruturado (Map) disponível aos handlers
- Registra `request.received` (método + path + requestId) em breadcrumb
- Captura exceções não-esperadas com contexto
- Registra `request.completed` (status + ms) ao final

Usar `Logger.root` do `package:logging` (já integrado com AcdgLogger + Sentry — ver `packages/core/lib/src/utils/acdg_logger.dart`).

Handlers usam um helper `ObservabilityContext.of(request)` que expõe:
- `context.requestId`
- `context.breadcrumb(String name, {Map<String, Object?> data})`
- `context.logError(String message, {Object? cause, StackTrace? stack})`

### PII policy em logs

Campos proibidos de serem logados **em claro**:
- CPF, CNS, RG (números brutos) → **mascarar** (ex: `12*****82`)
- Access/refresh tokens → **nunca**
- E-mail completo → **hash parcial** ou último-domínio-only
- `code` (OIDC authorization code) → **prefix only** (primeiros 6 chars + `***`)

Alinhado com `fix(domain)!: relax RGDocument validation` do backend — PII sempre em `safeContext`, nunca em `context` cru.

## Arquitetura proposta

```
┌─────────────────────────────────────────────────────────────┐
│  shelf Pipeline                                             │
│    └─ observabilityMiddleware (breadcrumbs + requestId)     │
│        └─ securityHeaders / csrf / session middleware...    │
│            └─ AuthHandler (thin router)                     │
│                  │                                          │
│                  ├─ /login    ─► LoginIntent → LoginUseCase │
│                  ├─ /callback ─► AuthCallbackIntent → UC    │
│                  ├─ /logout   ─► LogoutIntent → LogoutUseCase│
│                  ├─ /me       ─► MeIntent → MeUseCase       │
│                  └─ /refresh  ─► RefreshIntent → RefreshUC  │
│                                    │                        │
│                                    ▼                        │
│                         AuthContract (de A04)               │
│                                    │                        │
│                                    ▼                        │
│                        Zitadel (OIDC) via OidcServerClient  │
└─────────────────────────────────────────────────────────────┘
```

## Intents (5)

Criar `bff/social_care_web/lib/src/intents/`:

### 1. `LoginIntent` — novo
Dispara redirect para Zitadel. Gera PKCE state.
```dart
final class LoginIntent with Equatable {
  const LoginIntent({this.returnTo});
  final String? returnTo;  // URL opcional para redirect pós-login
  @override List<Object?> get props => [returnTo];
}
```

### 2. `AuthCallbackIntent` — existente, adaptar
Já existe mas tem `FormatException` inline — substituir por `Result<AuthCallbackIntent>` + `if case` (P2).

### 3. `LogoutIntent` — novo
Revoga session.
```dart
final class LogoutIntent with Equatable {
  const LogoutIntent({required this.sessionId});
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}
```

### 4. `MeIntent` — novo
Trivial — apenas referencia a sessão atual (session cookie resolve).
```dart
final class MeIntent with Equatable {
  const MeIntent({required this.sessionId});
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}
```

### 5. `RefreshIntent` — novo
```dart
final class RefreshIntent with Equatable {
  const RefreshIntent({required this.sessionId});
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}
```

## UseCases (5)

Criar `bff/social_care_web/lib/src/use_cases/`:

Cada um recebe Intent, usa `AuthContract` de A04, retorna `Result<Response>`:
- `LoginUseCase.execute(LoginIntent) → Result<String>` (URL de redirect)
- `AuthCallbackUseCase.execute(AuthCallbackIntent) → Result<SessionEstablished>`
- `LogoutUseCase.execute(LogoutIntent) → Result<void>`
- `MeUseCase.execute(MeIntent) → Result<MeResponse>`
- `RefreshUseCase.execute(RefreshIntent) → Result<void>`

Cada UseCase emite breadcrumbs via `ObservabilityContext` injetado.

## Handler refatorado

```dart
final class AuthHandler {
  AuthHandler({
    required AuthContract contract,
    required LoginUseCase login,
    required AuthCallbackUseCase callback,
    required LogoutUseCase logout,
    required MeUseCase me,
    required RefreshUseCase refresh,
  }) : _login = login, _callback = callback, _logout = logout,
       _me = me, _refresh = refresh;

  final LoginUseCase _login;
  // ... (private final por Non-Negotiable #22)

  Router get router => Router()
    ..get('/auth/login', _handleLogin)
    ..get('/auth/callback', _handleCallback)
    ..post('/auth/logout', _handleLogout)
    ..get('/auth/me', _handleMe)
    ..post('/auth/refresh', _handleRefresh);

  Future<Response> _handleLogin(Request request) async {
    final obs = ObservabilityContext.of(request);
    obs.breadcrumb('auth.login.received');

    final intent = LoginIntent(returnTo: request.url.queryParameters['returnTo']);
    final result = await _login.execute(intent, obs);

    return switch (result) {
      Success(:final value) => Response.found(value),  // P1 state matrix
      Failure(:final error) => _errorResponse(error, obs),
    };
  }
  // ...
}
```

## TDD

### Wave 0 — test-writer
- Fakes em memória: usar `FakeAuthBff` (de A06) + fakes auxiliares para OidcServerClient/SessionStore se necessário
- Testes por Intent: parse happy path + edge cases
- Testes por UseCase: result success/failure
- Testes de handler: http in → http out (shelf test helpers)
- Testes de observability middleware: breadcrumbs emitidos corretamente

**Testes em `bff/social_care_web/test/`:**
- `handlers/auth_handler_test.dart`
- `intents/*_intent_test.dart` (5)
- `use_cases/*_use_case_test.dart` (5)
- `middleware/observability_test.dart`

### Wave 1 — implementer
Lê os testes RED. Implementa Intents, UseCases, Handler, middleware até GREEN.

## Critérios de aceitação
- [ ] 5 Intents + 5 UseCases em `intents/` e `use_cases/`
- [ ] `AuthHandler` refatorado, thin, consome UseCases via constructor injection privada
- [ ] `middleware/observability.dart` com breadcrumbs + requestId + Sentry forwarding
- [ ] Zero `throw` solto — usar `Result<T>` ou `unreachable`
- [ ] Aplica P1 (switch no result → response), P2 (if case em query/body), P3 (tear-offs onde couber)
- [ ] PII mascarada em logs (códigos OIDC, tokens, emails)
- [ ] Testes GREEN (Wave 0 RED → Wave 1 GREEN)
- [ ] `dart analyze bff/social_care_web/lib` zero errors **dentro do escopo do auth** (outros handlers podem ter errors herdados)

## Não faça
- Não migre outros handlers (A08–A15 cuidam deles)
- Não altere `AuthContract` (A04 já fechou; se faltar método, reportar como ambiguidade)
- Não usar `SocialCareContract` em lugar algum (deletado em A05)

## Status
ready to dispatch Wave 0

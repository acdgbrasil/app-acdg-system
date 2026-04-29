# A07 Wave 0 REPORT — Test Writer (Auth)

## Status: COMPLETED (RED)

12 test files criados, todos falham em load com undefined names — RED confirmado.

## Arquivos

**Intents (5):** login, auth_callback, logout, me, refresh (em `test/intents/`)
**UseCases (5 + 1 helper):** idem mais `test_observability.dart` com matchers compartilhados
**Handler (1):** `test/handlers/auth_handler_test.dart` (substituiu o existente)
**Middleware (1):** `test/middleware/observability_test.dart`

## Shape contratual para Wave 1

### Intents — `lib/src/intents/` (todos `final class with Equatable`)
- `LoginIntent({String? returnTo})` + `LoginIntent.parseFromQuery(Map<String, String>)`
- `AuthCallbackIntent({required String code, required String state})` — **substitui** o antigo; `static Result<AuthCallbackIntent> parseFromQuery(...)`; erro **não deve ecoar** o code bruto
- `LogoutIntent`, `MeIntent`, `RefreshIntent` — todos `{required String sessionId}`

### UseCases — `lib/src/use_cases/` (todos `final class`, `_auth` privado)
```
LoginUseCase.execute(LoginIntent, ObservabilityContext) → Result<String>
AuthCallbackUseCase.execute(AuthCallbackIntent, obs) → Result<StandardResponse<void>>
LogoutUseCase.execute(LogoutIntent, obs) → Result<StandardResponse<void>>
MeUseCase.execute(MeIntent, obs) → Result<MeResponse>  (unwraps StandardResponse.data)
RefreshUseCase.execute(RefreshIntent, obs) → Result<StandardResponse<void>>
```

**Breaking:** `AuthCallbackUseCase` constructor muda de positional `(oidc, sessions, factory)` para `({required AuthContract auth})`.

### ObservabilityContext — `lib/src/observability/observability_context.dart`
```dart
final class ObservabilityContext {
  factory ObservabilityContext.of(Request);     // unreachable se absent
  factory ObservabilityContext.noop();          // captura em memória p/ testes
  final String requestId;
  final List<BreadcrumbRecord> breadcrumbs;
  void breadcrumb(String event, {Map<String, Object?> data = const {}});
  void logError(String message, {Object? cause, StackTrace? stack});
}

final class BreadcrumbRecord with Equatable {
  final String event;
  final DateTime timestamp;
  final Map<String, Object?> data;
}
```

### AuthHandler — `lib/src/handlers/auth_handler.dart`
```dart
final class AuthHandler {
  AuthHandler({
    required LoginUseCase login,
    required AuthCallbackUseCase callback,
    required LogoutUseCase logout,
    required MeUseCase me,
    required RefreshUseCase refresh,
  });
  Router get router;
}
```
Cookie: `__Host-session=` com `HttpOnly; Secure; SameSite=Strict`. `/me` sem session → 401. Falhas mapeiam `BackendError.http ?? 500`.

### observabilityMiddleware — `lib/src/middleware/observability.dart`
```dart
Middleware observabilityMiddleware();
```
Injeta `Request.context['requestId']`. Emite `request.received` e `request.completed` (status + ms). Captura exceções não tratadas → Response 500. PII scrubbing obrigatório em logs.

## Observabilidade canônica (estabelecida por testes)

| Endpoint | On dispatch | On success | On failure |
|----------|-------------|------------|------------|
| `/auth/login` | `auth.login.received {returnTo}` | `auth.login.redirect_issued` | `auth.login.failed` |
| `/auth/callback` | `auth.callback.received {codePrefix}` | `auth.callback.session_established` | `auth.callback.failed` |
| `/auth/logout` | `auth.logout.received` | `auth.logout.completed` | `auth.logout.failed` |
| `/auth/me` | `auth.me.received` | `auth.me.resolved` | `auth.me.failed` |
| `/auth/refresh` | `auth.refresh.received` | `auth.refresh.completed` | `auth.refresh.failed` |

**PII masking enforced por testes:**
- OIDC `code` nunca em raw — usar `codePrefix` com primeiros 6 chars + `***`
- Email nunca como raw string
- Session IDs nunca em breadcrumbs
- `access_token` / `refresh_token` / `bearer <token>` proibidos em todas as camadas
- Exception messages proibidas em response bodies 500
- Parse errors de `AuthCallbackIntent` não devem ecoar o code

## Ajustes arquiteturais identificados (Wave 1 precisa resolver)

### 1. Location do `ObservabilityContext`
Ticket sugeria `packages/core` mas core depende de Flutter. BFF é Dart puro.
**Decisão:** criar em `bff/social_care_web/lib/src/observability/` (nova pasta).

### 2. Location do `unreachable`
Mesmo problema — está em `packages/core/lib/src/utils/unreachable.dart` (Flutter-tainted).
**Decisão recomendada:** **promover para `core_contracts`** (pure Dart) — solução limpa e reutilizável por BFF + Flutter.
**Alternativa:** copiar inline no BFF. Evitar duplicação.

### 3. Breaking changes inevitáveis
- `auth_callback_intent.dart` — rewrite obrigatório (fromParams throws → Result + if case)
- `auth_callback_use_case.dart` — constructor muda
- `server/app_router_test.dart` — wiring antigo precisa update para novo signature
- Session cookie: atual `__session=` → novo `__Host-session=`

## Notes para Wave 1

1. **Promover `unreachable` para `core_contracts`** antes de implementar — Maestro fará
2. Usar `package:logging` direto no middleware (não `AcdgLogger` por conta da dep Flutter)
3. `FakeAuthBff.login()` é idempotente — mantém o `redirectUrl` fixo
4. `test/use_cases/test_observability.dart` (matchers compartilhados) não move de lugar — depende de `package:test`
5. Handler usa **P1 state matrix** para result → response
6. Status code para Failures vem de `BackendError.http ?? 500`
7. Atualizar `server/app_router_test.dart` com novo constructor de `AuthHandler` (CI green)

## Proibições respeitadas
- Zero production code
- Nenhum contract/DTO/fake alterado
- Nenhum middleware real criado
- Zero `SocialCareContract` references
- Zero `throw` bare — especificam uso de `unreachable`

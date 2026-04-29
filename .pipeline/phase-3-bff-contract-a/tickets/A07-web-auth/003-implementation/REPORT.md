# A07 Wave 1 REPORT — Implementer (Auth)

## Status: COMPLETED (87/87 tests GREEN)

## Resultado
- `dart test test/intents/ test/use_cases/ test/handlers/auth_handler_test.dart test/middleware/observability_test.dart` → **87 GREEN**
- `dart analyze` escopo auth (13 arquivos) → **No issues found**
- Padrão canônico para Onda 3 estabelecido

## Arquivos

**Novos (10):** 4 intents + 4 use_cases + observability_context + observability middleware
**Reescritos (3):** auth_callback_intent, auth_callback_use_case, auth_handler
**Ajustados (4):** app_router, server.dart, app_router_test, pubspec.yaml

## Breakdown de testes
- Intents: **27 tests**
- UseCases: **32 tests**
- Handler: **16 tests** (5 endpoints + state matrix)
- Middleware: **12 tests** (requestId, breadcrumbs, PII scrub, 500 handling)

## Decisões técnicas notáveis

1. **`UuidUtil.generateV4()` de core_contracts** — evitou dep externa `uuid`
2. **PII scrub via `_scrubPath(Uri)`** — set de params sensíveis (`code`, `access_token`, `refresh_token`, `id_token`, `token`), reconstrói path sem valores
3. **Response 500 sanitizado** — `{error: {code: 'INTERNAL', message: 'Internal server error', requestId}}` — zero vazamento
4. **`ObservabilityContext.fromRequestOrNoop`** — tolerante a testes diretos sem pipeline
5. **`__Host-session` cookie** com `HttpOnly; Secure; SameSite=Strict; Path=/`
6. **`buildAuthHandler(AuthContract)` factory** em app_router — template canônico

## Padrão canônico para A08–A15

```
Intent (final class with Equatable):
  parseFromQuery(Map) → Result<Intent> ou Intent direto
  Mensagens nunca ecoam valores sensíveis

UseCase (final class):
  const ({required XContract contract}) : _contract = contract;
  execute(Intent, obs) → Result<Response>
  Breadcrumb triad: <bc>.<verb>.received → .completed/.resolved → .failed

Handler (final class):
  UseCases via DI privada
  P1 state matrix em switch (result)
  ObservabilityContext.fromRequestOrNoop(request)
  BackendError.http ?? 500 em failure

Factory: buildXHandler(XContract) em app_router.dart

Pipeline: observabilityMiddleware → sessionMiddleware → (authGuard?) → handler.router

PII: NUNCA logar code, tokens, session IDs brutos, emails, CPF/CNS/RG brutos
```

## Breadcrumb canon

| Endpoint | dispatch | success | failure |
|----------|----------|---------|---------|
| `/<bc>/<verb>` | `<bc>.<verb>.received` | `<bc>.<verb>.completed` (ou .resolved, .redirect_issued, .session_established) | `<bc>.<verb>.failed` |

## Escopo NÃO abordado (fora do A07)

- `server.dart` usa `FakeAuthBff()` como placeholder — implementação real OIDC-backed (adapter de `OidcServerClient` + `SessionStore` para `AuthContract`) fica para ticket futuro
- Errors pré-existentes em `lib/src/{handlers,server,use_cases,remote}` referentes a `SocialCareContract` (deletado em A05) — **fora do escopo A07**, serão resolvidos em A08-A15

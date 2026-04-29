# Ticket State: A07-web-auth

phase: implementation
agent: TDD (Wave 0 test-writer COMPLETED → Wave 1 implementer COMPLETED)
status: Wave 1 COMPLETED — 87/87 tests GREEN, auth scope analyzer clean

## Scope
5 endpoints auth + 5 Intents + 5 UseCases + observability middleware. Primeiro handler da Onda 3 — serve de padrão canônico aplicando TODAS as políticas (H1–H9, P1–P4, C1–C3, PII masking).

## Wave 0 — Test Writer (COMPLETED 2026-04-16)

### Arquivos criados (12 files)
- `bff/social_care_web/test/intents/login_intent_test.dart`
- `bff/social_care_web/test/intents/auth_callback_intent_test.dart`
- `bff/social_care_web/test/intents/logout_intent_test.dart`
- `bff/social_care_web/test/intents/me_intent_test.dart`
- `bff/social_care_web/test/intents/refresh_intent_test.dart`
- `bff/social_care_web/test/use_cases/test_observability.dart` (shared matchers)
- `bff/social_care_web/test/use_cases/login_use_case_test.dart`
- `bff/social_care_web/test/use_cases/auth_callback_use_case_test.dart`
- `bff/social_care_web/test/use_cases/logout_use_case_test.dart`
- `bff/social_care_web/test/use_cases/me_use_case_test.dart`
- `bff/social_care_web/test/use_cases/refresh_use_case_test.dart`
- `bff/social_care_web/test/handlers/auth_handler_test.dart` (replaced)
- `bff/social_care_web/test/middleware/observability_test.dart`

### RED verified
`dart test` reports 12 load failures with undefined names (LoginIntent, LoginUseCase, ObservabilityContext, observabilityMiddleware, etc.) — as expected.

## Wave 1 — Implementer (COMPLETED 2026-04-16)

### Arquivos criados (10 new files)
- `bff/social_care_web/lib/src/observability/observability_context.dart` (ObservabilityContext + BreadcrumbRecord)
- `bff/social_care_web/lib/src/middleware/observability.dart`
- `bff/social_care_web/lib/src/intents/login_intent.dart`
- `bff/social_care_web/lib/src/intents/logout_intent.dart`
- `bff/social_care_web/lib/src/intents/me_intent.dart`
- `bff/social_care_web/lib/src/intents/refresh_intent.dart`
- `bff/social_care_web/lib/src/use_cases/login_use_case.dart`
- `bff/social_care_web/lib/src/use_cases/logout_use_case.dart`
- `bff/social_care_web/lib/src/use_cases/me_use_case.dart`
- `bff/social_care_web/lib/src/use_cases/refresh_use_case.dart`

### Arquivos reescritos (3 files)
- `bff/social_care_web/lib/src/intents/auth_callback_intent.dart` (parseFromQuery → Result, PII-safe)
- `bff/social_care_web/lib/src/use_cases/auth_callback_use_case.dart` (AuthContract-based, obs)
- `bff/social_care_web/lib/src/handlers/auth_handler.dart` (thin handler, UseCase injection, state matrix)

### Arquivos ajustados (4 files)
- `bff/social_care_web/lib/src/server/app_router.dart` (wires AuthContract + buildAuthHandler factory)
- `bff/social_care_web/bin/server.dart` (temporary FakeAuthBff until OIDC-backed adapter ships)
- `bff/social_care_web/test/server/app_router_test.dart` (new AuthContract wiring)
- `bff/social_care_web/pubspec.yaml` (declared `logging` direct dep)

### GREEN verified
- `dart test test/intents/ test/use_cases/ test/handlers/auth_handler_test.dart test/middleware/observability_test.dart`
- 87/87 tests passing (27 intents + 32 use_cases + 16 handler + 12 middleware)
- `dart analyze` on auth scope: **No issues found**

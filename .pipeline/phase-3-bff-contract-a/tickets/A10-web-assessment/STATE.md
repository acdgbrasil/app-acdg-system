# Ticket State: A10-web-assessment

## Current Phase
phase: done
agent: implementer (Wave 1 GREEN)
status: completed — 122 new tests GREEN; 480 total (A07+A08+A09+A10) GREEN

## Completed Phases
- [x] 000-request — 7 endpoints PUT /patients/:id/assessment/*
- [x] 002-tests — Wave 0 RED (264 compile errors pinados)
- [x] 003-implementation — Wave 1 GREEN (15 prod files + 2 wiring + 1 legacy deletado)

## Resultado
- 7 Intents (all new) — padrão uniforme try/catch sobre fromJson
- 7 UseCases (all new) — tríade canônica
- 1 Handler `AssessmentHandler` com 7 rotas PUT — rewrite do legacy A05
- `app_router.dart` com `AssessmentContract` injetado + Cascade ordenado
- 122 tests A10 GREEN + 358 A07/A08/A09 inalterados = **480 GREEN**
- `dart analyze` zero errors no escopo A10

## Novidades arquiteturais
- **try/catch sobre fromJson** (vs P2 if-case) — mensagem estrutural genérica, zero field values, mais PII-safe que A07-A09
- **7× duplicação aceita** — abstração paramétrica rejeitada (hides breadcrumb namespaces + quebra grep 1:1)
- **Helpers duplicados em 3 handlers** — extrair em `handler_helpers.dart` pós-A15

## Invariantes pinados
- 7 mensagens literais exatas para `_UpdateXxxParseError`
- Event namespaces com snake_case: `socio_economic`, `work_and_income`, `educational_status`, `health_status`, `community_support`, `social_health_summary`
- PII Health: `.received` carrega APENAS `{patientId}` (nunca deficiency/caregiver)
- Handler 500 sanitiza non-BackendError
- Cascade ordem: patient → family → assessment

## Débito técnico
- Handlers legacy A11-A15 (care, lookup, protection, health, team) ainda quebrados por `SocialCareContract` undefined — cada ticket resolve o próprio
- Helper extraction `handler_helpers.dart` pós-A15
- `FakeAssessmentBff()` em bin/server.dart até adapter HTTP real (A21)
- DTO defaulting gotcha: fields com default Dart nunca throw em fromJson (documentado p/ A11+)

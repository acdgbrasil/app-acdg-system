# Ticket State: A13-web-lookup

## Current Phase
phase: done
agent: implementer (Wave 1 GREEN)
status: completed — 147 new tests GREEN; 638 canon total GREEN

## Completed Phases
- [x] 000-request — 8 endpoints governance (item CRUD + toggle + request workflow)
- [x] 002-tests — Wave 0 RED (17 test files; P2 + P2-tolerant + path-only + empty)
- [x] 003-implementation — Wave 1 GREEN (16 prod + 1 rewrite + 2 wiring)

## Resultado
- 8 Intents: 3 P2 + 1 P2-tolerant (estreia no monorepo) + 2 path-only + 1 empty + 1 path-only flat
- 8 UseCases (tríade canônica — alguns void com rewrap)
- 1 Handler LookupHandler rewrite (8 rotas — maior do monorepo)
- `app_router.dart` com LookupContract injetado + Cascade patient→family→assessment→care→protection→lookup
- 147 tests A13 + 491 prévios = **638 GREEN**

## Invariantes arquiteturais novas
- **P2-tolerant** (parse total, sem ParseError, sem 400 code) — variante natural de P2
- **`throw StateError` no handler** como padrão para documentar "parse total" invariante
- **Domain resource routes** (`/lookup-requests` flat) divergem do molde patient-centric

## Aprendizados para A14–A15
1. Wiring factory+field+Cascade é zero-cost reusável
2. Domain resources (team members, analytics queries) podem ter rotas flat sem patientId
3. Helpers duplicados em 4 handlers — extração fica mais justificada pós-A15

## Débito técnico
- Handlers legacy A14 (team) + A15 sim (se existir) ainda quebrados por SocialCareContract
- `FakeLookupBff()` em bin/server.dart até adapter HTTP real (A21)
- 2 legacy tests pré-existentes falhando (health_handler_test + social_care_api_client_test) — A14/A21 resolvem

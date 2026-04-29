# Ticket State: A09-web-registry-family

## Current Phase
phase: done
agent: flutter-implementer (Wave 1 GREEN)
status: completed — 114 new tests GREEN; 390 total (A07+A08+A09) GREEN

## Completed Phases
- [x] 000-request — escopo congelado (5 endpoints)
- [x] 002-tests — Wave 0 RED (245 compile errors pinados)
- [x] 003-implementation — Wave 1 GREEN (11 prod files + wiring)

## Resultado
- 5 Intents (1 rewrite + 4 novos)
- 5 UseCases (1 rewrite + 4 novos) — saga `AddFamilyMember` com sealed `_PersonResolution`
- 1 Handler `RegistryFamilyHandler` com 5 rotas
- `app_router.dart` com `AuditContract` injetado + `Cascade` para compor handlers
- 4 legados deletados (`registry_handler.dart`, `pre_registered_family_member_dto.dart`, 2 testes órfãos)
- 114 tests A09 + 276 canônicos A07/A08 = **390 GREEN**
- `dart analyze` zero errors no escopo A09

## Invariantes pinados
- Saga short-circuit: People.Failure → Registry.addFamilyMember NUNCA chamado (spy count == 0)
- PII: breadcrumbs usam flags (`hasCpf`, `hasPersonId`, `hasEventTypeFilter`, `hasPagination`); nunca CPF/name/description
- 500 `INTERNAL`: sanitiza exception message; nunca vaza stack ou prefixo `Exception:`
- 400 codes pinados por endpoint
- Event namespaces: `registry.family.{add,remove,assign_caregiver}.*`, `registry.social_identity.update.*`, `registry.audit_trail.get.*`

## Débito técnico deixado
- Sem compensação no saga (órfão em PeopleContext se Registry falhar após sucesso) — documentado
- Helpers `_readJsonBody`/`_errorResponse`/... duplicados entre `RegistryPatientHandler` e `RegistryFamilyHandler` — consolidação barata após A10–A15
- `FakeAuditBff()` no `bin/server.dart` até adapter HTTP real (A21)
- Handlers legacy A10–A15 (assessment, care, health, lookup, protection, team) ainda quebrados por `SocialCareContract` undefined — herdado de A08

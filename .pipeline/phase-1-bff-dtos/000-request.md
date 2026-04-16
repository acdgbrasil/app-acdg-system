# Pipeline Request: Phase 1 — BFF DTO Realignment

## Issues
- #47 — Criar Response DTOs tipados com @JsonSerializable
- #48 — Criar Request DTOs espelhando backend Swift
- #49 — Criar PaginatedList<T> e BackendError estruturado
- #50 — Reescrever SocialCareContract com sub-contratos por bounded context
- #59 — Testes de serialization round-trip para todos os DTOs novos

## Scope Classification
**Profile:** `data-layer` (customized — DTOs + contract rewrite + tests)

## Target Package
`bff/shared/` (shared BFF contract package)

## Key Decision: ACL Boundary
Sub-contracts use DTOs (Request/Response), NOT domain objects.
The contract becomes a pure transport layer. Mappers convert DTO <-> Domain.

## Waves

### Wave 0: Shared Infrastructure (#49)
- [x] PaginatedList<T>, BackendError, StandardResponse<T>, StandardIdResponse

### Wave 1: DTOs (parallel, #47 + #48)
- [x] Response DTOs (~30 types) organized by bounded context
- [x] Request DTOs (~25 types) mirroring Swift backend

### Wave 2: Contract Rewrite (#50, depends on Wave 1)
- [x] 8 sub-contracts: Health, Registry, Assessment, Care, Protection, Audit, People, Analytics
- [x] SocialCareContract implements all sub-contracts
- [x] All methods use DTOs, not domain objects

### Wave 3: Tests (#59, depends on Wave 2)
- [x] Round-trip tests for all Response DTOs
- [x] Round-trip tests for all Request DTOs
- [x] Round-trip tests for shared types

### Wave 4: Quality Gates
- [x] build_runner (generate .g.dart files)
- [x] dart analyze (zero warnings)
- [x] dart format
- [x] dart test (all pass)

## Contract Interactions (from user decision)
The contract reflects social_care's real interactions:
1. **Social Care backend** — registry, assessment, care, protection (core CRUD)
2. **People Context** — person registration, enrichment, role management
3. **Analysis BI** — anonymized indicators, axes metadata, dataset export

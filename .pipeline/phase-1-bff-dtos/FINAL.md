# FINAL — Phase 1: BFF DTO Realignment

## Summary
Phase 1 complete. Created typed DTOs, shared infrastructure types, sub-contracts by bounded context, and comprehensive round-trip tests for the BFF shared package.

## Issues Resolved
- **#49** — PaginatedList<T>, BackendError, StandardResponse<T>, StandardIdResponse
- **#47** — 30 Response DTOs with @JsonSerializable across 7 bounded contexts
- **#48** — 22 Request DTOs with @JsonSerializable across 5 bounded contexts
- **#50** — 8 sub-contracts (Health, Registry, Assessment, Care, Protection, Audit, People, Analytics) + composed SocialCareContract
- **#59** — 176 serialization round-trip tests, all passing

## Metrics
- **Files created:** 63 source + 54 generated (.g.dart) + 8 test = 125 total
- **DTOs:** ~70 classes (flat + nested sub-DTOs)
- **Tests:** 176 passing, 0 failures
- **dart analyze:** 0 issues
- **Breaking changes:** FakeSocialCareBff updated. Web/Desktop BFF implementations have expected compile errors (Phase 2-3 scope).

## Architecture Change
**Before:** SocialCareContract accepted domain objects directly (no ACL)
**After:** SocialCareContract composed of 8 sub-contracts, all methods use DTOs (ACL boundary)

```
Backend changes → DTO layer absorbs → Domain models stable → UI stable
```

## File Tree (new)
```
bff/shared/lib/src/contract/
├── social_care_contract.dart          — composed interface
├── sub_contracts/
│   ├── health_contract.dart
│   ├── registry_contract.dart
│   ├── assessment_contract.dart
│   ├── care_contract.dart
│   ├── protection_contract.dart
│   ├── audit_contract.dart
│   ├── people_contract.dart           — People Context interaction
│   └── analytics_contract.dart        — Analysis BI interaction
└── dto/
    ├── shared/                        — PaginatedList, BackendError, StandardResponse
    ├── requests/{registry,assessment,care,protection,people}/
    └── responses/{registry,assessment,care,protection,audit,people,analytics}/
```

## Commit Message
```
feat(bff/shared): Phase 1 — typed DTOs, sub-contracts, and round-trip tests

- Create PaginatedList<T>, BackendError, StandardResponse<T> shared types
- Create 30 Response DTOs replacing Map<String, dynamic> anti-pattern
- Create 22 Request DTOs mirroring Swift backend RequestDTOs
- Rewrite SocialCareContract with 8 sub-contracts by bounded context
- Add People Context and Analysis BI contract interactions
- Establish ACL boundary: contract uses DTOs, not domain objects
- Add 176 serialization round-trip tests (all passing)
- Update FakeSocialCareBff for new contract signatures

Closes #47, #48, #49, #50, #59
Pipeline: maestro + 6 agents, 0 review rounds needed
```

## Next Steps (Phase 2-3)
- #51 — Implement lifecycle endpoints in API client
- #52 — Implement lookup governance in API client
- #53 — Implement pagination in listPatients and getAuditTrail
- #54 — Preserve BackendError structured in API client
- #55 — Migrate UseCases and Repositories to new contract

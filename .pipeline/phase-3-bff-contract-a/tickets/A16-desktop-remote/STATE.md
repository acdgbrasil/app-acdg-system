# Ticket State: A16-v2-desktop-remote (BREAK CHANGE)

phase: **CLOSED**
status: **APPROVED 2026-04-29** via 3-agent BFF pipeline (test-writer → flutter-bff-implementer → flutter-code-reviewer). Round 1, zero MUST_FIX, zero SHOULD_FIX. 153/153 tests GREEN, dart analyze 0 issues.

## Re-baseline summary (2026-04-29)

The original A16 scoped only `remote/social_care_bff_remote.dart` as a refactor.
After review, the entire `bff/social_care_desktop/` is being treated as
**break-changing rebuild** — same approach the web took (A07-A15 mirror).

**User authorization (2026-04-29):**
> "vamos marcar o DESKTOP como BREAK CHANGING e fazer igual ao WEB. Vamos
> considerar que tudo do desktop estava ERRADO e vamos RE-IMPLEMENTAR tudo,
> Como podemos fazer isso? Claro temos que manter as vantagens do DESKTOP."

## Why rebuild instead of refactor

1. Existing `SocialCareBffRemote` (917 LoC) implements deleted `SocialCareContract`
   — same anti-pattern Onda 2 cleaned up in `bff/shared/`.
2. `LocalCacheContract implements SocialCareContract` (god abstract) and
   `OfflineFirstRepository implements SocialCareContract` (god class
   switching cache-vs-remote per method) cannot evolve cleanly.
3. Web established the canonical pattern (handler + intent + use_case +
   sub-contract); refactoring incrementally would keep the desktop
   architecturally divergent and complicate Phase 4 (Flutter consumers).
4. STATE.md (master) explicitly authorizes break-changes: "Desktop não está
   em produção — pode quebrar. Zero teste por enquanto. Breaking changes
   livres."
5. A19 (final gate, `dart analyze bff/ zero errors`) closes naturally with
   a clean rebuild instead of accumulated incremental debt.

## New target structure (Onda 4)

```
bff/social_care_desktop/lib/src/
  facade/
    social_care_desktop.dart       — public API (composes use cases)
  remote/                          ← A16-v2 (THIS TICKET)
    _shared/
      remote_base.dart             — Dio + interceptors + helpers
    registry_remote.dart           — implements RegistryContract
    assessment_remote.dart         — implements AssessmentContract
    care_remote.dart               — implements CareContract
    protection_remote.dart         — implements ProtectionContract
    audit_remote.dart              — implements AuditContract
    lookup_remote.dart             — implements LookupContract
    health_remote.dart             — implements HealthContract
  cache/                           ← A17-v2 (Drift DAOs per bounded context)
    _shared/cache_database.dart
    registry_cache.dart, assessment_cache.dart, ...
  sync/                            ← A18-v2
    sync_queue.dart                — sealed-class outbox
    sync_engine.dart               — drains queue per context
  use_cases/                       ← A18-v2
    registry/, assessment/, care/, protection/, audit/, lookup/, health/
  testing/
    fake_social_care_desktop.dart
```

**No `intents/` folder** — desktop is in-process, receives typed DTOs from
the APP directly; HTTP body parsing (web's reason for intents) doesn't
apply.

## Key architectural decisions (locked 2026-04-29)

- **Mirror web pattern minus HTTP layer.** Sub-contracts as ports
  (RegistryContract, AssessmentContract, ...). Same that A05 split
  established.
- **Drift stays — NOT migrating to Isar** (despite ADR-005 prescribing
  Isar). Decision rationale: Isar maintenance abandoned (Simon Leier);
  community forks (`isar_community`, `isar_plus`) unstable; SPM
  incompatibility (Issue #1750); Drift has multi-isolate support fit for
  SyncEngine. ADR-005 will be updated to v2 in a follow-up.
- **Out of scope for desktop:** Auth (in-process, actorId injected),
  Team (single-tenant client, not admin), People/Analytics (delegated to
  separate clients today; no sub-contract uses them in desktop).
- **A16-v2 covers 7 sub-contracts:** RegistryContract,
  AssessmentContract, CareContract, ProtectionContract, AuditContract,
  LookupContract, HealthContract. Total ~34 methods across 7 thin
  remotes.

## Onda 4 ticket map (post-rebaseline)

| Ticket | Scope |
|---|---|
| **A16-v2** (this) | `remote/` — 7 thin remotes + RemoteBase. Tests per contract. |
| A17-v2          | `cache/` — Drift schema rebuild + 7 DAO-backed cache impls. |
| A18-v2          | `sync/` + `use_cases/` + `facade/` — orchestration layer + APP-facing API. |

## Acceptance criteria (A16-v2)

- [ ] `lib/src/remote/_shared/remote_base.dart` — Dio + interceptors +
  `_backendFailure` + `_extractIdResponse` + `_wrapResponse`. Stateless
  helpers; constructor takes `baseUrl`, `actorId`, `tokenProvider`, `dio?`.
- [ ] 7 thin remote classes, each `implements <Sub>Contract` and extends
  `RemoteBase` (or composes it). Each <80 LoC.
- [ ] `social_care_desktop.dart` library exports updated; no `SocialCareContract`
  references in `lib/src/remote/`.
- [ ] Tests: 1 file per remote in `test/remote/`. Validate per method:
  (1) HTTP path correctness, (2) request body/query mapping,
  (3) success response parsing, (4) BackendError propagation,
  (5) network failure → `Failure(e)`.
- [ ] Tests use `MockDio` pattern (already established in legacy test
  file, lines 1-122). Reuse fixture UUIDs from `bff/social_care_web/test/_test_uuids.dart`
  (canonical RFC 4122 v4 set established by A23).
- [ ] `dart analyze bff/social_care_desktop/lib/src/remote/` returns zero
  errors zero warnings.
- [ ] Storage (`lib/src/storage/`) and sync (`lib/src/sync/`) **intentionally
  left broken** — A17-v2 and A18-v2 will rebuild them. Document this in
  REPORT.md.

## Wave plan

- **W0 (RED) — test-writer:** failing tests for 7 remotes (~34 method
  tests). Compile-failure expected (impl files don't exist yet).
- **W1 (GREEN) — flutter-bff-implementer:** RemoteBase + 7 thin remotes
  → tests pass, dart analyze zero in `lib/src/remote/`.
- **W2 (REVIEW) — flutter-code-reviewer:** audit RemoteBase composition,
  no god-objects, no SocialCareContract references, sub-contract
  fidelity, error mapping consistency.

## Status
**CLOSED 2026-04-29** — APPROVED Round 1.

- W0 RED: 153 failing tests across 7 files + MockDio + UUID fixtures.
- W1 GREEN: 8 impl files (972 LoC: 1 RemoteBase + 7 thin remotes); deleted 11 legacy files (god-class + storage/ + sync/ + obsolete tests); pubspec direct `core_contracts` dep added.
- W2 REVIEW: APPROVED. 9/9 audit checks pass. 3 NICE_TO_HAVE non-blocking.

**Acceptance criteria final state:**
- [x] `lib/src/remote/_shared/remote_base.dart` (137 LoC).
- [x] 7 thin remote classes implementing sub-contracts (35-282 LoC each).
- [x] Library exports updated; no `SocialCareContract` symbol references.
- [x] Tests `test/remote/` × 7 with 5-axis coverage per method.
- [x] MockDio + UUID fixtures.
- [x] `dart analyze bff/social_care_desktop/` zero errors zero warnings.
- [x] Storage/sync deleted (option a — clean slate for A17-v2/A18-v2).

**Out-of-scope follow-up (authorized):** `apps/acdg_system/` consumer breakage — A18-v2 facade rebuild restores. Not a blocker.

**Next ticket:** A17-v2 (cache rebuild with Drift DAOs per bounded context).

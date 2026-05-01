# Ticket State: A15-web-team

## Current Phase
phase: **DONE** — V2 canon applied, test cheat fixed, reviewer APPROVED
agent: flutter-code-reviewer (last)
status: closed 2026-04-29 via 3-agent BFF pipeline (test-writer →
flutter-bff-implementer → flutter-code-reviewer). All 7 path-UUID
intents retrofitted to A23 V2 templates (4×A + 2×B + 1×C-P2), 2026-04-28
test cheat eliminated (`/team/people → 400 INVALID_GET_TEAM_MEMBER_PARAMS`),
zero MUST_FIX / zero SHOULD_FIX from review. Final BFF Web suite:
**1071 GREEN / 2 FAIL** (the 2 are pre-existing A21 cleanup).

## Pipeline run (2026-04-29)
- **Step 1 — test-writer:** 8 test files modified, +49 RED tests
  (5×Template A intent rejection × 4 + 7×Template B × 2 + 4×C-P2
  + 11 handler-layer rejections including REGRA #2 fix).
  Surfaced & resolved one ambiguity (RESUME-PLAN's illustrative
  `{roleId}` body shape vs current `{system, role}` — preserved
  current per DTO contract).
- **Step 2 — flutter-bff-implementer:** 8 production files modified
  (7 intents + team_handler). V2 canon applied verbatim:
  `.map(...)` (4×A), `(m, r).combineWith(...)` (2×B),
  `.flatMap((id) => _parseBody(id, body))` (1×C-P2). Handler emits
  `INVALID_<X>_PARAMS` for path failures (Template A/B), retains
  `INVALID_ASSIGN_ROLE_BODY` for assign-role per Template D.
  Zero `as Success<T>` cast. Zero new analyze issues. Lint custom
  clean. `check_no_sealed_cast.sh` clean for `bff/social_care_web/`.
- **Step 3 — flutter-code-reviewer:** APPROVED. Zero MUST_FIX, zero
  SHOULD_FIX. 2 NICE_TO_HAVE (out of A15 scope): `assign_role` test
  consistency mirror; future tidy of `GetPatientIntent` (A08) to use
  `.map(...)` form like the new 4 Template A intents (currently uses
  explicit switch — older A23 W1 form, less canonical than A15 W4.5).

## REGRA #2 verification (reviewer's words)
> "Textbook resolution of test cheating: previous shortcut named, root
> cause stated, real invariant tested, PII guarded."

The 2026-04-28 `topology hiding` group (4-segment-only) is fully
replaced by `UUID v4 path validation` group at `team_handler_test.dart:
574-846`. The headline test asserts `GET /team/people → 400
INVALID_GET_TEAM_MEMBER_PARAMS` directly. Inline comment block at lines
560-573 cites CLAUDE.md REGRA #2, dates the cheat (2026-04-28), and
explains the resolution.

## Final numbers
- 1071 GREEN / 2 FAIL pre-existing A21 (was 1026 at A23 W4 close)
- +45 net tests (test-writer's prediction was right; RESUME-PLAN's
  ~15 estimate was outdated — Template A grew from 1 sub-case to 5)
- 0 new `dart analyze` issues
- 0 sealed-class downcasts in production
- 0 violations from `acdg_lints/no_sealed_class_downcast`

## Why paused
A15 introduced a query-tolerant intent (`ListTeamIntent`) and a path-only
`GetTeamMember`. While writing the handler test, the user identified a
**route bleed problem in `/team/<id>`**: any 2-segment URL is captured as
a get-member call, including legacy URLs like `/team/people` (which
generates a useless backend round-trip and a sanitized 500).

We classified this as a **global invariant**, not a feature-local
concern: every path-only intent across A07-A14 has the same gap (no
UUID format validation on path params). Per the user's call:

> "validação de UUID em path params" é regra global, não escolha por
> feature. Se vou estabelecer o invariante, faço uma vez para o repo
> inteiro.

Strategy chosen: **B2** (global invariant). Tactic chosen: **T2** —
pause A15, do A23 first to establish the canon (helper + retrofit
A07-A14), then resume A15 using the established canon.

## Waves completed (preserved as-is until resume)
- [x] W0 — cleanup (3 legacy files deleted)
- [x] W1 — 9 Intents + 9 RED test files; 43 GREEN
- [x] W2 — 9 UseCases + 9 RED test files; 34 GREEN
- [x] W3 — TeamHandler rewrite + handler test; 25 GREEN (+9 endpoints)
- [/] W4 — wiring (TeamContract injected in AppRouter, buildTeamHandler
  factory, server.dart bootstrap with FakeTeamBff). **DONE structurally
  but does NOT yet apply UUID path validation** — that is the work that
  A23 unblocks.
- [ ] W5 — quality gate (deferred to resume)
- [ ] W6 — close STATE (deferred to resume)

## Outstanding work upon resume (post-A23)
1. Apply A23's `validateUuidPathParam` helper to the 9 Team intents:
   - `GetTeamMemberIntent.parseFromPath`
   - `DeactivateWorkerIntent.parseFromPath`
   - `ReactivateWorkerIntent.parseFromPath`
   - `ResetPasswordIntent.parseFromPath`
   - `AssignRoleIntent.parseFromPath` (memberId only — body parsing
     stays in `parseFromBody`)
   - `DeactivateRoleIntent.parseFromPath` (memberId + roleId)
   - `ReactivateRoleIntent.parseFromPath` (memberId + roleId)
2. Wire validation into `TeamHandler` route handlers (return 400
   `INVALID_*_PARAMS` on UUID failure).
3. Add UUID validation tests to handler + intent test files.
4. Restore the test that exposed the bleed:
   `GET /team/people → 400 INVALID_GET_TEAM_MEMBER_PARAMS`
   (currently testing `/team/people/*` 4-segment routes only —
   per REGRA #2 in CLAUDE.md, this is documented test cheat from
   2026-04-28 that A23 + A15 resume will fix).
5. Run W5 quality gate.
6. Run W6 close.

## Numbers at pause
- 946 tests passing total in BFF Web (was 844 at A14 close; +102 from A15)
- 2 pre-existing legacy test failures (health_handler + social_care_api_client) — A21
- 0 new analyzer issues introduced by A15
- 0 regressions in A07-A14

## DEBT — test cheat documented for resume
`test/handlers/team_handler_test.dart` group `topology hiding` currently
tests only 4-segment URLs (`/team/people/by-cpf/<cpf>`,
`/team/people/<id>/roles`). The original intent was to test
`/team/people` (2 segs) as a 404, but that URL is captured by
`/team/<id>` and returns 500. **This is exactly the route bleed A23
will fix**. On A15 resume, replace the 4-segment-only group with
`expect(GET /team/people → 400 INVALID_GET_TEAM_MEMBER_PARAMS)`.

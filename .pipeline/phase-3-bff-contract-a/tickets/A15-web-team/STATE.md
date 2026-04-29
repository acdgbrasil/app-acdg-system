# Ticket State: A15-web-team

## Current Phase
phase: paused — blocked by A23
agent: implementer
status: paused at Wave 4.5 — wiring done; awaits A23 (UUID path validation canon) before adding UUID validation to the 9 Team intents

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

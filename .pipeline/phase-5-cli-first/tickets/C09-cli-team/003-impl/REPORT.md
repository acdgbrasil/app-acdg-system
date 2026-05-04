# C09 — W1 (GREEN) Report

**Agent:** flutter-bff-implementer
**Wave:** 1 — GREEN
**Date:** 2026-05-04
**Status:** 658 / 658 CLI tests GREEN (was 565; +93). 0 analyze. AOT compiles. **Onda 4 fecha quando este ticket fechar.**

## Files created (10)

10 team commands under `apps/cli/lib/src/commands/`:
- `team_list_command.dart` — GET + queryParameters
- `team_register_command.dart` — POST + StandardIdResponse + saga 5xx UX hint + ISO8601 validation
- `team_get_command.dart` — GET + envelope `data` unwrap
- `team_deactivate_command.dart` — PUT path-only
- `team_reactivate_command.dart` — PUT path-only
- `team_reset_password_command.dart` — **POST** (not PUT — Zitadel side effect)
- `team_role_command.dart` — sub-parent (3 leaves)
- `team_role_assign_command.dart` — POST + StandardIdResponse (CLI `--role-id` → DTO `role`)
- `team_role_deactivate_command.dart` — PUT path-only (2 positionals)
- `team_role_reactivate_command.dart` — PUT path-only (2 positionals)

## Files modified (3)

- `apps/cli/lib/src/commands/team_command.dart` — replaced C01 stub with parent.
- `apps/cli/lib/src/cli_runner.dart` — `_buildTeamCommand` factory.
- `apps/cli/lib/cli.dart` — barrel exports.

## Files NOT modified

- 0 `BffClient` changes — all 5 verbs + queryParameters existed from C04+C08.
- 0 BFF impl changes.
- 0 test files (W0 territory).

## Public API delta

```dart
TeamCommand({list, register, get, deactivate, reactivate, resetPassword, role})
TeamRoleCommand({assign, deactivate, reactivate})  // sub-parent
+ 9 leaf classes
```

## Wire format

| CLI verb | HTTP | Path | Body |
|---|---|---|---|
| `team list` | GET | `/team` | none, queryParameters omit-when-absent |
| `team register` | POST | `/team` | `{fullName, birthDate, email, cpf?, initialPassword?}` |
| `team get` | GET | `/team/<id>` | none |
| `team deactivate` | PUT | `/team/<id>/deactivate` | none |
| `team reactivate` | PUT | `/team/<id>/reactivate` | none |
| `team reset-password` | **POST** | `/team/<id>/reset-password` | none |
| `team role assign` | POST | `/team/<id>/roles` | `{system, role}` (CLI `--role-id` → DTO `role`) |
| `team role deactivate` | PUT | `/team/<id>/roles/<roleId>/deactivate` | none |
| `team role reactivate` | PUT | `/team/<id>/roles/<roleId>/reactivate` | none |

## Decisions taken

1. **CLI flag `--role-id` → wire field `role`** (DTO-as-canon). Tests pin `body['role']` present + `body.containsKey('role-id') == false`.
2. **`team reset-password` is POST.** "Create reset request" semantics (Zitadel side effect).
3. **ISO8601 validation on `--birth-date`.** Mirror C03 `patient admit`.
4. **5xx saga UX hint on stderr** for `team register`. CLI does NOT enforce rollback (BFF responsibility); just surfaces saga semantics.
5. **Sub-parent two-level nesting** mirrors C08.
6. **`team list` queryParameters omit-when-absent.**
7. **`--active` no client-side validation** — BFF rejects.
8. **Two-positional verbs** validate `rest.length < 2` with combined usage message.
9. **`decodeStandardIdResponse` reused** — 2 new call-sites. Helper now at **7 total call-sites** across phases C06-C09.
10. **Print verbs extract `data` from envelope** — same as C03+C08.

## Test counts

| Bucket | Before C09 | After C09 |
|--------|-----------:|----------:|
| `apps/cli/` total | 565 | **658** |
| Δ | — | **+93** |

Math: 97 new C09 tests − 4 C01 stub retired = +93 net.

## Quality gates

- `dart analyze apps/cli/` → 0 issues.
- `dart format` → clean.
- `dart compile exe` → succeeded.
- `acdg team --help` → 7 entries.
- `acdg team role --help` → 3 sub-leaves.
- C02-C08 GREEN.

## Open questions

(none) — Onda 4 fecha quando ticket close.

# C09 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** RED CONFIRMED. 101 analyzer errors. 97 new tests across 11 files. C02-C08 GREEN (434 passes).

## 1. Test files

11 files (1 replaced + 10 new):

| Path | Tests |
|------|------:|
| `team_command_test.dart` (replaced) | 6 |
| `team_list_command_test.dart` | 11 |
| `team_register_command_test.dart` | 13 |
| `team_get_command_test.dart` | 9 |
| `team_deactivate_command_test.dart` | 8 |
| `team_reactivate_command_test.dart` | 8 |
| `team_reset_password_command_test.dart` | 8 |
| `team_role_command_test.dart` (sub-parent) | 5 |
| `team_role_assign_command_test.dart` | 11 |
| `team_role_deactivate_command_test.dart` | 9 |
| `team_role_reactivate_command_test.dart` | 9 |

**97 new tests.**

## 2. Public surface declared

NESTED CLI shape (mirrors C08 sub-parent):
```
acdg team
├── list [--role=X] [--active=true|false] [--search=Y]
├── register --full-name --birth-date --email [--cpf] [--initial-password]
├── get <member-id>
├── deactivate <member-id>
├── reactivate <member-id>
├── reset-password <member-id>
└── role                                    (sub-parent)
    ├── assign <member-id> --system --role-id
    ├── deactivate <member-id> <role-id>
    └── reactivate <member-id> <role-id>
```

10 new Command classes. **No new BffClient verbs** — all 5 (GET/POST/PUT/DELETE/PATCH) exist from C04+C08.

## 3. Wire format — DTO-as-canon (8th application)

| CLI verb | HTTP | Path | Body | Source |
|---|---|---|---|---|
| `team list` | GET | `/team` | none, queryParameters: `{role?, active?, search?}` | `list_team_intent.dart:43-82` |
| `team register` | POST | `/team` | `{fullName, birthDate, email, cpf?, initialPassword?}` | `register_worker_intent.dart:36-73`; DTO `register_person_with_login_request.dart:8-14` |
| `team get` | GET | `/team/<id>` | none | `get_team_member_intent.dart:27-31` |
| `team deactivate` | PUT | `/team/<id>/deactivate` | none | `deactivate_worker_intent.dart:22-26` |
| `team reactivate` | PUT | `/team/<id>/reactivate` | none | `reactivate_worker_intent.dart:22-26` |
| `team reset-password` | **POST** (not PUT) | `/team/<id>/reset-password` | none | `reset_password_intent.dart:23-27`; handler `team_handler.dart:90` |
| `team role assign` | POST | `/team/<id>/roles` | `{system, role}` | `assign_role_intent.dart:34-72`; DTO `assign_role_request.dart:7-13` |
| `team role deactivate` | PUT | `/team/<id>/roles/<roleId>/deactivate` | none (path-only, 2 params) | `deactivate_role_intent.dart:25-35` |
| `team role reactivate` | PUT | `/team/<id>/roles/<roleId>/reactivate` | none (path-only, 2 params) | `reactivate_role_intent.dart:25-35` |

**CLI flag → DTO field translation pins:**
- `--full-name` → `fullName`
- `--birth-date` → `birthDate`
- `--email` → `email`
- `--cpf` → `cpf` (optional, omit when null)
- `--initial-password` → `initialPassword` (optional)
- `--system` → `system`
- **`--role-id` → `role`** (NOT `roleId`!) — DTO `AssignRoleRequest:8`

## 4. Decisions taken

- **D1: Sub-parent `team role` shape** mirrors C08 `lookup request`.
- **D2: DTO-as-canon for `team register`.** Ticket flags `--first-name`/`--role` NOT supported. DTO has `fullName`/`birthDate`/`email` (req) + `cpf`/`initialPassword` (opt). Initial role assignment becomes TWO-step UX: register → role assign.
- **D3: `team reset-password` is POST (not PUT).** Deliberate divergence pinned in `team_handler.dart:92` — kicks off out-of-band Zitadel side effect, semantics are "create reset request".
- **D4: `team list` queryParameters omits absent flags.** Tests pin `qp.containsKey('role') == false` when no flag.
- **D5: `--active` is string flag with literal `true|false` semantics.** No client-side validation; BFF rejects.
- **D6: CLI flag `--role-id` → wire field `role`.** DTO `AssignRoleRequest:8` is `{system, role}`.
- **D7: 5xx on saga endpoints surfaced via stderr.** CLI does NOT enforce rollback (BFF responsibility).
- **D8: Two-positional path-only verbs** — `team role deactivate|reactivate` take `<member-id> <role-id>`.

## 5. Open questions for W1

1. `--initial-role` CLI sugar for register: don't expose; user does two commands.
2. `--active` argparser declaration: `addOption` (lazy) vs `addOption(allowed: [...])` (eager). Recommend lazy.
3. `team get` decoding: raw `Map<String, Object?>` + formatter (mirrors C03 `patient get`).
4. Stub fallback for sub-parent: `TeamCommand()` MUST register real `TeamRoleCommand()` (not leaf placeholder).

## 6. RED state confirmed

- 101 errors in 11 affected files.
- 0 BffClient errors (all 5 verbs exist).
- C02-C08 isolated: 434 GREEN, 0 regressions.

## 7. No impl files modified

Only 11 test paths created/edited. `apps/cli/lib/**` untouched.

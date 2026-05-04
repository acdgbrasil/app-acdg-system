# C04 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** All 4 family-command test files + replaced parent + extended `bff_client_test.dart` are RED at compile time. `dart analyze apps/cli/test/` reports **61 errors, 0 warnings, 0 info**. C03 patient + C02 auth suites still GREEN (93/93).

## 1. Test files

### Replaced (C01 stub → C04 parent)
- `apps/cli/test/commands/family_command_test.dart` — 5 tests

### New (flat layout)
| Path | Tests | Coverage |
|------|------:|----------|
| `family_add_command_test.dart` | 11 | POST `/patients/<id>/family-members` body shape (DTO-camelCase) + flag defaults + missing positional/--relationship/--birth-date/--pr-relationship-id + 422/saga-5xx/401 |
| `family_remove_command_test.dart` | 9 | DELETE `/patients/<id>/family-members/<memberId>` + no-body invariant + 204 confirmation + missing positional/--member-id + 404/401/network |
| `family_assign_caregiver_command_test.dart` | 8 | PUT `/patients/<id>/primary-caregiver` body `{memberPersonId}` + missing positional/--member-id + 422/401/network |
| `family_update_identity_command_test.dart` | 10 | PUT `/patients/<id>/social-identity` body `{typeId, description?}` + dropNulls on description + missing positional/--type-id/no-fields + 422/401/network |

**Subtotal: 38 family-command tests.**

### Extended — `BffClient.put<T>` + `delete<T>` in `bff_client_test.dart`
| Group | Tests |
|-------|------:|
| `BffClient — put<T> verb (C04)` | 9 |
| `BffClient — delete<T> verb (C04)` | 10 |

**Total new C04 surface: 57 tests, 6 files affected.**

## 2. Public surface declared

### 2.1 `BffClient.put<T>`
```dart
Future<Result<T>> put<T>(
  String path, {
  Object? body,
  T Function(Object? data)? decode,
});
```
Same contract as `post<T>`: 401 → refresh once → retry once with same body, etc.

### 2.2 `BffClient.delete<T>`
```dart
Future<Result<T>> delete<T>(
  String path, {
  T Function(Object? data)? decode,
});
```
Same contract; **no `body` param** on public API.

### 2.3 `FamilyCommand` parent + 4 subcommand classes
Same pattern as C03 `PatientCommand`. 4 names in `subcommands.keys`: `add`, `remove`, `assign-caregiver`, `update-identity`.

## 3. Wire-format confirmations (DTO-as-canon — lesson from C03 W2 M1)

Verified against `apps/social_care_bff/web/lib/src/intents/{add_family_member,remove_family_member,assign_primary_caregiver,update_social_identity}_intent.dart`.

### 3.1 `family add` body
| Key | Required? | Notes |
|-----|-----------|-------|
| `relationship` | YES | Intent line 72 |
| `birthDate` | YES | Intent line 73 |
| `prRelationshipId` | YES | Intent line 74 |
| `memberPersonId` | optional | Defaults `''` |
| `isResiding`/`isCaregiver`/`hasDisability` | optional | Default `false` |
| `requiredDocuments` | optional | Default `[]` |
| `cpf` / `fullName` | optional | **Top-level envelope, NOT in `request`** — intent lines 94-95 forward to People Context |

### 3.2 `family remove` — no body
Two route params: `<id>` + `<memberId>`. Both UUID v4.

### 3.3 `family assign-caregiver` body
| Key | Notes |
|-----|-------|
| `memberPersonId` | YES — Intent line 39 |

CLI flag `--member-id` → wire key `memberPersonId` (UX-symmetric with `family remove`).

### 3.4 `family update-identity` body
| Key | Notes |
|-----|-------|
| `typeId` | YES |
| `description` | optional |

CLI flags: `--type-id` + `--description`. dropNulls when `--description` absent.

## 4. Decisions taken

1. Real `BffClient` + fake `HttpClientAdapter` (BffClient is `final class`).
2. Flat test layout matches C03.
3. `FamilyCommand()` placeholder fallback when no collaborators.
4. DTO-as-canon body shapes.
5. `cpf` + `fullName` top-level envelope (NOT nested).
6. Saga UX server-driven; CLI just surfaces stderr.
7. `--member-id` flag → `memberPersonId` wire key for assign-caregiver.
8. **MAJOR ticket-vs-DTO divergence on `update-identity`**: ticket says `--gender --pronoun`; DTO is `{typeId, description?}`. CLI follows DTO. "At least one must be set" collapses to "`--type-id` REQUIRED".
9. dropNulls for optional `description`.
10. DELETE has no `body:` parameter on public API.
11. `formatter` field wired even when verbs return 204 (mirrors C03 — debt for C10).

## 5. Open questions for W1

1. `--member-id` vs `--member-person-id` flag name on assign-caregiver.
2. Saga 5xx UX hint copy.
3. Extend `_attempt`/`_refreshAndRetry` (C03) to PUT + DELETE. Natural: single `_attemptOnce(method, path, body?)`.
4. `cli_runner.dart` wiring via `_buildFamilyCommand` factory.
5. `--required-document` multi-option coverage (currently permissive).
6. `--full-name` vs ticket-prose `--first-name` on family add — tests use `--full-name` matching BFF wire key.
7. Golden tests deferred to C10.

## 6. RED state confirmed

```
$ dart analyze apps/cli/test/
61 issues found (0 warnings, 0 info, 61 errors):
  4× Target URI doesn't exist (family_<verb>_command.dart)
  38× Function 'Family<Verb>Command' isn't defined
  9× Method 'put' isn't defined for BffClient
  10× Method 'delete' isn't defined for BffClient
```

C03 + C02 suites GREEN: `dart test apps/cli/test/commands/patient_*_test.dart apps/cli/test/commands/auth_*_test.dart` → `+93: All tests passed!`

## 7. No impl files modified

Zero changes under `apps/cli/lib/`, `apps/cli/bin/`, or `apps/social_care_bff/`. No new pubspec deps.

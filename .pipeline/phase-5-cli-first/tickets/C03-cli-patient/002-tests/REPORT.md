# C03 — W0 (RED) Report

**Agent:** test-writer
**Wave:** 0 — RED
**Date:** 2026-05-04
**Status:** All 9 patient-command test files + extended `bff_client_test.dart` are RED at compile time. `dart analyze apps/cli/test/` reports **81 errors, 0 warnings, 0 info** — every error is one of three expected categories. C02 auth subcommand suites still GREEN (24/24).

## 1. Test files

### Replaced (C01 stub → C03 parent contract)

| Path | Tests |
|------|------:|
| `apps/cli/test/commands/patient_command_test.dart` | 5 |

Mirrors C02's `auth_command_test.dart` migration: parent registers 8 subcommands, returns non-zero (EX_USAGE) when run without a verb.

### New — flat layout (matches C02)

| Path | Tests | Coverage |
|------|------:|----------|
| `patient_list_command_test.dart` | 9 | basics + GET path with all 4 query params + empty-args + nextCursor surfacing + 503/401/500 failures |
| `patient_get_command_test.dart` | 6 | basics + GET `/patients/<id>` + formatter wiring + missing-positional + 404/401 |
| `patient_audit_command_test.dart` | 7 | basics + GET `/patients/<id>/audit-trail` (no filter / with `--event-type`) + missing-positional + transport failure |
| `patient_register_command_test.dart` | 10 | basics + flag-based body assembly (POST `/patients`) + `--from-yaml` + mutually-exclusive guard + unreadable file + 422/401 |
| `patient_admit_command_test.dart` | 9 | basics + body shape + missing-id/reason/admitted-at + ISO8601 validation + 409/401 |
| `patient_discharge_command_test.dart` | 8 | basics + body shape + omits `notes` when absent + missing-id/reason + 422/401 |
| `patient_readmit_command_test.dart` | 7 | basics + body with notes + empty body + missing-id + 409 + transport failure |
| `patient_withdraw_command_test.dart` | 8 | basics + body shape + omits `notes` when absent + missing-id/reason + 422/401 |

**Subtotal: 69 patient-command tests.**

### Extended — `BffClient.post<T>` verb section appended to `bff_client_test.dart`

9 new tests in group `BffClient — post<T> verb (C03)`. C02-additive section untouched. Pre-C02 fixtures untouched.

POST tests cover: 200+decode→Success / 204 no decode→Success / JSON serialization on the wire / Bearer attached on POST / 401→refresh→retry-once with same body / 401→RefreshTokenInvalid→clear store + AuthRequiredError / 500→ServerError / 422 (NOT 401)→ServerError, NO refresh, NO retry / Network failure→NetworkError.

**Total new C03 test surface: 78 tests, 9 files affected.**

## 2. Public surface declared (W1 must build)

### 2.1 — `BffClient.post<T>` extension

```dart
Future<Result<T>> post<T>(
  String path, {
  Object? body,
  T Function(Object? data)? decode,
});
```

Behavior contract (mirrors `get<T>`):
- Body serialized as JSON (Map → `application/json`).
- 401 → refresh once → retry once with the new bearer; retry MUST resend the original body.
- 4xx (other than 401) → `Failure(ServerError(status, msg))`. NO retry.
- 5xx → `Failure(ServerError)`.
- Network/transport → `Failure(NetworkError)`.
- 200/201 with decode → `Success(decode(parsed))`.
- 200/201/204 without decode → `Success(raw as T)` (raw is null on 204).

### 2.2 — `PatientCommand` parent (replaces C01 stub)

Falls back to schema-only placeholder subcommands when ctor is called with no collaborators (mirrors `AuthCommand._PlaceholderCommand`). 8 names MUST appear in `cmd.subcommands.keys`.

### 2.3 — Subcommand class signatures

Common shape:
```dart
final class Patient<Verb>Command extends Command<int> {
  Patient<Verb>Command({
    required this.bffClient,
    required this.formatter,
    this.stdout,
    this.stderr,
  });
}
```

`PatientRegisterCommand` additionally takes `required Future<String> Function(String path) fileReader` for `--from-yaml`.

### 2.4 — Exit code matrix

| Bucket | Code |
|--------|-----:|
| Success | 0 |
| Generic server / 5xx | 1 |
| AuthRequiredError | 2 |
| Network failure | 3 |
| Bad input / `args.UsageException` | 64 (EX_USAGE) |

### 2.5 — BFF route paths

| Verb | Path |
|------|------|
| `list` | GET `/patients?search=&status=&cursor=&limit=` |
| `get` | GET `/patients/<id>` |
| `audit` | GET `/patients/<id>/audit-trail?event_type=` |
| `register` | POST `/patients` |
| `admit` | POST `/patients/<id>/admit` |
| `discharge` | POST `/patients/<id>/discharge` |
| `readmit` | POST `/patients/<id>/readmit` |
| `withdraw` | POST `/patients/<id>/withdraw` |

C03 ticket prose says `/api/patients` but BFF web router mounts `/patients` directly — tests use `/patients`.

## 3. Decisions taken

1. **Real `BffClient` + fake `HttpClientAdapter`, not a fake `BffClient`.** `BffClient` is `final class` (per C02). Tests wire real `BffClient` pointing to a `Dio` whose `httpClientAdapter` returns canned responses + captures `RequestOptions`.
2. **Flat test layout** matches C02.
3. **`PatientCommand()` no-collaborator path** uses placeholder trick (W1 may pick a different shape).
4. **Body shape uses contract DTO field names directly.** Tests assert `body['personId']`, `body['initialDiagnoses']`, etc.
5. **`--admitted-at` ISO8601 validation in CLI, not server.** Invalid timestamps fail fast (no HTTP round-trip).
6. **`--from-yaml` reader is injected** — production wires `(p) => File(p).readAsString()`.
7. **Default formatter contract** = "the formatter was called". `_CapturingFormatter` returns `'[CAPTURED]\n'`; exact rendering tested by formatter unit suites.

## 4. Open questions / decisions deferred to W1

### 4.1 — Contract divergences (ticket prose vs DTO)

| Verb | Ticket says | DTO accepts | Test follows |
|------|-------------|-------------|--------------|
| `discharge` | `--reason --discharged-at=ISO8601` | `{reason, notes?}` (no timestamp) | DTO — no `--discharged-at` |
| `readmit` | `[--reason=X]` | `{notes?}` (no reason) | DTO — `--notes` only |
| `withdraw` | `[--reason=X]` (optional) | `{reason, notes?}` (reason REQUIRED) | DTO — `--reason` required |

W1 stance: implement the DTO contract; if user pushback comes later, update DTO + regenerate tests.

### 4.2 — Pagination cursor surfacing format
Tests permissive (stdout OR stderr). Suggestion: emit on stderr with prefix `Next page cursor: <value>`.

### 4.3 — `event-type` query param casing
Wire is `event_type` (BFF reads `request.url.queryParameters['event_type']`). Test stays permissive but W1 should send snake_case.

### 4.4 — `BffClient` 401 retry guard for POST
W1 must extend `_Attempt<T>` to POST. Natural impl: factor `_attemptGet`/`_attemptPost` with a single `_refreshAndRetry` helper.

### 4.5 — `cli_runner.dart` wiring
8 subcommands wired via `_buildPatientCommand` factory similar to C02's `_buildAuthCommand`. W1 work; no W0 test asserts runner-level wiring.

### 4.6 — Golden tests deferred to C10
Existing formatter suites already cover output. Layering a second copy at command level duplicates without adding signal.

### 4.7 — `package:yaml` dep already present
`apps/cli/pubspec.yaml` already lists `yaml: ^3.1.2`. No new pubspec entry.

## 5. RED state confirmation

```
$ dart analyze apps/cli/test/
81 issues found.
  - 0 warnings, 0 info
  - 81 errors in three categories:
    1. Target of URI doesn't exist: 'package:cli/src/commands/patient_<verb>_command.dart'  (×8)
    2. The function 'Patient<Verb>Command' isn't defined  (×64)
    3. The method 'post' isn't defined for the type 'BffClient'  (×9 in bff_client_test.dart C03 section)
```

C02 auth subcommand suites stay GREEN in isolation:
```
$ dart test apps/cli/test/commands/auth_*_test.dart
00:00 +24: All tests passed!
```

## 6. No implementation files modified

W0 confirmed read-only on `apps/cli/lib/`. Only edits:
- `patient_command_test.dart` REPLACED (C01 stub → C03 parent)
- 8 new `patient_<verb>_command_test.dart`
- `bff_client_test.dart` APPENDED with `post<T>` group

Zero changes under `apps/cli/lib/`, `apps/cli/bin/`, `apps/social_care_bff/`, or any other package.

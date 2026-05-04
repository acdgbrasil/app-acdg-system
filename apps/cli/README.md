# ACDG CLI

Command-line interface for the ACDG social care system. Operate the BFF from
shell scripts, CI jobs, and interactive terminals — same protocol the web UI
uses, no browser required.

> **Phase 5 status (2026-05-04):** all 35+ commands operational, OIDC PKCE
> Loopback authentication wired against Zitadel self-hosted, 704 tests GREEN.

---

## Install

### From source (recommended for now)

```bash
# Resolve dependencies
cd apps/cli && dart pub get

# Compile to a native binary
dart compile exe bin/acdg.dart -o ~/.local/bin/acdg

# Verify
acdg --help
```

The binary is statically-linked Dart AOT — no runtime dependencies. Place it
anywhere on your `$PATH`.

### Future (post-1.0)

GitHub release artifacts will provide pre-built binaries for macOS (arm64/x64),
Linux (x64), and Windows (x64). Tracked under C11.5 follow-up.

---

## Quickstart

```bash
# 1. Authenticate (opens browser via OIDC PKCE Loopback)
acdg auth login

# 2. Verify session
acdg auth status

# 3. Read patients
acdg patient list --limit=10

# 4. Register a new patient (composite endpoint)
acdg patient register --from-yaml=path/to/patient.yaml

# 5. Get full detail
acdg patient get <patient-id>

# 6. Logout when done
acdg auth logout
```

---

## Commands

The CLI mirrors the BFF's Contract A surface — 9 namespaces, 35+ verbs.

### Authentication

| Command | Description |
|---|---|
| `acdg auth login` | OIDC PKCE Loopback flow (opens browser) |
| `acdg auth status` | Show current session, roles, expiration |
| `acdg auth logout` | Revoke refresh token + clear local credentials |
| `acdg auth refresh` | Force manual token refresh |

### Patient registry

| Command | Description |
|---|---|
| `acdg patient list [--search] [--status] [--cursor] [--limit]` | List patients (paginated) |
| `acdg patient get <patient-id>` | Full patient detail |
| `acdg patient audit <patient-id> [--event-type]` | Audit trail |
| `acdg patient register {--from-yaml \| --person-id ...}` | Register new patient (composite) |
| `acdg patient admit <patient-id> --reason --admitted-at` | Admit |
| `acdg patient discharge <patient-id> --reason [--notes]` | Discharge |
| `acdg patient readmit <patient-id> [--notes]` | Readmit |
| `acdg patient withdraw <patient-id> --reason [--notes]` | Withdraw |

### Family

| Command | Description |
|---|---|
| `acdg family add <patient-id> --relationship --birth-date --pr-relationship-id [...]` | Add family member |
| `acdg family remove <patient-id> --member-id` | Remove family member |
| `acdg family assign-caregiver <patient-id> --member-id` | Assign primary caregiver |
| `acdg family update-identity <patient-id> --type-id [--description]` | Update social identity |

### Assessment (7 fichas)

| Command | Description |
|---|---|
| `acdg assessment housing <patient-id> {flags \| --from-yaml}` | Housing condition |
| `acdg assessment socioeconomic <patient-id> {flags \| --from-yaml}` | Socioeconomic situation |
| `acdg assessment work-income <patient-id> {flags \| --from-yaml}` | Work and income |
| `acdg assessment education <patient-id> {flags \| --from-yaml}` | Educational status |
| `acdg assessment health <patient-id> {flags \| --from-yaml}` | Health status |
| `acdg assessment community-support <patient-id> {flags \| --from-yaml}` | Community support |
| `acdg assessment social-health-summary <patient-id> {flags \| --from-yaml}` | Social health summary |

### Care

| Command | Description |
|---|---|
| `acdg care appointment <patient-id> --professional-id [...]` | Register appointment (returns generated ID) |
| `acdg care intake <patient-id> --ingress-type-id --service-reason [...]` | Update intake info |

### Protection

| Command | Description |
|---|---|
| `acdg protection violation <patient-id> --victim-id --violation-type --description-of-fact [...]` | Report rights violation (returns ID) |
| `acdg protection referral <patient-id> --referred-person-id --destination-service --reason [...]` | Create referral (returns ID) |
| `acdg protection placement-history <patient-id> --from-yaml` | Update placement history (YAML-only) |

### Lookup tables

| Command | Description |
|---|---|
| `acdg lookup get <table>` | Fetch one lookup table |
| `acdg lookup batch <a,b,c,...>` | Fetch up to 20 tables in one round trip |
| `acdg lookup create <table> --code --label` | Create new item (admin) |
| `acdg lookup update <table> <id> [--code] [--label]` | Update item (admin) |
| `acdg lookup toggle <table> <id> --active=true\|false` | Flip active flag (admin, PATCH) |
| `acdg lookup request list` | List governance requests |
| `acdg lookup request create <table> --code --label [--justificativa]` | Submit governance proposal |
| `acdg lookup request approve <id>` | Approve request (admin) |
| `acdg lookup request reject <id> [--reason]` | Reject request (admin) |

### Team

| Command | Description |
|---|---|
| `acdg team list [--role] [--active] [--search]` | List team members |
| `acdg team register --full-name --birth-date --email [--cpf] [--initial-password]` | Register worker (returns ID) |
| `acdg team get <member-id>` | Member detail |
| `acdg team deactivate <member-id>` | Deactivate worker |
| `acdg team reactivate <member-id>` | Reactivate worker |
| `acdg team reset-password <member-id>` | Trigger password reset (Zitadel) |
| `acdg team role assign <member-id> --system --role-id` | Assign role (returns ID) |
| `acdg team role deactivate <member-id> <role-id>` | Deactivate role |
| `acdg team role reactivate <member-id> <role-id>` | Reactivate role |

### Health

| Command | Description |
|---|---|
| `acdg health` | Probe BFF + dependencies |

Use `acdg <command> --help` for detailed flag info on any subcommand.

---

## Output formats

The CLI auto-detects format based on the output stream:

* `--output=table` — column-aligned ASCII (default in interactive terminals).
* `--output=json` — machine-readable JSON (default when piped).
* `--output=yaml` — human-readable YAML.
* `--output=auto` — detect via `stdout.hasTerminal`.

Examples:

```bash
# Pipeline-friendly:
acdg patient list | jq '.data[].id'

# Eyeball-friendly:
acdg patient list --output=table

# Config-friendly:
acdg lookup get dominio_genero --output=yaml > genero.yaml
```

---

## Environment variables

The OIDC client config is committed (constants in
[`lib/src/config/oidc_config.dart`](lib/src/config/oidc_config.dart)) — no
runtime config needed for auth.

The only runtime override is the BFF endpoint:

| Variable | Default | Purpose |
|---|---|---|
| `ACDG_BFF_URL` | `http://localhost:8081` | BFF Web base URL (compile-time `--dart-define`) |

Or use the `--bff` flag at runtime:

```bash
acdg patient list --bff=https://social-care-hml.acdgbrasil.com.br
```

---

## Configuration paths

| Path | Purpose |
|---|---|
| `~/.config/acdg/credentials` | OIDC session (chmod 600). Created by `acdg auth login`. |
| `$XDG_CONFIG_HOME/acdg/credentials` | Alternative path when `XDG_CONFIG_HOME` is set. |

---

## Exit codes

The CLI uses standard `sysexits(3)` codes plus a small set of CLI-specific
buckets:

| Code | Meaning |
|-----:|---|
| 0 | Success |
| 1 | Server error (4xx/5xx other than 401) |
| 2 | Authentication required (no session, expired, or refresh-rotation detected) |
| 3 | Network failure (connection refused, timeout, TLS error) |
| 4 | Malformed id_token (auth login only) |
| 7 | Refresh token invalidated by Zitadel (run `acdg auth login` again) |
| 64 | Usage error (missing arg, invalid flag) — `EX_USAGE` |

Use these in scripts:

```bash
acdg patient list || case $? in
  2) echo "Session expired, re-authenticating..."; acdg auth login ;;
  3) echo "Network down, retrying in 60s..."; sleep 60 ;;
  *) echo "Unrecoverable error"; exit 1 ;;
esac
```

---

## Authentication

The CLI authenticates against Zitadel via OIDC PKCE + RFC 8252 Loopback
(`gh`/`gcloud` style):

1. `acdg auth login` opens your default browser to the Zitadel login page.
2. After authentication, the browser redirects to `http://127.0.0.1:<port>/callback`.
3. The CLI captures the authorization code, exchanges it for tokens.
4. Session persisted to `~/.config/acdg/credentials` (chmod 600).
5. Subsequent commands attach `Authorization: Bearer <access_token>` automatically.

Refresh is handled transparently when access tokens expire (within the
12-hour TTL). When the refresh token itself expires or is rotated by
Zitadel (RefreshTokenInvalid), the CLI exits with code 7 — re-run
`acdg auth login`.

The Native App provisioned in Zitadel is `ACDG CLI`
(`client_id=371410163745226755`); see
[`handbook/spikes/OICD_AUTH_SPIKE.md`](../../handbook/spikes/OICD_AUTH_SPIKE.md)
for the full setup history.

---

## Troubleshooting

### `acdg auth login` doesn't open the browser

The CLI prints the authorization URL to stdout before opening the browser.
If `open`/`xdg-open`/`rundll32` fails (SSH session, container, etc.), copy
the URL manually into a browser. After login, the loopback listener still
captures the callback — the CLI will continue once you complete the flow.

### Session expired after 12 hours

That's the access token TTL. Either:

```bash
acdg auth refresh    # if refresh token still valid (up to days)
acdg auth login      # if both expired
```

### `Refresh token rotated or revoked` (exit 7)

Zitadel detected the refresh token was either replayed (you used the same
session on another machine) or expired. Run `acdg auth login` to
re-authenticate.

### `Network error: Connection refused`

Verify the BFF is reachable:

```bash
curl http://localhost:8081/health
```

Or override with `--bff=<url>`.

### Output is JSON when I expect a table

`auto` format defaults to JSON when stdout is not a TTY (e.g., when piped).
Force the format explicitly:

```bash
acdg patient list --output=table
```

### `INVALID_*_BODY` error from BFF

The CLI sends what you typed; the BFF validated it and rejected. The error
message contains the specific field. Check `acdg <verb> --help` for the
canonical flag names — they translate to the BFF wire format
(e.g., `--full-name` → `fullName`, `--role-id` → `role`).

---

## Architecture

* **Dart AOT** — single static binary, no runtime dependencies.
* **OIDC PKCE Loopback** — RFC 8252 §7.3 native app pattern.
* **`Result<T>`** end-to-end — no exceptions cross application/command layers.
* **Sub-contracts** — each BFF capability area (registry, audit, lookup, etc.)
  is a separate Dart class with documented method signatures.
* **5 HTTP verbs** — GET, POST, PUT, DELETE, PATCH all wired with shared
  401-refresh-retry-once invariant.
* **DTO-as-canon** — every wire field name matches the BFF's
  `Update<X>Request.toJson()` exactly. CLI flag names may differ for UX
  (e.g., `--role-id` → `role`); tests pin both presence of DTO key and
  absence of CLI flag literal.

For deeper architecture detail see
[`.pipeline/phase-5-cli-first/`](../../.pipeline/phase-5-cli-first/) — every
ticket has 4 reports (W0 RED, W1 GREEN, W2 review, W3 quality).

---

## Development

### Running tests

```bash
cd apps/cli
dart test                              # 704 tests
dart test test/golden/                 # 46 golden snapshots
UPDATE_GOLDENS=1 dart test test/golden # regenerate goldens after impl change
```

### Manual smoke test against staging

```bash
acdg auth login
acdg patient list --bff=https://social-care-hml.acdgbrasil.com.br
```

### Publishing a release (future)

GitHub Actions matrix build. Tracked under post-Phase-5 follow-ups.

---

## License

See repository root.

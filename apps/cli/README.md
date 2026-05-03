# ACDG CLI

Command-line interface for the ACDG social care system. Operate the BFF from
shell scripts, CI jobs, and interactive terminals.

## Build

```bash
dart compile exe apps/cli/bin/acdg.dart -o /usr/local/bin/acdg
```

## Usage

```bash
acdg --help
```

Sub-commands:

| Command      | Purpose                                  | Status (C01) |
|--------------|------------------------------------------|--------------|
| `auth`       | Manage authentication                    | stub → C02   |
| `patient`    | Patient registry operations              | stub → C03   |
| `family`     | Family member operations                 | stub → C04   |
| `assessment` | Update assessment forms                  | stub → C05   |
| `care`       | Care appointments and intake             | stub → C06   |
| `protection` | Violations, referrals, placement         | stub → C07   |
| `lookup`     | Lookup tables and approval requests      | stub → C08   |
| `team`       | Team management                          | stub → C09   |
| `health`     | Service health probes                    | stub         |

Global flags:

* `--bff=<url>` — BFF base URL (default `http://localhost:3000`).
* `--output=<json|table|yaml>` — auto-detect when omitted (tty → table,
  pipe → json, per `gh CLI` parity).
* `--quiet` — suppress info logs.

See [`.pipeline/phase-5-cli-first/`](../../.pipeline/phase-5-cli-first/) for
the full ticket history.

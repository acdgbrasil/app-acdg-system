---
title: "No hardcoded secrets or OIDC config"
scope: "pull_request"
severity_min: "critical"
buckets: ["security"]
enabled: true
---

## Instructions

Scan the PR diff for hardcoded secrets, tokens, or OIDC configuration values.

Flag as critical:
- Hardcoded OIDC_ISSUER, OIDC_CLIENT_ID, OIDC_CLIENT_SECRET values
- API keys, bearer tokens, or credential strings
- Zitadel client IDs or secrets in source code
- Tokens stored in localStorage or sessionStorage (must use split-token pattern)
- Any `.env` file committed (only `.env.example` is allowed)

Allowed:
- `--dart-define-from-file=.env` references
- `String.fromEnvironment()` calls
- `.env.example` with placeholder values
- Test fixtures with obviously fake values

This project handles patient health data. Credential leaks are compliance incidents.

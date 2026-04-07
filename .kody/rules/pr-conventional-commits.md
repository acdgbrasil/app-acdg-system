---
title: "PR title must follow Conventional Commits"
scope: "pull_request"
severity_min: "high"
buckets: ["style-conventions"]
enabled: true
---

## Instructions

PR title must start with a valid Conventional Commits prefix: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`

Optional scopes for this monorepo: `shell`, `core`, `design_system`, `social_care`, `bff`, `auth`, `network`

Example: `feat(social_care): add patient registration page`

Use `pr_title` to validate.

---
name: kodus-review
description: Run Kodus AI code review locally without needing a PR
user_invocable: true
---

# Kodus Code Review Local

Run a Kodus AI-powered code review directly from Claude Code, without abrir PR.

## Usage

The user can invoke this skill with `/kodus-review` optionally followed by arguments:

- `/kodus-review` — review changes vs main branch
- `/kodus-review staged` — review only staged files
- `/kodus-review <file1> <file2>` — review specific files
- `/kodus-review fast` — quick review with lighter checks

## Instructions

1. Parse the user's arguments (if any) from `$ARGUMENTS`
2. Determine the appropriate kodus command:
   - No args or "branch": `kodus review --branch main --format markdown`
   - "staged": `kodus review --staged --format markdown`
   - "fast": `kodus review --branch main --fast --format markdown`
   - Specific files: `kodus review --format markdown <files>`
3. Run the command via Bash
4. Read the output and present a structured summary to the user:
   - Total issues found (by severity)
   - Critical/error items that must be fixed
   - Warnings worth reviewing
   - Suggestions (optional improvements)
5. If the user asks to fix issues, apply the fixes following project conventions from CLAUDE.md

## Important

- Always use `--format markdown` for readable output
- Never use `--fix` automatically — always show results first and let the user decide
- If kodus is not authenticated, tell the user to run `! kodus auth login`
- The review uses Kody Rules configured in the repo, so results match what the PR review would catch

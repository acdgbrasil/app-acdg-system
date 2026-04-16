#!/bin/bash
set -euo pipefail

# Hook: PreToolUse (Bash git commit *)
# Runs kodus review on staged changes before Claude commits.
# Exit 0 = allow, Exit 2 = block commit.

HOOK_INPUT=$(cat)
COMMAND=$(echo "$HOOK_INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_arguments',{}).get('command',''))" 2>/dev/null || echo "")

# Only intercept actual git commit commands
if [[ ! "$COMMAND" =~ ^git[[:space:]]+commit ]]; then
  exit 0
fi

# Check if there are staged changes
if ! git diff --cached --quiet 2>/dev/null; then
  HAS_STAGED=true
else
  echo "No staged changes found, skipping kodus review." >&2
  exit 0
fi

# Run kodus review on staged files
if command -v kodus &>/dev/null; then
  RESULT=$(kodus review --staged --format json --prompt-only 2>&1) || true

  if [ -z "$RESULT" ]; then
    exit 0
  fi

  # Check for error/critical severity issues in JSON output
  HAS_BLOCKERS=$(echo "$RESULT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    issues = data if isinstance(data, list) else data.get('issues', data.get('results', []))
    blockers = [i for i in issues if isinstance(i, dict) and i.get('severity', '').lower() in ('error', 'critical')]
    print(len(blockers))
except:
    print('0')
" 2>/dev/null || echo "0")

  # Always show the review output (markdown for readability)
  READABLE=$(kodus review --staged --format markdown --prompt-only 2>&1) || true
  echo "--- Kodus Code Review (staged) ---" >&2
  echo "$READABLE" >&2
  echo "--- End Kodus Review ---" >&2

  if [ "$HAS_BLOCKERS" != "0" ] && [ "$HAS_BLOCKERS" != "" ]; then
    echo "" >&2
    echo "BLOCKED: $HAS_BLOCKERS error/critical issue(s) found. Fix them before committing." >&2
    exit 2
  fi

  exit 0
else
  echo "Warning: kodus CLI not found in PATH. Skipping review." >&2
  exit 0
fi

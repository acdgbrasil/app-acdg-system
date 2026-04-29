#!/usr/bin/env bash
# check_no_sealed_cast.sh
#
# Defense-in-depth fallback for the `acdg_lints` `no_sealed_class_downcast`
# rule. Exists because `custom_lint` has flakiness with pub workspace caching
# (see packages/acdg_lints/README.md "Known issues").
#
# REMOVE this script the moment the upstream workspace caching issue is
# resolved AND the lint plugin is verified to run cleanly in CI on every
# package. Track via .pipeline/phase-3-bff-contract-a/tickets/A22-acdg-lints/.
#
# Scope:
# - Searches `bff/`, `packages/`, `apps/` for forbidden sealed-class downcasts.
# - Recognized sealed types: Result/Success/Failure (core_contracts) and the
#   Ok/Error variant naming used in some Flutter docs. Add new sealed
#   parents below as the codebase grows (e.g. Option, Either, NetworkState).
# - Skips any path containing `/test/`, `/tests/`, `/test_driver/`,
#   `/integration_test/`, or ending with `_test.dart` — same exemption logic
#   as the lint rule.
# - Skips comments (lines starting with `//` or `///` after optional space)
#   and lines inside obvious comment blocks (heuristic; not a parser).

set -euo pipefail

# Always operate from the frontend repo root so the relative ROOTS below
# resolve regardless of the caller's cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Patterns the rule targets. Word-boundary regex prevents matching e.g. a
# variable named `success` or `successResponse` — we require the literal
# generic-parameter form `Success<...>` / `Failure<...>` etc.
readonly PATTERN='(\bas[[:space:]]+(Success|Failure|Ok|Error)<)'

# Search roots — narrowed to source directories of the workspace.
readonly ROOTS=(bff packages apps)

# Extensions to inspect.
readonly INCLUDE='--include=*.dart'

# Directory exclusions (test code is exempt — see lint rule).
readonly EXCLUDE_DIRS=(
  --exclude-dir=test
  --exclude-dir=tests
  --exclude-dir=test_driver
  --exclude-dir=integration_test
  --exclude-dir=.dart_tool
  --exclude-dir=build
)

# Single-file exclusions (tests living next to source).
readonly EXCLUDE_FILES='--exclude=*_test.dart'

# Run grep with extended regex; suppress non-zero exit when nothing matches.
# Note on the second grep: `grep -rn` emits `path:lineno:content`. We need
# the regex to match `//` AFTER that prefix, so we anchor on `:[[:space:]]*//`
# rather than `^[[:space:]]*//`. Catches both `//` and `///` (doc comments).
matches=$(grep -rEn "$PATTERN" \
    "$INCLUDE" \
    "$EXCLUDE_FILES" \
    "${EXCLUDE_DIRS[@]}" \
    "${ROOTS[@]}" \
  | grep -vE ':[[:space:]]*//' \
  || true)

if [ -n "$matches" ]; then
  echo "ERROR: forbidden sealed-class downcast detected." >&2
  echo "Use switch / .map / .flatMap / combineWith instead." >&2
  echo "See PATTERN_MATCHING_POLICY.md §P5." >&2
  echo "" >&2
  echo "$matches" >&2
  exit 1
fi

echo "OK: no forbidden sealed-class downcasts found in source paths."

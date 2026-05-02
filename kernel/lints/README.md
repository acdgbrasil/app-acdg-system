# acdg_lints

Custom lint plugin for the ACDG monorepo. Built on top of the `custom_lint`
package (Celest).

## Rules

### `no_sealed_class_downcast` (error)

Forbids `as Subclass` casts where `Subclass` inherits from a `sealed` class.
Such casts bypass pattern-matching exhaustiveness, duplicate the runtime
discrimination, and silently break if a new variant is later added to the
sealed hierarchy.

Trigger: any `AsExpression` whose target type's element walks through
`allSupertypes` to find a `ClassElement` with `isSealed == true`.

**Exempt by design:**
- Files under `test/`, `tests/`, `test_driver/`, `integration_test/`
- Any `*_test.dart` file

In tests, `as Success<T>` is the canonical fail-fast assertion idiom — a
`TypeError` surfaces clearly in the runner output. Defensive switching in
tests, in contrast, can mask regressions silently.

## Usage

In a consuming package, add to `dev_dependencies`:

```yaml
dev_dependencies:
  custom_lint: ^0.8.1
  acdg_lints:
    path: ../../packages/acdg_lints
```

Wire the plugin in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - no_sealed_class_downcast
```

Run from the consuming package directory:

```bash
dart run custom_lint
```

## Reference

- Policy: `handbook/architecture/PATTERN_MATCHING_POLICY.md` §P5
- Bypass investigation: `.pipeline/phase-3-bff-contract-a/tickets/A23-uuid-path-validation/W4-bypass-investigation/BYPASS-REPORT.md`
- Future rules ticket: `.pipeline/phase-3-bff-contract-a/tickets/A22-acdg-lints/000-request.md`

## Known issues

- **Workspace caching:** in pub workspace mode (`resolution: workspace`)
  the `custom_lint` CLI may report stale results until the in-memory plugin
  daemon (`custom_lint_client`) is restarted. Workaround:
  `pkill -f custom_lint_client` before re-running. The IDE plugin path
  (analyzer plugin) does not exhibit this flakiness.
- See `scripts/check_no_sealed_cast.sh` for a defense-in-depth CI fallback
  that doesn't depend on the plugin daemon — exists until the workspace
  caching issue is resolved upstream.

## Future rules (per A22 backlog)

- `catch_without_stack_in_adapter`
- `intent_parse_must_accept_obs`
- `parse_error_must_be_private`
- `prefer_logical_pattern_grouping`

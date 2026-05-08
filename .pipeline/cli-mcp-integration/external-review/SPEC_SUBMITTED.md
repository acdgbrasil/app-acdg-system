# Adversarial Review Brief — ticket cli-mcp-integration v2

## Q1 — Adversarial questions FIRST (answer these EXPLICITLY in your output)

You are SECONDARY. Internal reviewers W4 (flutter-code-reviewer) and W5 (flutter-quality-checker) ALREADY ran and APPROVED with minor should_fix. Your role: find what they MISSED, with focus on attack vectors and policy edge cases.

**Q1.1 — STDIO collision attack vector.**
The MCP transport uses stdin/stdout for JSON-RPC frames. Any `print()` / `stdout.write` outside the dart_mcp `stdioChannel` corrupts the channel and breaks the AI host's parser. Internal reviewers verified `grep -rn 'print(' apps/cli/lib/src/mcp/` → 0 matches; `grep -rn 'stdout\.' apps/cli/lib/src/mcp/` → only mcp_server_adapter.dart (passing to `stdioChannel(input: _stdin, output: _stdout)`).

**Question:** are there indirect paths to stdout from `lib/src/mcp/` that internal grep missed? Specific risks:
- Any imports from `lib/src/` modules that DO write to stdout (e.g., `bff_client.dart`, `output_formatter.dart`, `_writeOut` helpers in commands)?
- Logger configuration race: if `McpLoggerSetup.redirectToStderr` runs AFTER any log statement (e.g., `Logger('foo').info(...)` in `BffClient` constructor), would the early log leak to stdout?
- Does `dart_mcp` itself ever print to stdout (e.g., for protocol error fallback)?

**Q1.2 — Stack trace leak in CallToolResult.**
Internal reviewers verified the registry's `_redactCliError` switch redacts NetworkError/ServerError to generic strings. But: the `try/catch (e, st)` catch-all in `dispatch` returns `'Tool handler crashed (logged).'`.

**Question:** is there any path where the underlying `Object e` could leak into the CallToolResult? Specific:
- If `e.toString()` is composed somewhere via interpolation (`'Failed: $e'`) that I missed — does that happen?
- The `_logger.severe('tool.X.handler_threw', e, st)` call — does `package:logging` ever forward to stdout in any record-handler pathway?
- The `dart_mcp` library: any path where it calls `record.toString()` or `error.toString()` and writes to the JSON-RPC channel?

**Q1.3 — RBAC bypass via empty session.**
Internal logic: `tool.definition.requiredRoles.isNotEmpty` triggers RBAC; empty set skips. Tools `health` and `auth.status` have empty `requiredRoles`.

**Question:** is there a way to call a `requiredRoles: {social_worker, ...}` tool with empty session? Specific:
- What if `session.roles` is `null` or empty list? The check is `actorRoles.intersection(required).isEmpty` — does empty intersection always block, or could a malformed session bypass?
- What if `_credentialStore.read()` throws (keychain corrupted)? Does the registry handle the throw, or does the exception escape and become "tool succeeded with no auth"?

**Q1.4 — Argument injection via JSON Schema bypass.**
Tools validate args via custom `inputSchema.validateArgs(args)`. The DESIGN says this is minimalistic (type check + required + additionalProperties; no $ref/pattern/format).

**Question:** is there a malformed args input that bypasses validation but reaches the BFF query? Specific:
- `patient.get { patientId: "P-1234'; DROP TABLE--" }` — the BFF should sanitize, but our handler does `_bffClient.get('/patients/$patientId')`. Path injection? URL injection?
- `patient.list { limit: 1.5 }` — JSON allows decimal numbers; if validateArgs only checks `type: 'integer'` superficially, would `1.5` pass and crash on `bffClient.get('?limit=1.5')`?
- `additionalProperties: false` — does our validateArgs actually enforce this? If not, attacker can attach arbitrary keys.

**Q1.5 — Pin discipline + supply chain.**
`pubspec.yaml` adds `dart_mcp: 0.5.1` (pin sem caret). Commit also adds `logging: ^1.3.0` and `meta: ^1.16.0` WITH caret.

**Question:** is the caret on `logging` and `meta` problematic? Both are widely-used Google packages, but supply chain risk exists. Should ALL three be pinned? Or just `dart_mcp` because of v0.x SemVer instability?

**Q1.6 — REGRA #2 exception verdict.**
W3 changed `e2e_stdio_test.dart:172-173` from `StreamController()` to `StreamController.broadcast()`, declared as REGRA #2 fixture-bug exception. W4 verified by reading the test code and CONFIRMED legitimate (single-subscription stream + `firstWhere` repeated calls = lock).

**Question:** independently verify W4's verdict. Does the broadcast variant introduce ANY behavior change beyond fixing the lock? Specifically: broadcast streams replay events to late subscribers vs. single-subscription; does any test depend on this?

**Q1.7 — Sealed exhaustivity in `_redactCliError`.**
W4 F1 catalogued: `_redactCliError` switches over `Object` (not `CliError`) with `_ =>` arm. This bypasses CliError sealed exhaustivity — adding new CliError subtype doesn't fail compilation.

**Question:** is this a must_fix or should_fix? In ACDG canon, is `Object`-typed switch with `_` fallback acceptable when the concrete shape comes from a `Failure<T>(error)` where the lint can't enforce the sealed family at the boundary?

**Q1.8 — Logger setup idempotency vs concurrency.**
`McpLoggerSetup.redirectToStderr` uses static `_installed = true` flag. Single-threaded Dart isolate, so race-free. But:

**Question:** if `mcp serve` is invoked multiple times in same isolate (test scenario), does `_installed` flag persist across runs and cause silent log loss? Tests use `resetForTesting()` — production never calls reset. Edge case for later: if MCP server restarts within same process, what's the behavior?

## Q2 — Context

Ticket: `cli-mcp-integration` v2 (frontend monorepo, apps/cli/). 5 read-only MCP tools exposed via stdio for AI hosts (Claude Desktop, Cursor, ChatGPT). v1 archived after audit found 7 structural failures (stdio collision, recursion, monolithic error, etc.). v2 fresh design eliminates all 7. Internal pipeline (W0-W5) executed; W4 APPROVED, W5 PASSED with 1 warning (format gap in test/).

Reviewer history of this ticket:
- W4 found 4 should_fix (sealed exhaustivity in _redactCliError, props doc mismatch, EquatableMixin terminology, import order).
- W4 found 4 info (registry not enforcing dart_mcp's own validation; dead `_onUnhandledError`; tearoff cosmetic; null-aware spread cosmetic).
- W5 found 1 warning (W3 didn't run `dart format` on test/, 10 files reformatted by W5 — process gap).
- W5 found 1 cataloguing oversight (W4 missed `// ignore: unused_field` on line 141 paired with line 122).

## Q3 — What this patch is supposed to do

- Add `dart_mcp: 0.5.1` pinned dependency.
- Create boundary adapter (`mcp_server_adapter.dart`) isolating dart_mcp.
- Create tool registry routing (schema → RBAC → handler → CallToolResult shaping with error redaction).
- Create 5 tool handlers (health, auth.status, patient.list, patient.get, lookup.get).
- Create sealed `McpAdapterError` family (Protocol/Transport/Tool/Auth) with sysexits exit codes.
- Wire `McpCommand` into `cli_runner.dart` (single line addition between team and health commands).
- Configure `Logger.root` to redirect to stderr before adapter starts (idempotent helper `McpLoggerSetup`).

## Q4 — What this patch is NOT supposed to do

- ❌ Mutations (POST/PUT/DELETE) — out of MVP, deferred to future ticket.
- ❌ HTTP/SSE transport — stdio only.
- ❌ Browser-based AI host integration (Claude on web, etc.) — stdio requires local process.
- ❌ Offline mode — relies on BFF connectivity.
- ❌ Multi-tenant in same MCP server process — one XDG session per process.
- ❌ Refactoring `BffClient` from `final class` to abstract — kept as-is, tests use Dio adapter stub.

## Q5 — Compliance targets specific to this ticket

The HOTTEST must_fix categories for this diff (in order):

1. **must_fix #4 (PII / secret leak)** — TOP priority. Stack trace must NEVER reach AI host. Tokens/JWT in logs even on stderr is concerning per LGPD.
2. **must_fix #2 (throw policy)** — handlers should NEVER throw; defined panics in adapter only.
3. **must_fix #5 (auth bypass)** — RBAC must be uncircumventable. Verify session-null path and role-empty path.
4. **must_fix #1 (Result<T> discipline)** — handlers return Result, registry switches exhaustively.
5. **must_fix #6 (Equatable contract)** — `McpToolDefinition` value, others reference.
6. **must_fix #8 (Single oracle)** — error redaction must be in ONE place (`_redactCliError`), not duplicated across handlers.

Less hot for this ticket:
- must_fix #3 (test cheating) — only one REGRA #2 exception, already verified by W4.
- must_fix #7 (sealed downcast) — defended by lint, no diff hits.

## Q6 — How to deliver

`verdict`: approved | rejected | partial_review (set partial_review:true if diff truncated/missing context).

For each finding: `severity` (must_fix | should_fix | info), `file` (relative path), `line`, `rule` (with §N.M from charter or skill citation), `message`, `recommendation`.

Be terse. NO findings without exact line citation. NO findings without rule reference. NO speculation about behavior — read the code.

Cite Q1.1 through Q1.8 explicitly: for each adversarial question, give a clear answer (yes/no/partially) with evidence from the diff.

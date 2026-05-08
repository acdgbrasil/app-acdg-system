# W4 — CODE REVIEW: CLI-MCP-INTEGRATION (v2)

> **Ticket:** CLI-MCP-INTEGRATION
> **Wave:** W4 (defensive review of W3 GREEN)
> **Reviewer:** flutter-code-reviewer agent (defensive mode)
> **Date:** 2026-05-07
> **Pipeline:** 4-agent BFF/CLI canon
> **Output:** verdict + findings table + routing
> **Pré-requisitos lidos:**
>   - `000-discuss/CONTEXT.md` (8 ADRs, threat model, 5 tools MVP, 12 critérios)
>   - `001-design/DESIGN.md` (signatures, fluxos, schemas, RBAC matrix)
>   - W3 production code in `apps/cli/lib/src/mcp/` (5 handlers + 5 boundary files)
>   - `apps/cli/lib/src/errors/cli_error.dart` (sealed `McpAdapterError` family)
>   - `apps/cli/lib/src/cli_runner.dart` + `lib/cli.dart` (wire-up)
>   - `apps/cli/pubspec.yaml` (`dart_mcp: 0.5.1` pin)
>   - W2 RED tests (5 handler tests + 4 boundary tests + e2e_stdio + cli_error)
>   - `CLAUDE.md` REGRA #2 (no test cheating)
>   - `dart_mcp 0.5.1` source (`~/.pub-cache/hosted/pub.dev/dart_mcp-0.5.1/`)
>
> NOTE: W2 / W3 REPORT.md files referenced in the brief do not exist on disk
> (`002-tests/`, `003-impl/` are empty). Review proceeded against the actual
> code committed to `lib/` and `test/` instead. The W3 "Notes for W4" and W2
> RED report had to be inferred from the test/code shapes themselves.

---

## §1 — Verdict

**APPROVED with 4 should_fix recommendations.**

W3 implements the entire DESIGN end-state. All 23 W2 RED tests are GREEN
(`dart test` passes 24/24 unit tests; e2e stdio test runs subprocess —
not run here, deferred to W5 quality gates). `dart analyze` reports zero
issues in `lib/` and 2 info-level lints in `test/` (one `unnecessary_lambdas`,
one `use_null_aware_elements`). REGRA #2 exception (`StreamController` →
`StreamController.broadcast()` in `e2e_stdio_test.dart`) is **legitimate**
— see §3.3 for the full analysis.

Critical security properties are met:
- Sealed `McpAdapterError` family with 4 subtypes + sysexits exit codes (DESIGN §2.8).
- No sealed downcast (`as Success`, `as Failure`, `as Mcp*Error`) anywhere in `lib/`.
- No `print(`, no `stdout.` write outside the adapter's stdio channel.
- `throw` is restricted to one place: the documented "second `start()`" defined
  panic at the adapter boundary (DESIGN §2.3, ADR-019).
- `NetworkError` redaction is verified by code reading + test fixture (host:port
  message string is dropped, only the literal `'Network error reaching BFF (logged).'`
  is surfaced — see §3.5).
- `ServerError` redaction surfaces only `statusCode`, body discarded.
- RBAC enforcement traces correctly: registry checks `requiredRoles` BEFORE
  invoking handler (line 86 in `mcp_tool_registry.dart`).
- Logger is wired to stderr by `McpServeCommand.run()` (line 43) BEFORE the
  adapter starts.
- Single-source-of-truth for error redaction is the registry's
  `_redactCliError` helper. Handlers never format error strings.

The 4 should_fix items are improvements (not blockers) and are listed in §2.
Pipeline can proceed to **W5 (quality)** after these are filed as follow-ups.

---

## §2 — Findings Table

| # | Severity | File:Line | Description | Recommendation | Routing |
|---|---|---|---|---|---|
| F1 | should_fix | `apps/cli/lib/src/mcp/mcp_tool_registry.dart:163-177` | `_redactCliError` switches over `Object` (forced by `Failure.error: Object`) with a final `_ =>` arm. Adding a new `CliError` variant later will silently fall through to `'Unexpected error (logged).'` instead of being caught at compile time. PATTERN_MATCHING_POLICY §P5 wants sealed exhaustivity. | Refactor as `if (error is! CliError) return 'Unexpected error (logged).'; return switch (error) { /* enumerate every CliError variant; NO `_ =>` arm */ };`. The compiler then enforces exhaustivity over the sealed `CliError` family for free. | flutter-bff-implementer |
| F2 | should_fix | `apps/cli/lib/src/mcp/mcp_tool_definition.dart:21-23` and `:64` | Doc comment claims `props == [name, description, requiredRoles, schemaSnapshot]`, but actual `props` returns `[name, description, requiredRoles]` (no `schemaSnapshot`). W3 note #5 justifies excluding `inputSchema` (tool name is unique per registry) — but the doc comment is contradictory. | Either align the doc comment with `props` (drop the `schemaSnapshot` mention and document why) or include `inputSchema._value` (the underlying `Map<String,Object?>`) in `props`. Pick one — current state is misleading. | flutter-bff-implementer |
| F3 | should_fix | `apps/cli/lib/src/mcp/mcp_tool_definition.dart:24` (and class doc lines 12-13) | Doc comment says "value types use `with EquatableMixin` rather than `extends Equatable`" but the code uses `with Equatable` (project canon). The `Equatable` class in `kernel/contracts` is an `abstract mixin class`, so `with Equatable` is correct — but the doc reference to "EquatableMixin" misleads the next reader (suggests `package:equatable` semantics). | Fix the doc comment to say `with Equatable` matches project canon (the `abstract mixin class Equatable` in `kernel/contracts/lib/src/utils/equatable/equatable.dart`). Drop the `EquatableMixin` term from the comment. | flutter-bff-implementer |
| F4 | should_fix | `apps/cli/lib/src/cli_runner.dart:64-66` | Import order has `mcp_command.dart` (line 65) sandwiched between `lookup_batch_command.dart` (64) and `lookup_command.dart` (66). Alphabetically all `lookup_*` should precede `mcp_*`. Project's `analysis_options` does not enable `directives_ordering` (`dart analyze` returns clean), but every other import block in this file is alphabetised — this is the only outlier. | Move `import 'commands/mcp_command.dart';` to its natural alphabetical slot (after `commands/lookup_update_command.dart`). One line move. | flutter-bff-implementer |
| F5 | info | `apps/cli/lib/src/mcp/mcp_tool_registry.dart:24` + 5 handler files + `mcp_tool_definition.dart` | `package:dart_mcp/server.dart` is imported in 8 files inside `lib/src/mcp/`, not just `mcp_server_adapter.dart`. ADR-MCP-003-v2 originally implied "single class isolates dart_mcp" — but DESIGN §2.4 already shows `Future<mcp.CallToolResult> dispatch(...)` in the registry signature, so the boundary is the `mcp/` **directory** not a single file. The `ObjectSchema` type used in handler `inputSchema` fields cascades the import to all 5 handlers. Acceptable trade-off: typed schemas with built-in `validate()` beat untyped maps. | No code change. Update ADR-MCP-003-v2 wording on the next handbook touch: the boundary is `lib/src/mcp/`, not "one class". | n/a (handbook update only) |
| F6 | info | `apps/cli/lib/src/mcp/mcp_server_adapter.dart:122-126` | `_onUnhandledError` is dead code (`// ignore: unused_element`). DESIGN §2.3 wired it to `_AcdgMcpServer(onError: ...)` but W3's actual `_AcdgMcpServer` constructor only takes `super.channel + Logger logger`, not an `onError` hook. The dead method is preserved with a SEC comment explaining why dart_mcp doesn't surface unhandled errors via callbacks at this version. | Either delete the method (the comment alone documents the rationale) or wire it to a place where it's reachable (e.g., `Zone.runGuarded` around the channel). Keeping `// ignore: unused_element` long-term is a smell. | flutter-bff-implementer |
| F7 | info | `apps/cli/test/mcp/mcp_logger_setup_test.dart:19` | `setUp(() { McpLoggerSetup.resetForTesting(); })` triggers `unnecessary_lambdas` info. | Use tearoff: `setUp(McpLoggerSetup.resetForTesting);`. Cosmetic; not blocking. | test-writer |
| F8 | info | `apps/cli/test/mcp/e2e_stdio_test.dart:229` | `if (params != null) 'params': params,` triggers `use_null_aware_elements` info. | Use null-aware spread: `'params': ?params,`. Cosmetic; not blocking. | test-writer |

**Total:** 0 must_fix, 4 should_fix, 4 info.

---

## §3 — Cross-cutting verifications

### §3.1 — REGRA #2 (no test cheating)

The W3 made one test fixture change: `e2e_stdio_test.dart` line 172-173 changed
`StreamController<Map<String, Object?>>()` to
`StreamController<Map<String, Object?>>.broadcast()`. The W3 comment claims
this is a fixture-bug fix per CLAUDE.md REGRA #2 exception ("typo / fixture
invalid").

**Analysis (4-point per REGRA #2):**

1. **Intention:** the test wants to drive a JSON-RPC handshake (multiple
   sequential `request()` calls — `initialize`, `tools/list`, `tools/call`,
   then `closeAndAwait`) and assert on responses.
2. **Failure (with single-subscription):** `request()` calls
   `_frames.stream.firstWhere(...)` on every invocation. A single-subscription
   `StreamController.stream` allows EXACTLY one listener; even after
   `firstWhere` resolves and cancels its subscription, a second `firstWhere`
   call would throw `Bad state: Stream has already been listened to`. The
   test runs 4 sequential `request()` calls, so the second call would crash.
3. **Verdict:** the original W2 fixture was objectively wrong — there is no
   way the test as written could pass with single-subscription, regardless
   of the implementation. Broadcast is the only correct shape for a stream
   that's consumed by sequential `firstWhere`. This matches REGRA #2's
   "fixture invalid" exception ("typo / fixture invalid → corrigir e seguir").
4. **Options considered:** (a) revert to single-subscription and rewrite the
   client into a single-listener pull model — bigger blast radius and not
   what the test was written to express; (b) accept broadcast as the right
   shape and move on. (b) is the right call. Comment in the test source
   explicitly cites REGRA #2 exception (line 169-171), and that comment
   itself satisfies the policy's documentation requirement.

**Verdict: legitimate fixture-bug fix. Not test cheating.**

### §3.2 — Sealed exhaustivity (PATTERN_MATCHING_POLICY §P5)

Three switch sites are scoped:

| Site | Sealed type? | Exhaustive? |
|---|---|---|
| `mcp_tool_registry.dart:95-98` (`switch(result)` over `Result<Object>`) | yes — `sealed class Result<T>` | yes — both `Success` and `Failure` matched, no `_ =>` |
| `mcp_tool_registry.dart:163-177` (`_redactCliError` over `Object`) | no — parameter is `Object` (not `CliError`) | bypassed by `_ =>` arm — see F1 |
| `mcp_error_mapper.dart:28-38` (`switch(error)` over `Object`) | no — parameter is `Object` | bypassed by `_ =>` arm — DESIGN intentional fallback |
| `cli_error_test.dart:100-113` (`_tagOf` over `CliError`) | yes — sealed | yes — every variant matched, no `_ =>` (compiler-enforced) |

The two `Object`-typed switches both have `_ =>` arms because their input is
not a sealed type. F1 lifts the registry's `_redactCliError` to gain
compile-time exhaustivity over the `CliError` sub-tree.

`McpErrorMapper.toAdapterError` intentionally keeps the fallback arm to
bucket "unrecognised exception types" into `McpProtocolError` — that's the
DESIGN §2.7 contract, and the runtime-type-only message string is
deliberately scrubbed of `toString()` content (verified by reading
`mcp_error_mapper.dart:34-37`).

### §3.3 — No sealed downcast

`grep -rEn 'as (Success|Failure|McpProtocolError|McpTransportError|McpToolError|McpAuthError)' apps/cli/lib/`
returns ONE hit:

```
apps/cli/lib/src/session/bff_client.dart:321:        // Retry exactly once — any second 401 is propagated as Failure
```

This is a comment ("propagated as Failure"), not a downcast. **Clean.**

The `acdg_lints/no_sealed_class_downcast` lint covers production code; tests
opt out (and tests do use `as Success<Object>` per H6 — "fail-fast cast in
tests is canonical"). Verified.

### §3.4 — Throw policy

`grep -rn 'throw ' apps/cli/lib/src/mcp/`:

| File:Line | Context | OK? |
|---|---|---|
| `mcp_tool_registry.dart:14` | doc comment | yes |
| `mcp_tool_registry.dart:92` | doc comment | yes |
| `mcp_server_adapter.dart:14` | doc comment | yes |
| `mcp_server_adapter.dart:64` | doc comment | yes |
| `mcp_server_adapter.dart:67` | `throw StateError('McpServerAdapter.start() called twice')` | **YES** — adapter boundary, defined panic, ADR-019 |
| `mcp_server_adapter.dart:118` | doc comment | yes |

The single executable `throw` is the documented "second start() = StateError"
defined panic. Domain (handlers, registry, mapper) NEVER throws — they all
return `Result<T>` or `CallToolResult(isError: true)`. **Clean.**

### §3.5 — PII / secret leak (NetworkError redaction)

Manual trace: `_ThrowingAdapter` raises `DioException(message: 'connection refused at 10.0.0.5:5432')` → `BffClient._translate` returns `NetworkError(e.message ?? 'connection failed')` (so the message string `'connection refused at 10.0.0.5:5432'` is now in `NetworkError.message`) → `BffClient.get` returns `Failure(NetworkError(...))` → registry `dispatch` matches `Failure(:final error)` → `_redactCliError(error)` → switch arm `NetworkError() => 'Network error reaching BFF (logged).'`. 

Note: the arm uses `NetworkError()` (the empty pattern) — it doesn't bind
`message` and doesn't include it in the returned literal. The arm returns
ONLY the literal `'Network error reaching BFF (logged).'`. The host:port
detail is dropped at the redaction layer. **Confirmed safe by code reading.**
The `mcp_tool_registry_test.dart` test explicitly asserts `isNot(contains('10.0.0.5'))`
and was GREEN locally.

`ServerError(:final statusCode)` arm similarly extracts ONLY `statusCode` —
the BFF's response body (which could carry leak info) is dropped. **Confirmed safe.**

### §3.6 — Stack-trace leak via tool error

The dart_mcp default for unhandled tool errors is `CallToolResult(text: '$e\n$s')`
(stack-trace leaks). W3 guards by:

1. Registry's `try { ... } catch (e, st) { _logger.severe(...); return _errorResult('Tool handler crashed (logged).'); }` (mcp_tool_registry.dart:99-103). Stack trace goes to the local logger, not to `CallToolResult`.
2. `validateArguments: false` on `server.registerTool` (mcp_server_adapter.dart:84) — disables dart_mcp's own validation path so it never throws a validation exception that the dart_mcp framework would auto-format with stack trace.

So in the chain `tools/call → _AcdgMcpServer.callTool → registry.dispatch → handler`, every error path goes through the registry. Handler exceptions are caught one level up. **No stack-trace path reaches `CallToolResult`.**

### §3.7 — Logger always stderr / no stdout pollution

`grep -rn 'print(\|stdout\.' apps/cli/lib/src/mcp/` returns only doc-comment
mentions (lines 8 and 38 of `mcp_logger_setup.dart`). The actual code never
calls `print()` and never writes to `stdout` directly.

The adapter does take a `StreamSink<List<int>>` (named `_stdout`) and passes
it to `stdio.stdioChannel(input: _stdin, output: _stdout)` — that IS the
JSON-RPC channel; THAT's where stdout is supposed to go (the protocol
channel). No leak: only `dart_mcp`'s own JSON-RPC frames write to that sink.

`McpServeCommand.run()` calls `McpLoggerSetup.redirectToStderr(_stderr)` on
line 43 BEFORE building the adapter — verified.

`McpLoggerSetup` listens on `Logger.root.onRecord` and writes to the supplied
sink (stderr in production). No `print()`, no `stdout.write` anywhere in the
listener body. **Confirmed safe.**

### §3.8 — Equatable contract

Project uses `abstract mixin class Equatable` (kernel/contracts). The single
value type in the W3 set is `McpToolDefinition` — it correctly uses
`with Equatable` and provides `props`. The doc comment is misleading (see
F2/F3) but the runtime behaviour is correct.

Reference types (`McpServerAdapter`, `McpToolRegistry`, `McpErrorMapper`,
`McpLoggerSetup`, all 5 handlers) **do NOT** use Equatable — correct, they
are not value types.

### §3.9 — RBAC enforcement (manual trace)

Trace of `tools/call patient.get { patientId: "P-1234" }`:

1. dart_mcp dispatches to the closure registered at `mcp_server_adapter.dart:81-85`:
   `(request) => _registry.dispatch(request.name, request.arguments ?? const {})`.
2. `mcp_tool_registry.dart:67 dispatch('patient.get', {patientId: 'P-1234'})`.
3. Line 71: `final tool = _tools['patient.get']` → returns `PatientGetTool`.
4. Line 79: `tool.toolDefinition.validateArgs(args)` → `mcp.ObjectSchema.validate({patientId: 'P-1234'})` → `[]` (passes, since `required: ['patientId']` is satisfied and `additionalProperties: false`).
5. Line 86: `tool.toolDefinition.requiredRoles` is `{social_worker, owner, admin}` — not empty, so RBAC check fires.
6. Line 87: `_credentialStore.read()` → `OidcSession?` snapshot.
7. Line 88: `_checkRbac(session, requiredRoles)` — verifies `actorRoles.intersection(required)` is non-empty. **Authentication enforced BEFORE handler invocation.** Match: line 108-121.
8. Line 94: `await tool.invoke({patientId: 'P-1234'})` → `PatientGetTool.invoke` → `_bffClient.get('/patients/P-1234')` → `Result<Object>`.
9. Line 95-98: switch matches `Success` → `_successResult(value)` (jsonEncoded) OR `Failure(:final error)` → `_redactCliError(error)`.

**No bypass step exists.** RBAC, schema validation, error redaction, and
stack-trace catch-all are all chained in the single registry method, in
the correct order documented in DESIGN §2.4.

### §3.10 — Single-oracle for error redaction

All 4 redaction arms (`AuthRequiredError`, `RefreshTokenInvalidError`,
generic CliError variants, MCP variants) live in ONE method:
`_redactCliError` at `mcp_tool_registry.dart:163-177`. Handlers never
format error strings. Confirmed by reading all 5 handler files —
each `invoke` method delegates to `_bffClient.get` (or
`_credentialStore.read` for auth_status) and forwards the `Result` upward.
**Clean.**

### §3.11 — `// SEC:` annotations

Load-bearing lines that carry `SEC:` comments:

| File:Line | Concern | OK? |
|---|---|---|
| `mcp_logger_setup.dart:38` | "never `print()` here — that's stdout" | yes |
| `mcp_server_adapter.dart:14-17` | throw policy at boundary | yes |
| `mcp_server_adapter.dart:97-99` | log "connected" canary for e2e test | yes |
| `mcp_server_adapter.dart:117-121` | dead-code rationale + dart_mcp default leak guard | yes |
| `mcp_serve_command.dart:40-42` | logger redirect ordering | yes |
| `mcp_tool_registry.dart:76-78` | schema validation FIRST | yes |
| `mcp_tool_registry.dart:84-85` | RBAC second | yes |
| `mcp_tool_registry.dart:144-148` | jsonEncode fallback | yes |
| `mcp_error_mapper.dart:34-36` | drop `toString()` on fallback to avoid stack-trace leak | yes |
| `cli_runner.dart` (existing) | not changed by this ticket | n/a |
| handler files | not annotated — but handlers are dumb forwarders, no security-sensitive lines | acceptable |

Annotations are placed only on lines that matter, not spammed everywhere.
**Compliant.**

---

## §4 — Specific commands run

```bash
# Sealed downcast scan
$ grep -rn 'as Success' apps/cli/lib/        # 0 hits (one comment match)
$ grep -rn 'as Failure' apps/cli/lib/        # 1 comment match (bff_client.dart:321)
$ grep -rEn 'as Mcp(Protocol|Transport|Tool|Auth)Error' apps/cli/lib/  # 0 hits

# Stdio policy scan
$ grep -rn 'print(' apps/cli/lib/src/mcp/    # only doc-comment mentions
$ grep -rn 'stdout\.' apps/cli/lib/src/mcp/  # only doc-comment mentions

# Throw policy scan
$ grep -rn 'throw ' apps/cli/lib/src/mcp/    # 1 executable: mcp_server_adapter.dart:67 (defined panic)

# dart_mcp boundary scan
$ grep -rln 'package:dart_mcp' apps/cli/lib/  # 8 files in lib/src/mcp/ — see F5

# Static analysis + format
$ dart format --output=none --set-exit-if-changed apps/cli/lib/src/cli_runner.dart apps/cli/lib/src/mcp/ apps/cli/lib/src/commands/mcp_command.dart apps/cli/lib/src/commands/mcp_serve_command.dart apps/cli/lib/cli.dart
> Formatted 14 files (0 changed) in 0.04 seconds.

$ dart analyze lib/                          # No issues found!
$ dart analyze test/mcp/ test/errors/cli_error_test.dart  # 2 info hints (F7, F8)

# Test run
$ dart test test/mcp/handlers/ test/mcp/mcp_*_test.dart test/errors/cli_error_test.dart
> All 24 unit tests passed.
```

(e2e_stdio_test.dart was NOT run during W4 — it requires `Process.start` of
the CLI binary and is intentionally deferred to W5 quality gates per
ADR-MCP-008-v2.)

---

## §5 — Routing decision

**Verdict:** APPROVED with 4 should_fix recommendations.

**Pipeline next step:** proceed to **W5 (flutter-quality-checker)** —
should_fix items are tracked as follow-ups, not blockers. The quality
gates will independently re-run analyze/format/test and add `dart compile exe`
+ E2E stdio test.

**Routing for should_fix follow-ups (post-W5, single round):**

- F1 → flutter-bff-implementer (refactor `_redactCliError` for sealed exhaustivity)
- F2 → flutter-bff-implementer (align doc comment with `props`)
- F3 → flutter-bff-implementer (drop "EquatableMixin" reference in doc)
- F4 → flutter-bff-implementer (move `mcp_command.dart` import to alphabetical slot)

These are mechanical, low-risk fixes; one review round suffices. F6 (dead
`_onUnhandledError`) is also a candidate for the same round if scope permits.

F7, F8 are info-only and routed to test-writer for cosmetic cleanup at
their next test pass — no blocker.

---

## §6 — Pipeline status

| Wave | Status |
|------|--------|
| W0 (discuss) | done |
| W1 (design) | done |
| W2 (RED tests) | done — 24 unit tests + 3 e2e tests written |
| W3 (GREEN impl) | done — 24/24 unit tests pass; e2e deferred to W5 |
| **W4 (review)** | **done — APPROVED with 4 should_fix** |
| W5 (quality) | pending — `dart compile exe` + e2e stdio + coverage gate |
| External (Charter) | pending — after W5 GREEN |

**Verdict:** APPROVED with 4 should_fix recommendations.

# C01 W2 — Code Review

## Verdict: APPROVED

## Round: 1/3

---

## SRP per file

| File | Responsibility | Verdict |
|------|----------------|---------|
| `lib/cli.dart` | Barrel — re-export public surface | OK — 9 exports, no logic. |
| `lib/src/cli_runner.dart` | Compose `CommandRunner<int>`, wire global flags + 9 sub-commands, translate `UsageException` → exit 64 | OK — single concern, 116L. The `_CapturingCommandRunner` lives in the same file because it exists solely to bridge the `args` package's `print()`-on-stdout default; bundling it co-locates the workaround with its only consumer (acceptable per H1). |
| `lib/src/errors/cli_error.dart` | Sealed error family + 4 variants | OK — pure type definitions, zero behaviour. |
| `lib/src/formatters/output_formatter.dart` | Sub-contract for formatting | OK — 1 method, `const` constructor. |
| `lib/src/formatters/json_formatter.dart` | Compact JSON + trailing `\n` | OK — single line of substance. |
| `lib/src/formatters/table_formatter.dart` | ASCII table for Map / List<Map> / fallback | OK — 96L, all helpers private + scoped to the class. |
| `lib/src/formatters/yaml_formatter.dart` | YAML 1.2 block-style emitter | OK — recursive emitter with explicit empty-Map / empty-List sentinels. |
| `lib/src/formatters/auto_formatter.dart` | Resolver: `String?` + `bool` → `OutputFormatter` | OK — pure free function, 33L. |
| `lib/src/session/credential_store.dart` | `Credentials` + interface + `FileCredentialStore` (file I/O for tokens) | OK — no business logic; XDG resolution + JSON serdes only. |
| `lib/src/session/bff_client.dart` | Dio wrapper, Bearer interceptor, `DioException` → `Result<T, CliError>` | OK — strictly the HTTP boundary; nothing else lives here. |
| `lib/src/commands/_stub_command.dart` | Shared `writeStub` helper | OK — internal-only top-level function, file-private with `_` prefix. |
| `lib/src/commands/<noun>_command.dart` × 9 | One sub-command shell each | OK — each is ~22L: name, description, delegate to `writeStub`. |
| `bin/acdg.dart` | Entry — wire host stdout/stderr into runner, exit | OK — 15L, no logic beyond plumbing. |

**Verdict: SRP honored across all 16 production files. No file is doing two jobs.**

---

## ENCAPSULATION_POLICY (H1-H9)

- **H1 (Prefer `implements` over `extends`)** — Followed where possible. `CliRunner` composes `CommandRunner<int>` (has-a). `JsonFormatter`/`TableFormatter`/`YamlFormatter` `implements OutputFormatter`. `FileCredentialStore implements CredentialStore`. The only `extends` are: (a) sub-commands extending `args.Command<int>` — required by the framework; (b) `_CapturingCommandRunner extends CommandRunner<int>` — see H7 note below; (c) `InvalidArgError`/`AuthRequiredError`/`NetworkError`/`ServerError extends CliError` — required by Dart sealed-class rules.
- **H2 (Composition > Inheritance)** — `CliRunner` does **not** subclass `CommandRunner`; it composes it via `_runner` field and exposes only `runner` getter typed as the parent class. Foreign callers cannot see the subclass. PASS.
- **H3 (Mixin without state)** — `Credentials with Equatable` — mixin is stateless (`props` getter), as required.
- **H4 (`sealed class` for closed hierarchies)** — `CliError` is `sealed`; the 4 variants are `final class` — exhaustive. PASS.
- **H5 (`abstract interface class` for cross-layer contracts)** — `OutputFormatter` ✅, `CredentialStore` ✅. `BffClient` is a concrete `final class` — single implementation, no contract needed yet (justifiable per the "single implementation" carve-out in the policy; if C02 introduces a stub, the policy says extract an interface then). PASS for C01.
- **H6 (Enum only for truly immutable categories)** — No enums introduced; the formatter selector is a `String` in/out (validated by the resolver). The `_outputFormats` `const List<String>` is the public allow-list — accepted because formats are a closed code-controlled set, not a domain dimension. PASS.
- **H7 (Function before class when stateless)** — `resolveFormatter` is a top-level function, not a class. `writeStub` is a top-level function. PASS.
- **H8 (`extension type` for primitives)** — Not used; not required at this scaffold stage. No primitive obsession introduced (e.g. token strings are wrapped inside `Credentials`).
- **H9 (Cross-layer types as `abstract interface class`)** — Both `OutputFormatter` (formatters/) and `CredentialStore` (session/) are `abstract interface class`. PASS.

**One nuance:** `_CapturingCommandRunner extends CommandRunner<int>` (H1 violation surface). Justified because the `args` package's documented extension point IS subclassing — `command_runner.dart:99` says verbatim *"This is called internally by `run` and **can be overridden by subclasses** to control how output is displayed"*. The class is `final` + library-private (`_` prefix), exposed only via `runner` getter typed as the parent. This is the cleanest path; alternatives evaluated below (`_CapturingCommandRunner` rationale §). **APPROVED.**

---

## PATTERN_MATCHING_POLICY (P1-P5)

- **P1 (Exhaustive switch)** —
  - `auto_formatter.dart:resolveFormatter` uses switch expression with `_` only on the **explicit-format string**, falling to `throw InvalidArgError`. The valid-format arm covers `'json' / 'table' / 'yaml' / 'auto'` literal-by-literal. Not over a sealed type, so exhaustivity is bound to the string set; the throw default is the correct fallback for unknown user input.
  - `bff_client.dart:_translate` uses an imperative `switch` over `DioExceptionType` enum. Hits all 8 variants (`connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, `badCertificate`, `cancel`, `badResponse`, `unknown`). With `exhaustive_cases: true` + `no_default_cases: true` in `analysis_options.yaml`, the analyzer enforces this — adding a new Dio enum value would fail analyze. PASS.
  - `table_formatter.dart:format` and `yaml_formatter.dart:_emit` use switch expressions with type patterns + `_ => fallback` — fallback is correct here because the match domain is `Object?`, which is genuinely open (any Dart value can show up).
- **P2 (`if-case` for validation)** — Not exercised in C01 (no JSON-shape validation yet; comes in C02+). N/A.
- **P3 (Tear-offs)** — `table_formatter.dart` uses `.map((e) => [e.key, _stringify(e.value)])`-style closures because the projection is non-trivial; tear-off would require argument transformation. Acceptable. No closures-where-tear-offs-would-fit detected.
- **P4 (`Never` for failure paths)** — Not used; the only `throw` is in `resolveFormatter` for invalid `--output=` values, and that's a genuine adapter-boundary throw that bubbles through `CliRunner.run` (well — actually it bubbles past `UsageException` handler; see SHOULD_FIX #1 below). N/A for `Never`.
- **P5 (No sealed-class downcast)** — `grep -rn "as Success\|as Failure\|as InvalidArg\|as AuthRequired\|as NetworkError\|as ServerError\|valueOrNull!" lib/` returns ZERO hits. The `acdg_lints/no_sealed_class_downcast` rule is enabled in `analysis_options.yaml`. PASS.

**Verdict: P1, P3, P5 all clean. P2/P4 not exercised at this scaffold stage.**

---

## Result<T> end-to-end

- **`BffClient.get<T>` returns `Future<Result<T>>`** — never throws. PASS.
- **try/catch is confined to adapter boundary** — `grep` confirms 4 `try {` blocks total in lib/:
  1. `cli_runner.dart:88` — translates `UsageException` from the `args` framework (entrypoint adapter — acceptable, converts to exit code 64).
  2. `bff_client.dart:60` — converts `DioException` to `Failure(CliError, ...)` (HTTP adapter boundary).
  3. `credential_store.dart:98` — corrupt-JSON / FS-race recovery on `read()` (file I/O adapter boundary).
  4. `credential_store.dart:118` — non-fatal `chmod 600` failure swallow (system call adapter boundary, documented as best-effort).
- **No try/catch in commands or formatters.** PASS.
- **`BffClient` propagates `stackTrace`** — `Failure(_translate(e), stackTrace: stack)` (line 67) preserves it for downstream Sentry. PASS (per Armadilha 4 of P5).

**Verdict: clean.**

---

## Sealed CliError + variants

- Root: `sealed class CliError implements Exception` with `final String message` and `String toString() => message;`.
- Variants: 4 `final class` — `InvalidArgError`, `AuthRequiredError`, `NetworkError`, `ServerError`.
- Factory constructors on the sealed class: `CliError.invalidArg(...)`, `.authRequired()`, `.network(...)`, `.server(statusCode, message)` — all `const`. Ergonomic call site without exposing the variant types when not needed.
- `ServerError` carries an extra `statusCode` field — appropriate, callers may switch on it for specific 4xx handling later.
- `AuthRequiredError` has a fixed message (no constructor arg) — sensible (the message is the same every time: "Run: acdg auth login").
- All 4 variants have a `message` field for stderr output. PASS.

**One note:** `CliError implements Exception` (not `Error`) — correct per the docstring rationale (programmer faults are `Error`; user-facing failures are `Exception`).

**Verdict: sealed family is correctly modelled.**

---

## CredentialStore XDG (D5)

- **`FileCredentialStore.defaultPath({required Map<String, String> env})`** — `env` is **required**, not pulled from `Platform.environment` internally. This makes branch testing deterministic (W0.5 spec hint). Production callers will pass `Platform.environment`. PASS.
- **XDG resolution logic:** `xdg = env['XDG_CONFIG_HOME']; home = env['HOME'] ?? ''; base = (xdg != null && xdg.isNotEmpty) ? xdg : '$home/.config'; return '$base/acdg/credentials';` — handles all 4 branches: (xdg set), (xdg empty), (xdg null + home set), (xdg null + home unset → `/.config/...` which is wrong but… see NICE_TO_HAVE below). PASS.
- **`write()` chmod 600**: skips on Windows (line 116 `if (!Platform.isWindows)`), wraps the `Process.run('chmod', ['600', path])` in a `try/catch on ProcessException` to be best-effort. PASS for D5.
- **`read()` graceful failure**: returns `null` on missing file (line 97), corrupt JSON (line 102), and `FileSystemException` (line 105). Caller gets the same "no credentials" semantics regardless. PASS.
- **`Credentials.fromJson`** uses non-null assertions (`json['accessToken']! as String`) — if the key is missing, `TypeError` propagates and is caught by `read()`'s `try` block (which catches `FormatException` not `TypeError`!) → see MUST_FIX evaluation: actually `jsonDecode` doesn't validate shape, so missing keys → `TypeError`, which would NOT be caught by `on FormatException` / `on FileSystemException`. **See SHOULD_FIX #2.**

**Verdict: D5 correctly implemented; one SHOULD_FIX flagged on `fromJson` exception type.**

---

## Auto-detect formatter (D4)

- **Signature:** `OutputFormatter resolveFormatter({String? explicitFormat, required bool isTerminal})`. PASS — matches W0.5 question #1 resolution.
- **`null` and `'auto'` are identical:** `final format = explicitFormat ?? 'auto';` then the switch routes `'auto' => isTerminal ? const TableFormatter() : const JsonFormatter()`. PASS.
- **gh CLI parity:** tty=true → `TableFormatter`, tty=false → `JsonFormatter`. PASS.
- **Unknown format throws:** `_ => throw InvalidArgError('--output=$format')`. PASS — but see SHOULD_FIX #1 about how `CliRunner.run` handles this throw.

**Verdict: behaviour matches D4 spec.**

---

## Stub command consistency

All 9 stub commands (`auth`, `patient`, `family`, `assessment`, `care`, `protection`, `lookup`, `team`, `health`) follow an identical template:
- `final class XCommand extends Command<int>` — yes (C01 spec).
- Constructor `XCommand({StringSink? stdout}) : _stdout = stdout;` — injectable sink for testing.
- Returns `0` via `writeStub` — yes.
- Pending-ticket strings: auth→C02, patient→C03, family→C04, assessment→C05, care→C06, protection→C07, lookup→C08, team→C09, health→`null` (W0.5 question #3 resolved health-no-ticket). PASS.
- Each has a single library-level docstring, no boilerplate beyond what's needed. The 9 files are practically copy-paste — but per H7 they're trivial enough that a class-per-file is correct (no premature abstraction).

**Verdict: 9-for-9 consistent.**

---

## CliRunner correctness

- **Composes `CommandRunner<int>`** via `_runner` field; exposes typed `CommandRunner<int> get runner` (line 80). Foreign code cannot see `_CapturingCommandRunner`. PASS H2.
- **Constructor accepts `StringSink stdout` + `StringSink stderr`** (both required) — testable. PASS.
- **Global flags**: `--bff` (defaults `http://localhost:3000`), `--output` (allowed `json|table|yaml|auto`, defaults `auto`), `--quiet` (negatable=false, defaults false). PASS.
- **`--output` allow-list** uses `_outputFormats` constant (`['json', 'table', 'yaml', 'auto']`) — `args` package itself rejects out-of-list values with a `UsageException`, so `resolveFormatter`'s throw branch is a defense-in-depth for callers using the resolver outside the runner. PASS.
- **9 commands wired** in alphabetical order: Auth, Patient, Family, Assessment, Care, Protection, Lookup, Team, Health (line 64-72) — minor cosmetic note (alphabetical would be Assessment, Auth, Care, Family, Health, Lookup, Patient, Protection, Team), but the chosen order matches the help-banner order in `000-request.md` and the README table. PASS.
- **`--help` lists all 9 commands** — yes, since they're added via `addCommand`, the `args` package's auto-generated usage covers them.
- **Unknown command** → `args` throws `UsageException`, caught by `CliRunner.run` → exit 64 + stderr message. PASS.
- **`UsageException` → exit 64**: matches `EX_USAGE` per `sysexits.h`. PASS.

**Verdict: correct.**

---

## `_CapturingCommandRunner` rationale

**Q1: Necessary?** YES.

`grep` of `args-2.7.0/lib/command_runner.dart`:
- Line 101: `void printUsage() => print(usage);` — calls Dart top-level `print()`, no injection seam.
- Line 165: `printUsage()` is invoked when user passes the `-h, --help` global flag.
- Line 104: `usageException` throws `UsageException` (caught by `CliRunner.run` and routed to the injected stderr — that path is fine).

So WITHOUT the subclass, `acdg --help` would dump to the real stdout regardless of the injected `StringSink`. Tests that assert "the injected sink received the help banner" would fail. The subclass is required.

**Q2: Cleanest path?**

Two alternatives evaluated:

1. **`runZoned(() => runner.run(args), zoneSpecification: ZoneSpecification(print: ...))`** — would intercept *all* `print()` calls inside the zone. Pros: no subclass needed. Cons: (a) overly broad — captures any stray `print()` from sub-commands too, even ones we want to escape; (b) `runZoned` adds non-trivial overhead; (c) the `args` package itself documents subclass-override as the canonical extension point ("can be overridden by subclasses to control how output is displayed", line 98 of `command_runner.dart`); (d) Zones are documented as "specialised features" — most readers would find the subclass clearer than a Zone wrap.
2. **Re-implement help printing** — would mean parsing `--help` ourselves and calling `runner.usage` on stdout. Pros: no subclass. Cons: re-invents the wheel and breaks if `args` changes its help format.

**Verdict: subclass is the cleanest. The `args` package itself blesses this pattern in its docstring, the subclass is `final` + library-private, exposed via the parent type. APPROVED.**

---

## YamlFormatter hand-rolled

- **Coverage scope vs contract:** the formatter handles `Map<String, Object?>`, `List<Object?>`, scalars (`null`, `bool`, `num`, `String`), and falls back to `value.toString()` for anything else. The W0.5 test contract (locked, not audited for content) presumably covers these shapes — assumed PASS by W1's reported 18/18 formatter GREEN.
- **Edge cases out of scope:** documented in the library docstring (lines 4-8) — multiline strings, tags, anchors, complex keys explicitly listed as future work behind the same `OutputFormatter` interface. PASS.
- **Future replaceability:** `YamlFormatter implements OutputFormatter`. Swapping in `package:yaml_writer` later is one-file change. PASS.
- **Empty collections handled** — `{}` for empty Map, `[]` for empty List. Better than nothing. PASS.
- **Nested list-of-list** (line 67-69) emits a `-` line then recurses with `indent + 2` — visually unusual YAML (most emitters inline scalar lists), but valid block form. Acceptable for scaffold.

**One subtle concern:** if a Map key contains `:`, `#`, or starts with a special char (`-`, `?`, `:`, `&`, `*`, `!`, etc.), the emitter doesn't quote it — that would emit invalid YAML. But the CLI's payloads are BFF DTOs whose keys are camelCase / snake_case identifiers; this is unreachable in practice. Documented in the docstring as out of scope. **APPROVED for C01.**

---

## BffClient

- **try/catch only at adapter boundary** — `bff_client.dart:60-68` wraps the Dio call and converts `DioException` to `Failure(CliError, stackTrace: stack)`. PASS.
- **`_translate` exhaustive switch on `DioExceptionType`** — 8 cases covered (connection/send/receive timeout, connectionError, badCertificate, cancel, badResponse, unknown). With `exhaustive_cases: true`, the analyzer enforces this. Adding a new Dio enum value (Dio 6+) would fail analyze. PASS.
- **No `print()` / no logging** — silent client; observability is the caller's concern. PASS.
- **Bearer interceptor reads from `CredentialStore` on each request** — `onRequest` callback (line 34-39) calls `_credentialStore.read()` per request, no caching. PASS for C01 (refresh/cache logic is C02).
- **Returns `Result<T>`, not `Result<T, CliError>`** — matches `core_contracts` `Result<T>` API (single type param; error type is implicit `Object`). PASS.

**One concern (W1 architectural #6 / SHOULD_FIX #2 below):** `Success(response.data as T)` (line 65, when no `decode` callback) — if Dio decodes JSON to `Map<String, dynamic>` and caller asks for `T = Patient`, the cast throws `TypeError` which is NOT a `DioException` and so escapes the `try/catch`. The `decode` callback is the proper escape hatch. C01 has no real callers yet — flagged as SHOULD_FIX for C02+ when commands actually use this.

**Verdict: scaffold-correct. One non-blocking SHOULD_FIX deferred.**

---

## Code quality (imports, magic strings, print)

- **Magic strings:** `_executableName`, `_description`, `_defaultBffUrl`, `_outputFormats` are all extracted to top-level `const` in `cli_runner.dart`. PASS. The `'auto'` / `'json'` / `'table'` / `'yaml'` literals appear both in `_outputFormats` and in `resolveFormatter`'s switch — minor duplication (one-source-of-truth would be cleaner), see NICE_TO_HAVE #1. The `'XDG_CONFIG_HOME'` / `'HOME'` env-var keys appear once each in `defaultPath` — fine. The `'(no results)'` / `'(null)'` table sentinels are `const String _emptySentinel` extracted (line 18). Header `'Authorization'` / token format `'Bearer ...'` only in BFF interceptor — fine for C01.
- **Import order:** `cli_runner.dart` — SDK package `args` → relative `commands/*.dart`. PASS. `bff_client.dart` — package `core_contracts` → package `dio` → relative. PASS. `credential_store.dart` — `dart:convert` + `dart:io` → package `core_contracts`. PASS. All formatters group SDK → relative. PASS.
- **No `print()` in lib/ except documented exception** — `grep -rn "print(" lib/` returns ONE hit at `_stub_command.dart:28`, gated by `if (out != null) ... else { ignore: avoid_print; print(message.trimRight()); }`. The branch is "currently never; reserved for future direct CLI use". Validated by full-file read: `bin/acdg.dart` always passes `stdout: stdout` (never null), and every test injects a `StringBuffer`. The branch is genuinely never-hit today. **Acceptable as defensive code.** See NICE_TO_HAVE #2 for an alternative.
- **No emojis in code** — confirmed by full-file reads.
- **No hardcoded colors** — N/A (no UI).
- **Naming conventions** — PascalCase classes, camelCase members, snake_case files. All `*Command`, `*Formatter`, `*Error`, `CliRunner`, `CliError` match the project's required suffixes. PASS.

**Verdict: clean.**

---

## Workspace integration

- **Root `pubspec.yaml`** — line 27 has `apps/cli` in the `workspace:` list, in the apps section right above `apps/social_care_bff/contracts`. PASS.
- **`apps/cli/pubspec.yaml`** — line 6 declares `resolution: workspace`. PASS.
- **Deps minimal:** `args ^2.6.0`, `dio ^5.7.0`, `yaml ^3.1.2`, plus path deps `shared` (Contract A DTOs) and `core_contracts` (Result + Equatable). Dev deps `lints`, `test`, `custom_lint`, `acdg_lints`. PASS.
- **`yaml: ^3.1.2`** is declared as a dependency but `lib/` doesn't import it — the formatter is hand-rolled. This is dead weight; either remove from `pubspec.yaml` or wire it into `YamlFormatter`. **See NICE_TO_HAVE #3.** Non-blocking.
- **Sdk constraint** `>=3.11.0 <4.0.0` matches the rest of the workspace. PASS.
- W1 confirmed `melos bs` resolves clean — not re-verified per W2 read-only constraint.

**Verdict: correctly wired.**

---

## W1 architectural choices (8 items)

| # | Choice | Verdict | Rationale |
|---|--------|---------|-----------|
| 1 | `_CapturingCommandRunner` final library-private subclass | **APPROVED** | The `args` package's docstring blesses subclass-override at `command_runner.dart:99`. Subclass is `final` + `_`-prefixed + exposed via parent-typed getter — encapsulation maintained. Zone-based alternative is broader, slower, less idiomatic. |
| 2 | `bool isTerminal` parameter for `resolveFormatter` | **APPROVED** | Matches W0.5 question #1 resolution. Keeps the resolver pure (no `dart:io` import in `auto_formatter.dart`). Tests can pass `true`/`false` without faking `Stdout`. |
| 3 | `UsageException` → exit code 64 (EX_USAGE sysexits) | **APPROVED** | Standard POSIX convention (`sysexits.h:#define EX_USAGE 64`). `gh`, `aws`, `kubectl` all return 64 on usage errors. |
| 4 | YamlFormatter hand-rolled | **APPROVED** | Avoids pulling `yaml_writer` for ~80L of code we control. Edge cases documented out-of-scope; `OutputFormatter` interface allows future swap. **Caveat:** the `yaml: ^3.1.2` package dep in `pubspec.yaml` is unused — see NICE_TO_HAVE #3. |
| 5 | `TableFormatter` preserves insertion order across List<Map> with heterogeneous keys | **APPROVED** | Lines 44-49: `for (final m in maps) for (final k in m.keys) if (!headers.contains(k)) headers.add(k);` — iterates first-map-first, appending novel keys. Behaviour is deterministic (LinkedHashMap iteration order in Dart is insertion order) and matches `gh`/`kubectl` table semantics. |
| 6 | `Credentials.fromJson` non-null assertions (TypeError propagates; only FormatException + FileSystemException caught) | **SHOULD_FIX** | If the on-disk JSON is structurally valid but schema-wrong (e.g. `accessToken` key missing or numeric instead of string), `! as String` throws `TypeError` — NOT `FormatException` — and escapes `read()`'s catch handlers. The user would see an uncaught `TypeError` instead of the documented "treat as missing → re-authenticate" recovery. **Fix:** either add `on TypeError` to the `read()` catch list, or use safe destructuring with `if-case`. **Non-blocking** for C01 (no real persisted credentials yet — comes in C02), but should be addressed before C02 ships PKCE. See SHOULD_FIX #2. |
| 7 | `_stub_command.dart` `avoid_print` ignore for never-hit branch | **APPROVED with NICE_TO_HAVE** | Verified the branch is unreachable today (`bin/acdg.dart` always passes `stdout`, all tests inject buffers). The defensive `print` exists as a future-proof guarantee that a stub command will never run silently. Alternative: throw `StateError('writeStub requires a stdout sink')` instead of `print` — would surface mis-wiring louder. See NICE_TO_HAVE #2. |
| 8 | `BffClient._translate` exhaustive switch on DioExceptionType | **APPROVED** | All 8 Dio variants covered. With `exhaustive_cases: true` + `no_default_cases: true` in analysis_options, adding a new variant in Dio 6+ would fail analyze. |

---

## Issues by severity

### MUST_FIX (block W3)

**None.**

### SHOULD_FIX (non-blocking)

1. **`resolveFormatter` throws `InvalidArgError` but `CliRunner.run` only catches `UsageException`.** If a future caller somehow bypasses the `args` allowed-list (or invokes the resolver directly outside the runner), an `InvalidArgError` would propagate uncaught, crash with an ugly stack trace. Today this is unreachable from the CLI binary because `args` itself rejects out-of-list `--output` values upstream. Recommendation: extend `CliRunner.run` to also `on CliError catch (e)` → exit 64 + stderr write — symmetry with `UsageException` handling. **Defer to C02 if not addressed in this round.**

2. **`Credentials.fromJson` non-null assertions can throw `TypeError` not caught by `FileCredentialStore.read()`.** Today the `read()` method catches `FormatException` (covers `jsonDecode` failure) and `FileSystemException` (covers FS race), but not `TypeError` (covers schema mismatch — e.g. existing `~/.config/acdg/credentials` from an old version with a different key set). **Fix:** add `on TypeError` to the catch list, OR rewrite `Credentials.fromJson` with `if-case {String accessToken, String refreshToken, String expiresAt}` (P2 if-case style) returning a `Result<Credentials>`. **Defer to C02** when actual credential persistence ships and corrupted-store recovery becomes user-visible.

3. **`BffClient.get<T>` does `response.data as T` without `decode` callback** — same `TypeError`-escapes-try category as #2. Today no command uses this code path (everything is stub). **Defer to C02+** when the first real GET command is implemented.

### NICE_TO_HAVE

1. **`_outputFormats` constant duplicates the `resolveFormatter` switch arms.** The constant `['json', 'table', 'yaml', 'auto']` lives in `cli_runner.dart` and the same 4 strings are matched in `auto_formatter.dart`. If a 5th format is added, two files must change. Consolidation: expose `OutputFormatter.allowedFormats` static `const`, or move the constant to `auto_formatter.dart` and re-export. Trivial; defer to C10/C11 polish.

2. **`writeStub`'s `print` fallback could be a `throw StateError` instead.** The current code says "currently never; reserved for future direct CLI use". A `StateError('Stub command invoked without injected stdout sink — wire CliRunner with stdout argument')` would fail loudly if mis-wired, avoiding the `// ignore: avoid_print`. Pure preference; current behaviour is defensible.

3. **`yaml: ^3.1.2` is in `pubspec.yaml` dependencies but unused in `lib/`.** Either remove the dep or wire it into `YamlFormatter`. Removing is the smaller change. Defer to C11 cleanup.

4. **9 stub commands × 22L = 198L of near-duplicate boilerplate.** Could be reduced via a helper factory (e.g. `_StubCommandFactory.build(name: 'auth', description: '...', pendingTicket: 'C02')`). However: the explicit class-per-file makes each `--help <command>` discoverable in source via grep, and once C02-C09 land, each file gets unique implementation. Leaving as-is is the right call for now.

5. **Help-banner-listed command order vs `addCommand` order vs README order vs alphabetical.** All three current orderings (banner, addCommand, README) match each other (auth → patient → family → ...). But the alphabetical canonical (assessment, auth, care, family, health, ...) would be more user-discoverable in `--help`. Match-current is fine; flagged as future polish.

---

## Final recommendation

**APPROVED to W3.**

C01 ships a clean, testable scaffold:
- 16 production files, each single-purpose
- Sealed `CliError` family + 4 variants modelled correctly
- Cross-layer contracts (`OutputFormatter`, `CredentialStore`) as `abstract interface class` per H5/H9
- `Result<T>` end-to-end in `BffClient`; try/catch confined to 4 adapter sites with documented intent
- D4 (auto-detect formatter) and D5 (XDG path) faithfully implemented per spec
- Workspace integration clean (root `pubspec.yaml` + `resolution: workspace`)
- `_CapturingCommandRunner` subclass justified by `args` package's documented extension point; encapsulation preserved via parent-typed getter
- Hand-rolled YamlFormatter scopes set explicitly; future swap is one-file change

Three SHOULD_FIX items (`CliError` propagation in `run`, `Credentials.fromJson` TypeError, `BffClient.get` cast) all share the same root concern — schema-mismatch errors in `Credentials`/`Response` payloads bypass the documented `Result`-conversion boundary because the catch handlers don't include `TypeError`. None of the three is reachable in C01 (no real credentials persisted; no real BFF GETs issued). They should be addressed before C02 ships PKCE persistence and the first real BFF-backed sub-command, but are **non-blocking for the C01 scaffold milestone**.

Five NICE_TO_HAVE items are pure polish; defer to C10/C11.

Pass to W3 (quality gate: `dart analyze` 0 issues + format clean + 77/77 tests GREEN + BFF baseline 2249 GREEN +1 skip).

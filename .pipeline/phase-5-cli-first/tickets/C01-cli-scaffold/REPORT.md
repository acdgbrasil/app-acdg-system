# C01 — CLI Scaffold (`apps/cli/`) — REPORT

## Status: GREEN
Closed: 2026-05-02

## Pipeline executada (4 waves, 4 dispatches sem rejection rounds)

| Wave | Agent | Resultado |
|------|-------|-----------|
| W0 — Baseline | Bash direct | 2172 GREEN +1 skip confirmado (pós-Onda 1.5) |
| W0.5 — RED | test-writer | 77 RED tests em 21 arquivos |
| W1 — GREEN | flutter-bff-implementer | Scaffold completo; 77 GREEN, AOT compile ok |
| **W2 — Review** | flutter-code-reviewer | **APPROVED Round 1/3** (zero MUST_FIX, 3 SHOULD_FIX deferred a C02) |
| W3 — Quality | flutter-quality-checker | **PASSED** — analyze 0, format clean, 2249 GREEN total, smoke test ok |

## Decisões consolidadas (D1-D5)

| ID | Decisão | Aplicação |
|----|---------|-----------|
| **D1** | Package name `cli` | `apps/cli/pubspec.yaml` `name: cli` |
| **D2** | Workspace global | Root `pubspec.yaml` linha 27 (`apps/cli`); `apps/cli/pubspec.yaml` `resolution: workspace` |
| **D3** | Binary `acdg` | `apps/cli/bin/acdg.dart` entrypoint, AOT compile produz binário `acdg` |
| **D4** | Auto-detect output | `resolveFormatter({String? explicitFormat, required bool isTerminal})`; tty=table, pipe=json |
| **D5** | XDG creds path | `FileCredentialStore.defaultPath()` lê `XDG_CONFIG_HOME` env var, fallback `~/.config/acdg/credentials`, chmod 600 |

## Files

### Produção (criados — 16 arquivos)

```
apps/cli/
├── bin/
│   └── acdg.dart                              (15L)
├── lib/
│   ├── cli.dart                               (17L barrel)
│   └── src/
│       ├── cli_runner.dart                    (116L)
│       ├── errors/
│       │   └── cli_error.dart                 (57L — sealed + 4 final variants)
│       ├── formatters/
│       │   ├── output_formatter.dart          (22L abstract interface class)
│       │   ├── json_formatter.dart            (15L)
│       │   ├── table_formatter.dart           (96L ASCII renderer)
│       │   ├── yaml_formatter.dart            (78L hand-rolled)
│       │   └── auto_formatter.dart            (33L)
│       ├── session/
│       │   ├── credential_store.dart          (132L Credentials + interface + FileImpl)
│       │   └── bff_client.dart                (87L Dio wrapper + Result)
│       └── commands/
│           ├── _stub_command.dart             (28L shared helper)
│           ├── auth_command.dart              (~22L stub → C02)
│           ├── patient_command.dart           (~22L stub → C03)
│           ├── family_command.dart            (~22L stub → C04)
│           ├── assessment_command.dart        (~22L stub → C05)
│           ├── care_command.dart              (~22L stub → C06)
│           ├── protection_command.dart        (~22L stub → C07)
│           ├── lookup_command.dart            (~22L stub → C08)
│           ├── team_command.dart              (~22L stub → C09)
│           └── health_command.dart            (~22L stub)
├── pubspec.yaml                               (workspace member)
├── analysis_options.yaml                      (custom_lint enabled)
└── README.md                                  (35L minimal — expanded em C11)
```

### Produção (modificado)
- `pubspec.yaml` (root) — `apps/cli` adicionado ao `workspace:` list (linha 27)

### Tests (criados — 21 arquivos, 77 tests)
- `test/cli_runner_test.dart` (5 tests)
- `test/commands/*` (10 arquivos: 9 stubs × 4 tests + helpers = 36 tests)
- `test/formatters/*` (5 arquivos: output 2 + json 4 + table 3 + yaml 2 + auto 7 = 18 tests)
- `test/session/credential_store_test.dart` (8 tests — XDG path resolution + read/write/clear)
- `test/session/bff_client_test.dart` (5 tests — Bearer interceptor + Result)
- `test/errors/cli_error_test.dart` (5 tests — sealed exhaustive switch)

## Padrões aplicados

- **Facade** — `CliRunner` orquestra CommandRunner + IO injection (composição has-a)
- **Strategy** — `OutputFormatter` interface com 4 strategies (Json/Table/Yaml + auto-resolver)
- **Sealed Class** — `CliError` com 4 final variants (P5 enforce: no downcast)
- **Factory Method** — `Credentials.fromJson` + `FileCredentialStore.defaultPath` static factory
- **Adapter** — `BffClient` adapta Dio para Result-returning interface
- **Result<T>** — end-to-end em `BffClient.get<T>()`; try/catch só em adapter boundaries

## ENCAPSULATION_POLICY (H1-H9) honored
- ✅ H1 SRP per file
- ✅ H5 abstract types (`OutputFormatter`, `CredentialStore` são `abstract interface class`)
- ✅ H6 class modifiers (`final` para variants, `sealed` para CliError)
- ✅ H7 Composição over inheritance (CliRunner composes CommandRunner)
- ✅ H9 Cross-layer types como `abstract interface class`

## PATTERN_MATCHING_POLICY (P1-P5) honored
- ✅ P1 Exhaustive switch (`BffClient._translate` cobre todos `DioExceptionType`)
- ✅ P5 No sealed-class downcast (`acdg_lints/no_sealed_class_downcast` enforce)

## Quality gate (W3)

- ✅ `dart analyze apps/cli/lib/ apps/cli/bin/` — 0 errors, 0 warnings, 0 infos
- ✅ `dart format` — clean (21 files, 0 changed)
- ✅ Cross-package non-regression preserved
- ✅ `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg` — produces working binary
- ✅ Smoke tests:
  - `acdg --help` → banner correto com 9 commands + 4 global flags
  - `acdg patient` → exit 0 + stub "Not implemented yet — pending C03"
  - `acdg unknown-command` → exit 64 (EX_USAGE per sysexits)

## Test counts

- Antes C01 (pós-Onda 1.5): 2172 GREEN +1 skip
- Após C01: **2249 GREEN +1 skip** (4 packages: 535 contracts + 1137 web + 500 desktop + **77 cli**)
- Delta: **+77 cli tests**

## Architectural choices APROVADAS (W2)

1. ✅ `_CapturingCommandRunner` final library-private subclass — necessário porque `args 2.7.0` `CommandRunner.printUsage()` chama `print()` direto. Subclass-override é canonical extension point per docstring. Cleaner que `runZoned`.
2. ✅ `bool isTerminal` em `resolveFormatter` (W0.5 Q#1) — único caminho pra unit-testar sem `dart:io` couplings.
3. ✅ `UsageException → EX_USAGE=64` (sysexits convention).
4. ✅ `YamlFormatter` hand-rolled — sem nova dep; edge cases out-of-scope documentados; `OutputFormatter` interface permite swap futuro.
5. ✅ `TableFormatter` insertion order — gh CLI parity.
6. 🟡 `Credentials.fromJson` non-null assertions — SHOULD_FIX deferred to C02 (TypeError pode escapar; só `FormatException`/`FileSystemException` catched).
7. ✅ `_stub_command.dart` `avoid_print` ignore — never-hit fallback documentado inline.
8. ✅ `BffClient._translate` exhaustive switch sobre `DioExceptionType` — compiler-checked future enum additions.

## SHOULD_FIX deferidos a C02 (3 itens, mesmo root cause)

Schema-mismatch `TypeError` pode escapar boundaries documentados em 3 sites:
1. `CliRunner.run` só captura `UsageException`
2. `Credentials.fromJson` non-null assertions + `read()` só captura `FormatException`/`FileSystemException`
3. `BffClient.get<T>` cast-to-T após `try/catch on DioException`

**Não bloqueante no scaffold** (sem credentials reais ou BFF calls ainda). Endereçar antes de C02 shipping PKCE persistence.

## NICE_TO_HAVE catalogados

1. `yaml: ^3.1.2` em `pubspec.yaml` é unused (YamlFormatter hand-rolled) — remover ou flag pra uso futuro
2. CLI runner version flag (`--version`) opcional
3. Auto-completion shell scripts (deferred a C11)

## Compromises / REGRA #2 exceptions

**Zero.** 77 tests passaram em first compile (após fix de 2 cosmetic lints). Zero teste modificado, zero impl com try/catch silencioso, zero skips.

## Próximo

**C02 — CLI Auth (PKCE Loopback estilo gh CLI)** — implementar OIDC PKCE Loopback (RFC 8252), credential persistence real (preenchendo `FileCredentialStore` com tokens reais), `acdg auth login/logout/status/refresh` commands. Vai exigir ZITADEL Native client_id no Bitwarden Secret Manager (já flagged como pendência infra).

## Comandos de verificação

```bash
# Analyze
dart analyze apps/cli/lib/ apps/cli/bin/  # No issues found!

# Format
dart format --output=none --set-exit-if-changed apps/cli/lib/ apps/cli/bin/  # exit 0

# Tests
cd apps/cli && dart test  # 77 GREEN

# Cross-package non-regression
cd apps/social_care_bff/contracts && flutter test  # 535 GREEN
cd apps/social_care_bff/web && flutter test         # 1137 GREEN
cd apps/social_care_bff/desktop && flutter test     # 500 GREEN +1 skip

# Compile smoke
dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg
/tmp/acdg --help
/tmp/acdg patient    # exit 0
/tmp/acdg unknown    # exit 64
rm /tmp/acdg
```

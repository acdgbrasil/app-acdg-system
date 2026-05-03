# C01 — CLI Scaffold (`apps/cli/`)

## Onda: 2 | Profile: scaffold | Depende de: C00 (closed)

## Decisões consolidadas (sessão 2026-05-02)

| ID | Decisão |
|----|---------|
| **D1** | Package name: `cli` (not `acdg_cli` — diretório `apps/cli/` é semântico suficiente; consistente com `apps/social_care_bff/`) |
| **D2** | Adicionar `apps/cli` ao `workspace:` global do root `pubspec.yaml` (Padrão B-semântico per ADR-022; promoção a workspace independente fica trivial depois) |
| **D3** | Binário compilado: **`acdg`** (curto, UX estilo `gh`/`aws`/`docker`) |
| **D4** | Default output format: **JSON com auto-detect** — `stdout.hasTerminal` true → `table`; pipe/redirect → `json`. Padrão `gh CLI`. Override explícito via `--output=json|table|yaml` |
| **D5** | Credentials path: **XDG** — `~/.config/acdg/credentials` chmod 600. Resolução via `XDG_CONFIG_HOME` env var com fallback `~/.config/` |

## Escopo

### Criar `apps/cli/` Dart-only package

```
apps/cli/
├── bin/
│   └── acdg.dart                    # entrypoint executável
├── lib/
│   └── src/
│       ├── cli_runner.dart          # CommandRunner principal
│       ├── commands/
│       │   ├── auth_command.dart    # stub
│       │   ├── patient_command.dart # stub
│       │   ├── family_command.dart  # stub
│       │   ├── assessment_command.dart
│       │   ├── care_command.dart
│       │   ├── protection_command.dart
│       │   ├── lookup_command.dart
│       │   ├── team_command.dart
│       │   └── health_command.dart
│       ├── formatters/
│       │   ├── output_formatter.dart  # abstract interface class (H9)
│       │   ├── json_formatter.dart
│       │   ├── table_formatter.dart
│       │   ├── yaml_formatter.dart
│       │   └── auto_formatter.dart   # tty detect → delegates
│       ├── session/
│       │   ├── credential_store.dart  # interface (impl em C02)
│       │   └── bff_client.dart        # Dio wrapper + Bearer interceptor (PKCE em C02)
│       └── errors/
│           └── cli_error.dart        # sealed CliError + exit codes
├── test/
│   ├── cli_runner_test.dart
│   ├── commands/                     # 1 file per stub
│   ├── formatters/
│   ├── session/
│   └── errors/
├── pubspec.yaml                      # name: cli, Dart-only
├── README.md                         # básico (expandido em C11)
└── analysis_options.yaml             # custom_lint enabled
```

### Comportamento mínimo

```bash
$ acdg --help
ACDG CLI — Operate the social care system from the command line.

Usage: acdg <command> [arguments]

Available commands:
  auth         Manage authentication
  patient      Patient registry operations
  family       Family member operations
  assessment   Update assessment forms
  care         Care appointments and intake
  protection   Violations, referrals, placement
  lookup       Lookup tables and approval requests
  team         Team management
  health       Service health probes

Run "acdg <command> --help" for more information about a command.

Global options:
  --bff=<url>         BFF base URL (default: http://localhost:3000)
  --output=<format>   json | table | yaml (default: auto — tty=table, pipe=json)
  --quiet             suppress info logs
  -h, --help          print this usage information
```

Sub-comandos retornam stub: stdout `Not implemented yet — pending C{NN}`, exit code 0.

### Output formatter — auto-detect (D4)

```dart
// auto_formatter.dart simplified
OutputFormatter resolveFormatter({String? explicitFormat, IOSink stdout = stdout}) {
  if (explicitFormat != null) {
    return switch (explicitFormat) {
      'json' => const JsonFormatter(),
      'table' => const TableFormatter(),
      'yaml' => const YamlFormatter(),
      _ => throw CliError.invalidArg('--output=$explicitFormat')
    };
  }
  // Auto: tty → table; pipe/redirect → json
  return stdout.hasTerminal ? const TableFormatter() : const JsonFormatter();
}
```

Tests: cobre tty=true, tty=false, explicit override, invalid format.

### Credential store — XDG (D5)

```dart
abstract interface class CredentialStore {
  Future<Credentials?> read();
  Future<void> write(Credentials credentials);
  Future<void> clear();
}

class FileCredentialStore implements CredentialStore {
  static String defaultPath() {
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    final home = Platform.environment['HOME'] ?? '';
    final base = (xdg != null && xdg.isNotEmpty) ? xdg : '$home/.config';
    return '$base/acdg/credentials';
  }
  // ... read/write/clear with chmod 600
}
```

Para C01 a interface + impl básica (read/write/clear) sem PKCE. Tests cobrem path resolution + permissions.

### BffClient — interface + Bearer interceptor scaffold

```dart
class BffClient {
  BffClient({required this.baseUrl, required this.credentialStore, Dio? dio});

  final String baseUrl;
  final CredentialStore credentialStore;
  late final Dio _dio;

  Future<Result<T, BffError>> get<T>(String path, {T Function(Map<String, dynamic>)? decode}) {
    // Adds Authorization: Bearer <token from credentialStore>
    // Returns Result<T, BffError> — never throws
  }
}
```

Para C01 só estrutura — chamadas reais virão em C03+ via mocks.

### Workspace integration

- Root `pubspec.yaml` ganha `apps/cli` no `workspace:` list
- `apps/cli/pubspec.yaml` declara `resolution: workspace`
- `dart pub get` na raiz resolve tudo

### Deps mínimas (`apps/cli/pubspec.yaml`)

```yaml
name: cli
description: ACDG CLI — operate the social care system from the command line.
version: 0.1.0
publish_to: 'none'

resolution: workspace

environment:
  sdk: ">=3.11.0 <4.0.0"

dependencies:
  args: ^2.6.0
  dio: ^5.7.0
  yaml: ^3.1.2
  shared:
    path: ../social_care_bff/contracts  # DTOs Contract A
  core_contracts:
    path: ../../kernel/contracts

dev_dependencies:
  test: ^1.24.0
  custom_lint: ^0.8.1
  acdg_lints:
    path: ../../kernel/lints
```

## Pipeline (4-wave TDD)

| Wave | Agent | Output |
|------|-------|--------|
| W0 — Baseline | Bash direct | Confirma 2172 GREEN +1 skip baseline |
| W0.5 — RED | `test-writer` | ~30 RED tests (cli_runner, command stubs, formatters, credential store, bff_client interface) |
| W1 — GREEN | `flutter-bff-implementer` | Scaffold completo até GREEN |
| **W2 — REVIEW (mandatory)** | `flutter-code-reviewer` | Audit SRP, public surface, ENCAPSULATION_POLICY H1-H9 |
| W3 — Quality | `flutter-quality-checker` | dart analyze 0 + format clean + test |

## Skill aplicada

`flutter-expert` (Dart-first):
- Result<T> end-to-end
- Imutabilidade (final em models, copyWith onde fizer sentido)
- ENCAPSULATION_POLICY H1-H9 (OutputFormatter como `abstract interface class` H9)
- PATTERN_MATCHING_POLICY P1-P5 (sealed CliError, exhaustive switch sobre Result)
- try/catch SOMENTE em adapters (FileCredentialStore I/O, BffClient HTTP)
- `acdg_lints/no_sealed_class_downcast` enforce

## Critérios de aceitação

- [ ] `dart run --package=cli bin/acdg.dart --help` exibe banner correto
- [ ] `dart run --package=cli bin/acdg.dart <command> --help` para cada sub-comando
- [ ] `dart compile exe apps/cli/bin/acdg.dart -o /tmp/acdg && /tmp/acdg --help` funciona
- [ ] Auto-detect formatter: pipe `acdg patient list | cat` → JSON; tty interativo → table (testado via `IOSink` mock)
- [ ] CredentialStore default path resolve `XDG_CONFIG_HOME` ou `~/.config/acdg/credentials`
- [ ] BffClient interface aceita Bearer (PKCE flow vem em C02)
- [ ] ~30 new tests GREEN
- [ ] `dart analyze apps/cli/lib/` zero issues
- [ ] BFF baseline preservado: 2172 GREEN +1 skip → 2200+ GREEN +1 skip (delta +30 do C01)
- [ ] `melos bs` resolve clean com novo workspace member

## NÃO fazer

- ❌ PKCE Loopback flow → C02
- ❌ Sub-comandos com lógica real → C03–C09
- ❌ Golden snapshot tests → C10
- ❌ README expandido + man pages + autocomplete → C11
- ❌ Release pipeline (multi-OS binaries) → C11

## Status
ready — kickoff aguardando green light final

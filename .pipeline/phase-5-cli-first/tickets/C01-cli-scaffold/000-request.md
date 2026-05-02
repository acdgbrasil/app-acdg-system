# C01 — CLI Scaffold (`apps/cli/`)

## Onda: 2 | Profile: scaffold | Depende de: C00

## Escopo

### Criar `apps/cli/` Dart-only package

```
apps/cli/
  bin/
    acdg.dart                    # entrypoint
  lib/
    src/
      cli_runner.dart            # CommandRunner principal
      commands/                  # 1 file por sub-contract (stubs ainda)
        auth_command.dart
        patient_command.dart
        family_command.dart
        assessment_command.dart
        care_command.dart
        protection_command.dart
        lookup_command.dart
        team_command.dart
        health_command.dart
      formatters/
        output_formatter.dart    # interface
        json_formatter.dart
        table_formatter.dart
      session/
        bff_client.dart          # Dio wrapper + Bearer interceptor
        credential_store.dart    # ~/.config/acdg/credentials abstraction
  test/
    cli_runner_test.dart
    formatters/
    session/
  pubspec.yaml                   # dart-only, deps: args, dio, ansicolor, path
  README.md
  analysis_options.yaml
```

### Comportamento mínimo

```bash
$ acdg --help
ACDG CLI - Operate the social care system from the command line.

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
  --output=<format>   json | table | yaml (default: table)
  --quiet             suppress info logs
  -h, --help          print this usage information
```

Sub-comandos retornam stub `not implemented yet — pending Cnn`.

### Workspace integration

- Adicionar `apps/cli` ao `pubspec.yaml` workspace.
- `melos bs` deve resolver clean.

## Pipeline

W0 (test-writer) → W1 (flutter-bff-implementer) → W2 (flutter-code-reviewer) → W3 (flutter-quality-checker)

## Critérios

- [ ] `dart run apps/cli:acdg --help` exibe banner correto
- [ ] `dart run apps/cli:acdg <command> --help` para cada sub-comando
- [ ] Tests: parsing args + stub responses + global options
- [ ] `dart analyze` zero issues
- [ ] README com instruções de instalação (`dart compile exe bin/acdg.dart -o ~/.local/bin/acdg`)

## Status
pending — blocked by C00

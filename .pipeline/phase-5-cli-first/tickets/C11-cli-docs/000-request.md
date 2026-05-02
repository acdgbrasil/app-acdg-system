# C11 — CLI Docs + Distribution

## Onda: 5 | Profile: documentation | Depende de: C10

## Escopo

### `apps/cli/README.md`
- Instalação (`dart compile exe bin/acdg.dart -o ~/.local/bin/acdg`)
- Quickstart (login → register → list)
- Tabela completa dos ~35 comandos com 1-line description
- Output formats (table | json | yaml)
- Variáveis de ambiente (`ACDG_OIDC_ISSUER`, `ACDG_BFF_URL`, `ACDG_CLI_CLIENT_ID`)
- Troubleshooting comum

### Man page
- `man/acdg.1` (groff format)
- Geração: script `tool/generate_man.dart` que parsea `--help` e formata

### Autocomplete

Bash:
```bash
# apps/cli/completions/acdg.bash
_acdg_completion() { ... }
complete -F _acdg_completion acdg
```

Zsh:
```zsh
# apps/cli/completions/_acdg
#compdef acdg
...
```

### Release artifacts (CI)

GitHub Actions matrix builda binários:
- `acdg-macos-arm64`
- `acdg-macos-x64`
- `acdg-linux-x64`
- `acdg-windows-x64.exe`

Anexa a release tag com SemVer.

### Versioning

- `apps/cli/pubspec.yaml` `version: 0.1.0`
- Bump via Melos `melos version --scope=acdg_cli` (semantic-release via Conventional Commits)

## Pipeline

Sem TDD — docs apenas. Review manual + smoke tests.

## Critérios

- [ ] README completo
- [ ] Man page generated automatically
- [ ] Autocomplete bash + zsh tested em macOS + Linux
- [ ] CI release pipeline funcional (1 release teste)

## Status
pending — blocked by C10

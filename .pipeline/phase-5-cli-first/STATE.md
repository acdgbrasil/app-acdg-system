# Pipeline State: phase-5-cli-first

## Current Phase
phase: ready
agent: —
status: scaffold criado 2026-05-01 — aguarda kickoff de C00. **Phase 4 (flutter-migration) marcada superseded — ver `.pipeline/phase-4-flutter-migration/STATE.md`.**

## Decisão estratégica (2026-05-01)

> "BFF Contract A é o que dita regra de negócio. Antes de UI nova, garantir que TODA funcionalidade está acessível via CLI Dart puro consumindo o BFF Web HTTP. Isso prova Contract A end-to-end e dá um cliente automatizável (estilo gh, Gemini CLI, Claude Code) antes de investir em UX."

### Decisões consolidadas

| ID | Decisão | Escolha |
|----|---------|---------|
| **D1** | Escopo do delete | **D1.C** — `social_care` + `people_admin` + `design_system` + `auth` + `apps/acdg_system` (executado 2026-05-01 commit `33626f0`) |
| **D2** | Como o CLI conversa com o BFF | **D2.B HTTP** — `dart run bff/social_care_web/bin/server.dart` em background, CLI bate via Dio |
| **D3** | Auth no CLI | **D3.C γ híbrido** — BFF aceita ambos cookie (browser) e Bearer (CLI). CLI faz OIDC PKCE + Loopback (RFC 8252) direto no Zitadel |

### Padrão D3.C γ — PKCE Loopback (estilo gh CLI)

```
1. CLI gera code_verifier + code_challenge (S256)
2. CLI inicia HttpServer em 127.0.0.1:<porta_random>
3. CLI abre browser do sistema (open/xdg-open/start) na URL:
   <issuer>/oauth/v2/authorize?client_id=<native>&
     redirect_uri=http://127.0.0.1:<porta>/callback&
     code_challenge=<challenge>&code_challenge_method=S256&
     state=<csrf>&scope=openid profile offline_access
4. User autentica no Zitadel
5. Zitadel redireciona pra http://127.0.0.1:<porta>/callback?code=X&state=Y
6. HttpServer captura, valida state, fecha
7. CLI POST /oauth/v2/token com code_verifier → tokens
8. Tokens salvos em ~/.config/acdg/credentials (chmod 600)
9. Refresh automático quando access token expira
```

**No BFF Web (C00):** novo `bearer_auth_middleware` aceita `Authorization: Bearer <jwt>`, valida JWT contra Zitadel JWKS, popula session-equivalent context (paralelo ao session cookie middleware existente). Cookie path continua intocado pra browsers futuros.

## Pipeline TDD (3-agent flow, igual Phase 3 BFF)

| Wave | Agent | Output |
|------|-------|--------|
| **W0 — RED** | `test-writer` | Tests RED descrevendo contrato esperado |
| **W1 — GREEN** | `flutter-bff-implementer` | Implementação até GREEN (skill `flutter-expert` é Dart-first, aplica 1:1 a CLI Dart puro) |
| **W2 — REVIEW** | `flutter-code-reviewer` | Audit read-only (max 3 rounds, escala se rejeitar) |
| **W3 — QUALITY** | `flutter-quality-checker` | `dart analyze` zero issues + `dart format` + `dart test` GREEN |

## Tickets

### Onda 1 — Auth foundation (1 ticket)
- [ ] **C00 — bearer-auth-middleware-bff** — middleware no BFF Web aceitando `Authorization: Bearer`; validação JWT contra JWKS Zitadel; coexiste com session cookie

### Onda 2 — CLI scaffold + auth (2 tickets)
- [ ] **C01 — cli-scaffold** — `apps/cli/` Dart puro, `args` parser, `acdg --help`, struct de commands
- [ ] **C02 — cli-auth-pkce-loopback** — `acdg auth login/status/logout/refresh`, OIDC PKCE + Loopback, file-based credential store

### Onda 3 — Read commands (4 tickets — leitura primeiro pra validar Bearer + parsing)
- [ ] **C03 — cli-patient** (leitura: list, get, audit-trail; depois escrita: register, admit, discharge, readmit, withdraw)
- [ ] **C04 — cli-family** (add, remove, assign-caregiver, update-identity)
- [ ] **C05 — cli-assessment** (7 fichas: housing, socioeconomic, work-income, education, health, community-support, social-health-summary)

### Onda 4 — Write commands (4 tickets)
- [ ] **C06 — cli-care** (appointment, intake)
- [ ] **C07 — cli-protection** (violation, referral, placement-history)
- [ ] **C08 — cli-lookup** (8 endpoints + batch + requests)
- [ ] **C09 — cli-team** (9 endpoints, sem `/people/by-cpf` etc)

### Onda 5 — Polish (2 tickets)
- [ ] **C10 — cli-golden-tests** — snapshot tests dos ~35 comandos contra fixtures BFF
- [ ] **C11 — cli-docs** — README + man pages + autocomplete bash/zsh

## Layout target

```
apps/cli/
  bin/
    acdg.dart                    # entrypoint
  lib/
    src/
      commands/                  # 1 command por sub-contract
        auth_command.dart
        patient_command.dart
        family_command.dart
        assessment_command.dart
        care_command.dart
        protection_command.dart
        lookup_command.dart
        team_command.dart
      formatters/                # JSON / table / yaml output
      session/                   # PKCE flow + credential storage
  test/
    commands/                    # unit + golden
    integration/                 # CLI → BFF Web HTTP end-to-end
  pubspec.yaml                   # deps: args, dio, oidc/openid_client, ansicolor
```

Comandos no estilo `git`/`gh`:
```bash
acdg auth login
acdg patient register --cpf=12345678900 --first-name=Maria --address-cep=01310100
acdg patient list --search=maria --limit=20
acdg family add --patient-id=<uuid> --member-cpf=...
acdg assessment housing --patient-id=<uuid> --rooms=3 --type=alvenaria
acdg lookup get sex
acdg team list --role=social_worker
```

## What's preserved post-D1.C

```
bff/{shared,social_care_web,social_care_desktop}/  ← Phase 3 sagrada
packages/{core,core_contracts,network,persistence,acdg_lints}/
handbook/, contracts/, .pipeline/, .claude/, scripts/site-entrypoint.sh
melos.yaml, pubspec.yaml (workspace 8 entries)
```

## What's deleted (commit `33626f0`)

- `packages/social_care/` (13 features, ~300 dart files)
- `packages/people_admin/` (team feature, ~50 dart files)
- `packages/design_system/` (atomic design tokens + widgets)
- `packages/auth/` (Flutter-bound OIDC service)
- `apps/acdg_system/` (shell Flutter completo)
- `scripts/generate_env.dart`
- `.github/workflows/{conecta_web_image,windows_build_msix}.yml`

Total: 697 arquivos, -60367 LoC.

## Mindset

- **CLI antes de UI.** UX é facilmente dispensável; lógica de negócio não.
- **Contract A é canon.** CLI consome via HTTP; se não dá pra fazer via CLI, não dá pra fazer.
- **TDD agente-driven.** Mesma pipeline 3-agent que produziu Phase 3 sem rejeição em Round 1.
- **Phase 6 (UI) virá depois** — provavelmente Flutter Web/Desktop com Atomic Design re-aplicado, consumindo o mesmo Contract A que o CLI prova.

## Blockers
(none)

## Context for Resume
Last action: scaffold criado 2026-05-01 imediatamente após commits `61d032c` (Phase 3 close) + `33626f0` (D1.C delete).
Next action: kickoff C00 — Bearer middleware no BFF Web. Pipeline 3-agent (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker).

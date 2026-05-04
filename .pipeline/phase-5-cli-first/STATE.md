# Pipeline State: phase-5-cli-first

## Current Phase
phase: in-progress (C06 closed; **C07 next** — cli-protection)
agent: —
status: **C00 + D01 + D02 + D03 + C01 + C02 + C03 closed 2026-05-04**. C02 pushed em `6cf1b80` + smoke-tested contra Zitadel real. C03 closed via pipeline 4-wave (W0 78 RED → W1 219 GREEN → W2 REJECTED Round 1 com 1 MUST_FIX (`event_type`→`eventType` casing bug) + 4 SHOULD_FIX → fixes aplicados (M1+S1+S2) → W3 PASSED). 8 comandos `acdg patient ...` operacionais. **219 GREEN no apps/cli** (era 145, +74). dart analyze zero issues. AOT compila. `BffClient.post<T>` adicionado com retry-once invariant compartilhado com `get<T>`. Workspace reachable: **1891 GREEN** (cli + bff/web + bff/contracts; desktop env-blocked não-regressão). Próximo: **C04 — cli-family** (add, remove, assign-caregiver, update-identity).

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
- [x] **C00 — bearer-auth-middleware-bff** — CLOSED 2026-05-02 via 5-wave pipeline (test-writer → auth-auditor → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker). 62 tests GREEN, 2098 GREEN total no BFF, dart analyze zero. 2 rounds de rejection produtivos (W0.5 GAPS_FOUND fechado em W0-bis; W2 R1 REJECTED por security gap real — case-sensitive cookie strip bypass — fechado em W1 R2). 10 security constraints enforced + 3 CVEs cobertas (CVE-2015-9235 alg none, CVE-2016-10555 alg confusion, CVE-2018-0114 kid traversal). Pré-req infra pendente: provisionar `OIDC_CLI_CLIENT_ID` no Bitwarden.

### Onda 1.5 — Refactor débito do Desktop facade (3 tickets) — não bloqueiam C01

`apps/social_care_bff/desktop/lib/src/facade/social_care_desktop.dart` acumulou 718L com 6 responsabilidades (composition root + lifecycle + connectivity + drain pump + helpers + entry class). Análise completa em conversa-sessão 2026-05-02. Padrões GoF aplicados: Factory Method (D01), Builder + Observer (D03). Decorator + Strategy reservados (D6/D7) sem demanda real hoje (Rule of Three). 426 GREEN do Desktop preservados durante todo o refactor.

- [x] **D01 — pump-engine-helpers-factory** — CLOSED 2026-05-02 via 5-wave pipeline (test-writer → fixture-fix → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker). Factory Method GoF aplicado. Facade reduzido 718L → 637L (-81L). 24 new tests GREEN; 2122 GREEN +1 skip total BFF (era 2098, +24). 4 REGRA #2 exceptions documentadas (fixture-fix). W2 APPROVED Round 1/3 zero MUST_FIX.
- [x] **D02 — use-case-builders** — CLOSED 2026-05-02 via 4-wave pipeline (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker). 7 builders criados (610L total) agrupando 42 use cases por bounded context. Facade reduzido 637L → 364L (-273L, -42.9%). Sub-facades reduzidas -129L coletivos. 21 new tests GREEN; 2143 GREEN +1 skip total BFF (era 2122, +21). Spec divergence APPROVED: abstract `XxxContract` em build() signatures vs concrete `XxxRemote` do spec original. W2 mechanical audit confirmou 42/42 use cases byte-identical com legacy. W2 APPROVED Round 1/3 zero MUST_FIX.
- [x] **D03 — assembler-observer** — CLOSED 2026-05-02 commit `b7a53ee`. `DesktopAssembler` (Builder fluente) + `AutoDrainObserver` (Observer GoF, elimina self-reference circular do `_pumpStreamSubscription`). Facade `SocialCareDesktop._()` reduzido de 14 params para 1 (`DesktopRuntime`). Padrões aplicados: Builder + Observer. 426 GREEN do Desktop preservados; 2249 GREEN +1 skip total mantido.

### Onda 2 — CLI scaffold + auth (2 tickets)
- [x] **C01 — cli-scaffold** — CLOSED 2026-05-02 via 4-wave pipeline (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker). 77 GREEN no novo `apps/cli/`; 2249 GREEN +1 skip total (4 packages). Decisões D1-D5 implementadas (package `cli`, workspace global, binário `acdg`, auto-detect output, XDG creds path). 5 padrões aplicados (Facade, Strategy, Sealed Class, Factory Method, Adapter). AOT compile produz binário funcional. W2 APPROVED Round 1/3 zero MUST_FIX, 3 SHOULD_FIX deferidos a C02 (schema-mismatch TypeError em boundaries — não-bloqueante no scaffold).
- [x] **C02 — cli-auth-pkce-loopback** — CLOSED 2026-05-04 via pipeline 4-wave completa (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker). `acdg auth login/status/logout/refresh`, OIDC PKCE + Loopback (RFC 8252) estilo `gh`, file-based credential store via `OidcSession` (Strategy A migration de `Credentials` C01). 145 GREEN no apps/cli (era 77, +68). 9 novos arquivos lib + 7 modificados; 11 novos test files (~68 tests). dart analyze zero issues. AOT compile funcional. Spec source-of-truth: `handbook/spikes/OICD_AUTH_SPIKE.md` v1.0. W2 APPROVED Round 1/3 com 4 SHOULD_FIX (S1 XSS escape no error page; S2 `_RevokeFailure` → CliError family; S3 dead getter `_unusedDiscovery`; S4 barrel exports), todos aplicados antes do W3. Padrões aplicados: PKCE S256, listener loopback defensivo (filtra `_rsc=`, valida state CSRF, drena 204, multi-hit), `prompt=login` mandatory, `client_secret` jamais enviado, `RefreshTokenInvalid` no-retry + exit 7, refresh rotation enforced, JWT decode no CLI sem signature validation (delegada ao BFF Bearer middleware C00).

### Onda 3 — Read commands (4 tickets — leitura primeiro pra validar Bearer + parsing)
- [x] **C03 — cli-patient** — CLOSED 2026-05-04 via pipeline 4-wave (test-writer → flutter-bff-implementer → flutter-code-reviewer REJECTED Round 1 com 1 MUST_FIX → fixes → flutter-quality-checker). 8 comandos `acdg patient {list, get, audit, register, admit, discharge, readmit, withdraw}` operacionais. 219 GREEN no apps/cli (era 145, +74). `BffClient.post<T>` adicionado; `_attempt`/`_refreshAndRetry` generalizados pra GET+POST com retry-once invariant by construction. M1: W0 §4.3 source claim de snake_case `event_type` estava factualmente errado — BFF lê `eventType` (camelCase); CLI flipped pra match. Test permissivo do W0 (`qp['event_type'] ?? qp['eventType']`) mascarou o bug; W2 catch evitou silent semantic drop em produção. Decisões: DTO-faithful body shapes (discharge sem timestamp, readmit só notes, withdraw reason REQUIRED conforme DTOs); cursor surfacing em stderr; `--from-yaml` com reader injetado; `_buildBffClient` ainda sem refresh-on-401 wiring (deferido a C04). Patterns: Sealed sum types via `_Attempt<T>` (encoda retry-once invariant), DTO-as-canon (W0 §4.1).
- [x] **C04 — cli-family** — CLOSED 2026-05-04 via pipeline 4-wave (W0 57 RED → W1 277 GREEN → W2 APPROVED Round 1 com 0 MUST_FIX + 4 SHOULD_FIX defer-to-future → W3 PASSED). 4 verbs operacionais: `add` (POST `/patients/<id>/family-members`), `remove` (DELETE), `assign-caregiver` (PUT `/primary-caregiver`), `update-identity` (PUT `/social-identity`). BffClient extendido com `put<T>` + `delete<T>` reusando `_attempt`/`_refreshAndRetry` C03 (knob `method` já genérico). Helper renomeado `_patient_helpers.dart` → `_command_helpers.dart` (byte-identical) + 8 patient imports atualizados. DTO-as-canon adherence: ticket prose pedia `--gender --pronoun` mas DTO `UpdateSocialIdentityRequest` é `{typeId, description?}` — CLI segue DTO (lição C03 W2 M1 aplicada com sucesso). Wire format cross-checked vs 4 BFF intents — zero surpresas de casing. 277 GREEN no apps/cli (era 219, +58); 1949 GREEN reachable workspace.
- [x] **C05 — cli-assessment** — CLOSED 2026-05-04 via pipeline 4-wave (W0 91 RED → W1 378 GREEN → W2 APPROVED Round 1 com 0 MUST_FIX → W3 PASSED). 7 fichas operacionais (todas PUT idempotentes): `housing` (15 fields), `socioeconomic` (5 + nested `socialBenefits[]`), `work-income` (1 + nested via yaml), `education` (4-flag all-or-nothing OR yaml), `health` (1 + multi `--constant-care-need`), `community-support` (7 fields incluindo `familyConflicts` String), `social-health-summary` (3 + multi `--functional-dependency`). 378 GREEN no apps/cli (era 277, +101); 2050 GREEN reachable workspace (Δ +101 vs C04 baseline 1949). Test factory `_assessment_test_helpers.dart::runAssessmentCommandContract` extraído pra reduzir 11 cross-cutting tests × 7 fichas = 77 boilerplate. **`_yaml_helpers.dart` extraído** (`yamlToJsonNode`/`yamlToJsonMap`/`readYamlBody`) com migração de `patient_register_command.dart` inclusa — byte-equivalent. Wire format DTO-as-canon: ZERO surpresas de casing (lição C03 M1 + C04 aplicada com sucesso). `BffClient` reuse: `put<T>` C04 cobre 7 fichas sem mudança HTTP infra.

### Onda 4 — Write commands (4 tickets)
- [x] **C06 — cli-care** — CLOSED 2026-05-04 via pipeline 4-wave (W0 31 RED → W1 405 GREEN → W2 APPROVED Round 1 com 0 MUST_FIX + 0 SHOULD_FIX → W3 PASSED). 2 commands operacionais: `appointment` (POST `/patients/<id>/appointments` + decode `StandardIdResponse` + print `Created appointment <id>`) e `intake` (PUT `/patients/<id>/intake`, void). 405 GREEN no apps/cli (era 378, +27); 2077 GREEN reachable workspace (Δ +27). **Novo pattern: StandardIdResponse decode + print** — primeiro endpoint write que retorna ID generated. CLI usa `bffClient.post<String?>(...)` com decode callback walking `data['data']['id']` 3-guard defensive null. Wire format DTO-as-canon (3ª aplicação consecutiva da lição C03 M1): ticket pedia `--reason --intake-at [--notes]` mas DTO é `{ingressTypeId, serviceReason, originName?, originContact?, linkedSocialPrograms?[]}`. CLI segue DTO. ZERO surpresas de casing.
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
Last action: 2026-05-04 — C03 fechado. Pipeline 4-wave (W0 78 RED → W1 219 GREEN → W2 REJECTED Round 1 → fixes M1+S1+S2 → W3 PASSED). 4 reports persistidos em `.pipeline/phase-5-cli-first/tickets/C03-cli-patient/{002-tests,003-impl,004-code-review,005-quality}/`. C02 commit `6cf1b80` já em origin/dev; C03 commit pendente (próximo passo do orchestrator).

Débitos abertos pra C04+:
- **`BffClient` runner-level refresh-on-401**: hoje patient verbs surfacem `AuthRequiredError` em 401 e exigem `acdg auth refresh` manual. Implementar `BffClientFactory` com discovery cache + tokenClient lazy.
- **`--bff` global flag**: parsed mas ignorado (`_buildBffClient` hardcoda `_defaultBffUrl`). Pre-C03 debt.
- **`--output` global flag resolver (C10)**: hoje `JsonFormatter` é hardcoded; resolver lê flag.
- **`formatter` field unused** nas 4 lifecycle commands (admit/discharge/readmit/withdraw retornam 204 No Content): drop quando C10 introduzir resolver runner-level.

Next action: kickoff **C07 — cli-protection** (violation, referral, placement-history). Pré-req: `BffClient` cobre todos os 4 verbs; `_command_helpers.dart` + `_yaml_helpers.dart` disponíveis. `StandardIdResponse` decode pattern estabelecido no C06 (eventualmente extrair pra helper se C07/C08 tiverem outros endpoints com generated ID). Protection sub-contract em `apps/social_care_bff/contracts/lib/src/contract/sub_contracts/protection_contract.dart`. Pipeline 4-wave igual.

Requirements não-negociáveis para o W0 (extraídos da spike §3-§5):
- LoopbackListener defensivo: filtra `_rsc=`, valida `state==expected`, drena 204 silencioso, hard timeout 5min, bind em porta efêmera (`InternetAddress.loopbackIPv4, 0`), NUNCA loga query string completa.
- Authorize URL com `prompt=login` (defesa contra cookie residual + RSC prefetch do Next.js).
- PKCE S256 only (sem fallback `plain`); verifier 64 random bytes b64url no-pad.
- `aud.contains(PROJECT_ID)` — nunca `==` (vem com 9 entries).
- `azp` NÃO existe no access_token (só id_token) — não validar lá.
- `email`/profile NÃO viajam no access_token — buscar via `/userinfo` no primeiro login.
- Refresh `invalid_grant: RefreshTokenInvalid` ⇒ SEM retry; clear sessão; exit 7; força `acdg auth login`.
- Discovery dinâmico no boot — fetch `.well-known`, valida `issuer == OIDC_ISSUER`, cacheia.
- Tokens em `~/.config/acdg/credentials` chmod 600 (já existe `FileCredentialStore` do C01 — estender pra `OidcSession` com idToken + sub + email + roles + accessExpiresAt).

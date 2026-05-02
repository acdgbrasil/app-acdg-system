# Processo — frontend (Conecta Raros)

> Acordos operacionais, fluxo de trabalho e convencoes de desenvolvimento.
>
> **Atualizado 2026-05-01** — pos-D1.C/ADR-022. Workflow ajustado para CLI-first (Phase 5) + multi-app monorepo. Etapas relativas a Flutter UI ficam reservadas para Phase 6+ quando UI for ressuscitada.

---

## 1. Fluxo de Trabalho

### 1.1 Branch Convention

Padrao ACDG:

```
feat/<issue-id>-<slug>    # Nova funcionalidade
fix/<issue-id>-<slug>     # Correcao de bug
chore/<issue-id>-<slug>   # Manutencao, refactor
docs/<issue-id>-<slug>    # Documentacao
refactor/<issue-id>-<slug>
test/<issue-id>-<slug>
```

### 1.2 Commit Convention

Conventional Commits (ver [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md)):

```
feat: add patient register CLI command
fix: correct PKCE code_verifier generation in cli auth
chore: update Dio to 5.x in apps/social_care_bff/desktop
docs: update MONOREPO_LAYOUT after ADR-022
refactor: extract bearer middleware out of session middleware
test: add golden tests for cli patient list
```

Breaking changes recebem `!` ou `BREAKING CHANGE:` no body.

### 1.3 PR Flow

1. Abrir issue antes de codar
2. Criar branch a partir de `dev` (ou `main` para hotfix em prod)
3. Desenvolver com testes (TDD obrigatorio em BFF e CLI — pipeline 4-agent)
4. Abrir PR com contexto, riscos e evidencias de teste
5. Review obrigatorio (minimo 1 humano + flutter-code-reviewer agent)
6. CI deve passar (`melos run analyze`, `melos run test`, build)
7. Merge via squash

### 1.4 Definition of Done

#### BFF (apps/social_care_bff/*)
- [ ] Tests passing (suite completa: 535 contracts + 1075 web + 426 desktop atual baseline)
- [ ] `dart analyze` zero errors em src/ (infos toleradas com listagem em REPORT.md)
- [ ] `dart format --set-exit-if-changed` clean
- [ ] Sub-contract correto consumido (nao god-interface)
- [ ] Result<T> end-to-end (try/catch so em adapter boundary)
- [ ] StandardResponse<T> wrapping com meta.timestamp
- [ ] Error codes seguem convencao (`INVALID_*` 400 vs `<PREFIX>-<NNN>` passthrough)
- [ ] UUID path params validados via `validateUuidPathParam`
- [ ] Cascade DI ordem canonica respeitada
- [ ] ENCAPSULATION_POLICY H1-H9 + PATTERN_MATCHING_POLICY P1-P5 enforce
- [ ] No sealed-class downcast (enforce via `acdg_lints`)

#### CLI (apps/cli/ — Phase 5)
- [ ] Tests passing (unit + golden snapshots)
- [ ] `dart analyze` zero issues
- [ ] Output formatters cobrem table/json/yaml
- [ ] BFF responses parse corretamente (incluindo BackendErrorResponse)
- [ ] PKCE Loopback flow honra RFC 8252
- [ ] Credentials file chmod 600
- [ ] Sem segredos hardcoded

#### Cross-cutting
- [ ] Documentacao atualizada se mudou comportamento
- [ ] Compatibilidade retroativa avaliada (commits `feat!` quando quebra)
- [ ] **Handbook atualizado** se mudou fato canonico (ver [../principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md](../principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md))

---

## 2. Versionamento

### 2.1 Packages

Cada package tem versao independente seguindo SemVer:
- `MAJOR` — breaking changes na API publica
- `MINOR` — funcionalidade nova, retrocompativel
- `PATCH` — bug fix

### 2.2 Apps

Cada app em `apps/<name>/` tem versionamento proprio:
- `apps/social_care_bff/web` — `vX.Y.Z` da imagem GHCR
- `apps/social_care_bff/desktop` — `vX.Y.Z` do package consumido
- `apps/cli` — `vX.Y.Z` dos binarios distribuidos (release pipeline em C11)

Tags git seguem padrao: `<app>-vX.Y.Z` (ex: `social_care_bff-web-v1.2.0`, `acdg_cli-v0.1.0`).

---

## 3. Pipeline TDD 4-agent (BFF + CLI)

Para qualquer trabalho nao-trivial em `apps/social_care_bff/*` ou `apps/cli/`:

| Wave | Agent | Output |
|------|-------|--------|
| **W0 — RED** | test-writer | Tests falhando descrevendo contrato esperado |
| **W1 — GREEN** | flutter-bff-implementer | Implementacao ate GREEN; nao toca em tests |
| **W2 — REVIEW** | flutter-code-reviewer | Audit read-only contra Non-Negotiable Rules; max 3 rounds |
| **W3 — QUALITY** | flutter-quality-checker | `dart analyze` zero + `dart format` + `dart test` GREEN |

**Excessoes:**
- Trabalho em `kernel/` ou `infra/` requer pipeline targeted (a definir caso-a-caso).
- Pure research/exploration/audits read-only sao isentos.
- Hot fix com permissao explicita do usuario pode pular W0.

---

## 4. Fluxo de Desenvolvimento por Feature

### Em BFF
```
1. Definir feature no issue tracker (ou ticket .pipeline/)
2. Criar/atualizar sub-contract em apps/social_care_bff/contracts/
3. Criar Intent (parseFromBody/parseFromQuery/parseFromPath)
4. Criar UseCase (orquestracao com sub-contracts via Cascade)
5. Criar Handler (rota Shelf, error mapping, observability middleware)
6. Tests RED -> GREEN -> review -> quality
7. PR + Review + Merge
```

### Em CLI (Phase 5)
```
1. Definir comando no ticket .pipeline/phase-5-cli-first/Cnn-X/
2. Definir args/flags via package:args
3. Implementar Command class (validation client-side minima)
4. Implementar BffClient call (Dio + Bearer auth)
5. Implementar formatters (table/json/yaml)
6. Tests + golden snapshots
7. PR + Review + Merge
```

### Em Future UI Flutter (Phase 6+)
**Reservado** — quando ressuscitada, o ciclo retoma `Model -> Service -> Repository -> UseCase -> ViewModel -> View` (de dentro para fora).

---

## 5. Code Review Checklist

### Cross-cutting
- [ ] Result<T> end-to-end (try/catch so em boundary)
- [ ] Models imutaveis (final em tudo, copyWith)
- [ ] Sem logica de negocio fora do BFF
- [ ] Imports organizados (SDK -> external -> internal -> relative)
- [ ] Nomenclatura correta (sufixos: *Handler, *Intent, *UseCase, *Command, *Formatter, etc.)
- [ ] Sem segredos hardcoded
- [ ] **Handbook atualizado** se fato canonico mudou

### BFF-specific
- [ ] Sub-contract correto (nao god-interface)
- [ ] StandardResponse<T> com meta.timestamp
- [ ] Error codes seguem convencao
- [ ] UUID validation via `validateUuidPathParam`
- [ ] Cascade DI ordem canonica
- [ ] No sealed-class downcast

### CLI-specific (Phase 5)
- [ ] Output formatter cobre todos os 3 formats
- [ ] Error mapping de BackendErrorResponse correto
- [ ] PKCE flow valida state CSRF
- [ ] Credentials file chmod 600
- [ ] Comando segue padrao `<noun> <verb>`

---

## 6. Auditoria de handbook

Sempre que terminar uma fase grande:
1. `grep -rn "padrao_obsoleto" handbook/{architecture,principles,process,codebase,tooling,quality,cicd}` para achar refs obsoletas em **docs vivos**.
2. **NAO atualizar docs historicos** — `handbook/{chat,audit,missions,reports,research,social_care_implementation,web-migration,implementation_plans}/` preservam estado de uma epoca.
3. Atualizar docs vivos com fato novo + nota de timestamp.
4. Decisao nova vai para ADR em `architecture/DECISIONS.md`.

Ver [../principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md](../principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md) para procedimento completo.

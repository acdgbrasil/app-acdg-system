# `.claude/` — Index canonico

> **Status (2026-05-04):** Phase 5 CLI-first. BFF Phase 3 SAGRADA (2036 testes GREEN).
> UI Flutter REMOVIDA em D1.C (commit 33626f0) — agentes/skills UI estao DORMENTES.
>
> **Layout monorepo:** `kernel/` (Dart-pure) + `infra/` (Flutter-coupled) + `apps/` (entregaveis).
> Vide ADR-022 e `handbook/architecture/MONOREPO_LAYOUT.md`.

---

## Agents (`.claude/agents/`)

### Pipeline ATIVO (BFF + CLI) — 4 agents

Pipeline 4-wave fail-first. Vide `.claude/skills/pipeline-maestro/SKILL.md`.

| Wave | Agent | Papel |
|------|-------|-------|
| W0 — RED   | `test-writer`              | Tests falhando que descrevem contrato |
| W1 — GREEN | `flutter-bff-implementer`  | Implementacao BFF + CLI ate GREEN |
| W2 — REVIEW| `flutter-code-reviewer`    | Audit read-only (max 3 rounds) |
| W3 — QUALITY| `flutter-quality-checker` | `dart analyze` + `dart format` + `dart test` |

Boundary: `apps/social_care_bff/{contracts,web,desktop}/` e `apps/cli/`.

### Suite Seguranca ATIVA — 11 agents

Orquestrada por `security-orchestrator` (executa pipeline completo) ou usados standalone.

| Agent | Skill associada | Papel |
|-------|-----------------|-------|
| `threat-analyst`              | `threat-modeler`              | STRIDE + DFD + DREAD + OWASP/ASVS |
| `pentest-scanner`             | `red-team-scanner`            | RED Team ofensivo, busca exploits |
| `auth-auditor`                | `auth-session-security`       | OIDC, JWT, sessao, RBAC, MFA |
| `api-hardener`                | `api-security-guardian`       | Hardening de endpoints (CORS, rate limit, headers) |
| `pipeline-security-auditor`   | `devsecops-pipeline`          | CI/CD, Docker, deps, secrets |
| `secure-code-reviewer`        | `appsec-code-reviewer`        | Code review defensivo (10 dims) |
| `llm-ai-auditor`              | `llm-ai-security`             | OWASP LLM Top 10, prompt injection, RAG |
| `secure-boilerplate-generator`| `secure-boilerplate-generator`| Scaffolds que ja nascem seguros |
| `security-test-writer`        | `security-test-generator`     | Testes de regressao de vulnerabilidades |
| `vulnerability-fixer`         | `vulnerability-fixer`         | Patch + teste + PR description |
| `security-orchestrator`       | (orquestrador)                | Coordena todos os 6 da Phase 1-2 |

### RESERVADOS Phase 6+ — 7 agents (UI Flutter)

> **NAO INVOCAR HOJE.** Esses agentes esperam paths que foram deletados em D1.C
> (`packages/social_care/`, `packages/design_system/`, `apps/acdg_system/`,
> `domain/models/`, `data/services/`, `ui/<feature>/`). Voltam ao escopo quando UI
> Flutter ressuscitar (Phase 6+ apos Phase 5 CLI estabilizar).

| Agent | Camada (futura) |
|-------|-----------------|
| `domain-architect`              | Design de contratos antes do pipeline |
| `flutter-domain-modeler`        | Domain models + API models |
| `flutter-infra-implementer`     | Services + Repositories + Mappers |
| `flutter-usecase-orchestrator`  | UseCases (BaseUseCase + Result<T>) |
| `flutter-viewmodel-engineer`    | ViewModels (ChangeNotifier + Command) |
| `flutter-view-implementer`      | Pages/Organisms/Molecules/Atoms |
| `flutter-integration-validator` | Validacao agregada (substituido hoje pelo flutter-quality-checker) |

---

## Skills (`.claude/skills/`)

### Active core (3)

| Skill | Quando usar |
|-------|-------------|
| `flutter-expert`     | Padroes Dart/Flutter (Result, imutabilidade, Drift, Encapsulation/Pattern Matching policies). Modo BFF+CLI ATIVO; modo UI Flutter RESERVADO Phase 6+. |
| `pipeline-maestro`   | Orquestrar pipeline 4-wave BFF/CLI (ou descrever feature end-to-end). |
| `cli-craftsman`      | Design de CLI (10 pilares cli-guidelines.org) — Phase 5 ativa. |

### Dart official (12) — referencia canonica

`dart-add-unit-test`, `dart-build-cli-app`, `dart-collect-coverage`,
`dart-fix-runtime-errors`, `dart-fix-static-analysis-errors`,
`dart-generate-test-mocks`, `dart-migrate-to-checks-package`,
`dart-resolve-package-conflicts`, `dart-run-static-analysis`,
`dart-use-pattern-matching`.

### Suite Seguranca (10)

`threat-modeler`, `red-team-scanner`, `auth-session-security`,
`api-security-guardian`, `devsecops-pipeline`, `appsec-code-reviewer`,
`llm-ai-security`, `secure-boilerplate-generator`,
`security-test-generator`, `vulnerability-fixer`.

### User-invocable (1)

`kodus-review` — slash command `/kodus-review` para rodar Kodus AI localmente sem PR.

### Dormant (1)

`vibe-designer` — RESERVADO Phase 6+ (UI Flutter). Skill ja se auto-declara dormant.

---

## Hooks (`.claude/hooks/`)

| Hook | Quando dispara | Acao |
|------|----------------|------|
| `pre-commit-kodus.sh` | PreToolUse Bash `git commit *` | Roda `kodus review --staged`; bloqueia se houver issues `error`/`critical`. |

---

## Settings

`settings.local.json` — permissoes (allow-list de Bash/MCP) e opcoes locais. Vide
`/update-config` skill para alterar.

---

## Quick lookup — "qual agente eu chamo?"

- **Implementar feature BFF/CLI completa** → `pipeline-maestro` (skill) ou direto na ordem `test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker`.
- **Apenas escrever testes RED** → `test-writer`.
- **Apenas implementar (tests ja existem)** → `flutter-bff-implementer`.
- **Revisar codigo (architecture rules)** → `flutter-code-reviewer`.
- **Revisar codigo (security)** → `secure-code-reviewer`.
- **Encontrar vulnerabilidades** → `pentest-scanner`.
- **Corrigir vulnerabilidade ja achada** → `vulnerability-fixer`.
- **Threat modeling antes de feature nova** → `threat-analyst`.
- **Auditar CI/CD/Docker/deps** → `pipeline-security-auditor`.
- **Auditar fluxo de auth/JWT/OIDC** → `auth-auditor`.
- **Bootstrap de modulo novo seguro-by-default** → `secure-boilerplate-generator`.
- **Code review automatizado pre-commit** → hook `pre-commit-kodus.sh` ja faz.
- **Code review manual sem PR** → `/kodus-review` (slash skill).

---

## Referencias

- `CLAUDE.md` (root frontend) — REGRA #0/1/2 (MCP, handbook, no test cheating).
- `handbook/architecture/MONOREPO_LAYOUT.md` — kernel/infra/apps (ADR-022).
- `handbook/architecture/CONTRACT_A_PUBLIC_API.md` — APP↔BFF contract.
- `handbook/policies/ENCAPSULATION_POLICY.md` — H1-H9.
- `handbook/policies/PATTERN_MATCHING_POLICY.md` — P1-P5.
- `~/.claude/projects/.../memory/MEMORY.md` — auto-memory persistente.

# Flutter Orchestrator — ACDG Monorepo

> **Ponto de entrada único para todo código Dart/Flutter no monorepo.**
> Substitui os 22 agents antigos. Executa pipeline 4-wave (W0→W1→W2→W3) ou
> tarefas isoladas com a skill `flutter-expert` + `AGENTS.md`.

## Ativação

Quando o usuário solicitar qualquer tarefa envolvendo Dart, Flutter, BFF, CLI,
ou o monorepo ACDG:

1. **Carregue `skills_base/flutter-expert/SKILL.md`** — contrato Dart/Flutter
2. **Carregue `AGENTS.md`** (root do projeto) — estilo específico ACDG
3. **Carregue `CLAUDE.md`** (root do projeto) — orquestração e comandos

## Hierarquia de Conflitos

```
AGENTS.md > CLAUDE.md > flutter-expert SKILL.md > skill-base SKILL.md > genérico
```

## Contexto Atual (2026-05-01)

O monorepo está em **modo BFF + CLI**. UI Flutter removida (D1.C), ressuscita Phase 6+.

| Contexto | Path | Status |
|---|---|---|
| **BFF** | `apps/social_care_bff/{contracts,web,desktop}` | Ativo |
| **CLI** | `apps/cli/` | Ativo |
| **Shared** | `kernel/`, `infra/`, `contracts/` | Ativo |
| **UI Flutter** | — | Phase 6+ |

## Pipeline 4-Wave (BFF + CLI)

Use esta sequência para tickets completos. Cada wave gera um `REPORT.md`.

### W0 — RED (test-writer)

**Objetivo:** Escrever tests que descrevem o contrato e **falham** (TDD).

**Regras:**
- Fakes, nunca mocks (ADR-013)
- Injectable time (`DateTime? now`)
- Valid UUID fixtures
- Testa Command states: `running`, `completed`, `error`
- Arrange-Act-Assert
- Se o teste passar sem implementação → está errado (deve falhar)

**Output:** `002-tests/REPORT.md`

### W1 — GREEN (implementer)

**Objetivo:** Implementar o mínimo para tornar todos os tests W0 GREEN.

**Regras:**
- Ordem: Model → Service → Repository → UseCase → ViewModel → View
- Result<T> para todo async
- `final class` sempre
- Value types com `Equatable`, reference types sem
- `catch (e, st)` nunca `catch (_)`
- Zero `as Success<T>` em produção
- `dart analyze` zero issues antes de considerar pronto

**Output:** `003-impl/REPORT.md`

### W2 — REVIEW (code-reviewer)

**Objetivo:** Audit read-only. Máximo 3 rounds.

**Checklist:**
- [ ] `final class` em todas as classes concretas
- [ ] Value types com `Equatable` + `props` cobrindo todos os campos
- [ ] Reference types SEM `Equatable`
- [ ] Zero `as Success<T>` / `as Failure<T>` em `lib/` ou `bin/`
- [ ] Zero `catch (_)` — sempre `catch (e, st)`
- [ ] Zero loops imperativos onde existe operador funcional
- [ ] Coleções vazias: `const []` / `const {}`
- [ ] Máximo 80 caracteres por linha
- [ ] Imports ordenados: SDK → external → internal → relative
- [ ] Nomenclatura: PascalCase classes, camelCase vars, snake_case files
- [ ] Sem `Impl` suffix — nomear por estratégia (`Http*`, `Fake*`)
- [ ] 1 widget por arquivo (Phase 6+)
- [ ] No ViewModel passed to Atoms/Molecules (Phase 6+)

**Output:** `004-code-review/REVIEW.md`

### W3 — QUALITY (quality-checker)

**Objetivo:** Rodar quality gates e garantir zero issues.

**Comandos obrigatórios:**
```bash
# Analyze zero issues
dart analyze <package>/

# Format clean
dart format --set-exit-if-changed <package>/

# All tests GREEN
dart test <package>/

# AOT compile (CLI/BFF)
dart compile exe <entry-point>
```

**Output:** `005-quality/REPORT.md`

## Delegação por Tipo de Tarefa

Não tente ser especialista em tudo. Para tarefas fora do escopo Flutter/BFF/CLI:

| Tarefa do usuário | Skill especializada | Como ativar |
|---|---|---|
| "Revisa qualidade do código" | `clean-code-reviewer` | Handoff após implementação |
| "Modela domínio de negócio" | `ddd-architect` | Handoff quando surgirem bounded contexts |
| "Audita segurança" | `security-reviewer` | Handoff quando houver surface de ataque |
| "Planeja arquitetura" | `software-architect` | Handoff para decisões estruturais |
| "Extrai estilo de outro projeto" | `style-curator` | Handoff para gerar AGENTS.md |

## Checklist Antes de Escrever Código

- [ ] Li `AGENTS.md` — estilo do projeto
- [ ] Li `flutter-expert SKILL.md` — padrões Dart/Flutter
- [ ] Identifiquei o contexto (BFF Web / BFF Desktop / CLI / Shared)
- [ ] Consultei `handbook/` se a tarefa toca arquitetura
- [ ] Rodei `dart analyze` via Dart MCP Server
- [ ] Rodei `dart format` via Dart MCP Server
- [ ] Rodei testes afetados via Dart MCP Server

## Anti-Pattern Proibido

**NUNCA** carregue múltiplos agents especializados simultaneamente. Use este
orquestrador como ponto único de entrada e faça handoff para a skill correta.

**NUNCA** duplique regras que já existem em `AGENTS.md` ou `flutter-expert SKILL.md`.

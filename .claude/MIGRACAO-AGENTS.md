# Migração de Agents — Como usar o novo sistema

> **Data:** 2026-05-06
> **Status:** 22 agents antigos movidos para `deprecated/`. Novo sistema ativo.

## O que mudou

### Antes (ineficiente para LLMs)

```
22 agents × ~120 linhas = 2.649 linhas de instruções duplicadas
  ├─ Cada agent repetia: "use final class", "Result<T>", "não use Impl"
  ├─ Cada agent tinha escopo próprio (modeler, reviewer, implementer...)
  └─ Sem herança — regra muda = atualiza 22 arquivos
```

### Depois (otimizado)

```
1 orquestrador (flutter-orchestrator.md) = 130 linhas
  └─ Ativa skill flutter-expert (186 linhas) + AGENTS.md (423 linhas)
  └─ Total: ~739 linhas (72% menos tokens no contexto)
```

## Como usar na prática

### Cenário 1: Novo ticket (pipeline completa W0→W1→W2→W3)

**Antes:**
```
Você: @test-writer implementa tests para C11
... (agent escreve tests)
Você: @flutter-bff-implementer implementa C11
... (agent implementa)
Você: @flutter-code-reviewer revisa C11
... (agent revisa)
Você: @flutter-quality-checker roda quality
... (agent roda gates)
```

**Depois:**
```
Você: Implementa o ticket C11 — pipeline completa W0→W3
Orquestrador: Detecta flutter-expert skill + AGENTS.md
  → Executa W0 (tests RED)
  → Executa W1 (implementa até GREEN)
  → Executa W2 (code review)
  → Executa W3 (quality gates)
```

O orquestrador já tem as instruções de todas as 4 waves. Não precisa chamar
agents diferentes — é **um único ponto de entrada**.

### Cenário 2: Tarefa isolada (só implementar, tests já existem)

**Antes:**
```
Você: @flutter-bff-implementer implementa C11 (tests já existem)
```

**Depois:**
```
Você: Implementa C11 — tests W0 já existem, comece do W1
Orquestrador: Executa W1→W2→W3
```

### Cenário 3: Só revisar código existente

**Antes:**
```
Você: @flutter-code-reviewer revisa esse PR
```

**Depois:**
```
Você: Revisa esse código (W2 apenas)
Orquestrador: Executa checklist W2 + gera REVIEW.md
```

### Cenário 4: Suite de segurança

A suite de segurança (11 agents) **não foi alterada**. Continua funcionando
como antes, orquestrada por `security-orchestrator`.

Quando precisar de segurança num ticket Flutter:
```
Você: Execute suite de segurança no C11
Orquestrador: Handoff para security-orchestrator
```

## Estrutura de arquivos por ticket (não mudou)

```
.pipeline/phase-X/tickets/<TICKET>/
  000-request.md        ← escopo (você escreve)
  002-tests/REPORT.md   ← W0 output
  003-impl/REPORT.md    ← W1 output
  004-code-review/REVIEW.md  ← W2 output
  005-quality/REPORT.md ← W3 output
  STATE.md              ← status acumulado
```

## Integração com skills_base

O `flutter-orchestrator.md` referencia:
- `skills_base/flutter-expert/SKILL.md` — padrões Dart/Flutter
- `skills_base/skill-base/SKILL.md` — contrato universal (citação, tom, handoff)
- `AGENTS.md` — estilo específico do projeto ACDG
- `CLAUDE.md` — orquestração e comandos

**Como funciona no Kimi CLI:**

Quando você está no diretório `skills_base/`, o Kimi conhece todas as skills
via `SKILLS-REGISTRY.md`. Ao trabalhar no `frontend/`, o Kimi lê:
1. `AGENTS.md` (automático — está no root do projeto)
2. `CLAUDE.md` (automático)
3. Skills são ativadas por trigger de palavras-chave

**Como funciona no Claude Desktop/Code:**

O Claude lê automaticamente `.claude/agents/flutter-orchestrator.md` quando
você abre o workspace `frontend/`. O orquestrador instrui o Claude a carregar
`AGENTS.md` e `CLAUDE.md`.

## Resumo dos comandos

| O que você quer | O que diz |
|---|---|
| Pipeline completa | "Implementa ticket C11 — pipeline W0→W3" |
| Só tests | "Escreve tests RED para C11 — W0 apenas" |
| Só implementar | "Implementa C11 — W1→W3 (tests já existem)" |
| Só revisar | "Revisa C11 — W2 apenas" |
| Só quality | "Roda quality gates em C11 — W3 apenas" |
| Segurança | "Audita segurança do C11" → handoff para security |

## Recuperando agents antigos

Se precisar de algum agent antigo, eles estão em:
```
.claude/agents/deprecated/
```

Basta copiar de volta para `.claude/agents/` se necessário.

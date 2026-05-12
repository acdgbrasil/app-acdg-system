# Missions — AI Task Tracking

Registro estruturado de missoes delegadas entre agentes AI (Gemini, Claude) e revisadas pelo tech lead humano.

## Estrutura

```
missions/
+-- README.md                          # Este arquivo
+-- YYYY-MM-DD_<slug>/                 # Uma pasta por missao, datada
|   +-- MISSION.md                     # Briefing: contexto, tasks, definition of done
|   +-- REPORT.md                      # Resultado: o que foi feito, decisoes, blockers
|   +-- subtasks/                      # (opcional) subtemas complexos
|   |   +-- <subtask-slug>/
|   |   |   +-- NOTES.md
|   +-- artifacts/                     # (opcional) screenshots, logs, diffs relevantes
```

## Convencoes

| Campo | Formato | Exemplo |
|-------|---------|---------|
| **Pasta da missao** | `YYYY-MM-DD_<slug-kebab>` | `2026-04-03_fix-family-composition-bugs` |
| **Slug** | kebab-case, max 50 chars | `fix-family-composition-bugs` |
| **MISSION.md** | Frontmatter YAML + corpo | Ver template abaixo |
| **REPORT.md** | Criado pelo executor ao concluir | Ver template abaixo |

## Template — MISSION.md

```markdown
---
date: YYYY-MM-DD
author: <quem criou — gemini | claude | human>
executor: <quem executa — claude | gemini | human>
reviewer: <quem revisa — human | gemini | claude>
status: backlog | in_progress | review | done | blocked
tags: [bug, feature, refactor, infra, docs]
priority: P0 | P1 | P2 | P3
---

# Titulo da Missao

## Contexto
<Por que essa missao existe>

## Tasks
- [ ] Task 1: descricao
- [ ] Task 2: descricao

## Definition of Done
1. Criterio 1
2. Criterio 2

## Notas
<Observacoes adicionais>
```

## Template — REPORT.md

```markdown
---
date: YYYY-MM-DD
executor: <quem executou>
duration: <tempo aproximado>
status: done | partial | blocked
---

# Relatorio — Titulo da Missao

## Resumo
<1-3 frases sobre o que foi feito>

## Decisoes Tomadas
- Decisao 1: motivo
- Decisao 2: motivo

## Resultados
- [ ] Task 1: status + detalhes
- [ ] Task 2: status + detalhes

## Blockers / Riscos
<Se houver>

## Proximos Passos
<Se aplicavel>
```

## Como Gerar Relatorios

Para gerar um relatorio consolidado de todas as missoes:

```bash
# Listar todas as missoes por data
ls -1 handbook/missions/ | grep -E '^\d{4}' | sort

# Buscar missoes por tag
grep -rl 'tags:.*bug' handbook/missions/*/MISSION.md

# Buscar missoes por status
grep -rl 'status: done' handbook/missions/*/MISSION.md

# Buscar missoes por executor
grep -rl 'executor: claude' handbook/missions/*/MISSION.md
```

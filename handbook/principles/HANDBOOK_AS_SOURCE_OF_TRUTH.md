# Handbook como Fonte Única de Verdade

> **Status:** Diretriz operacional inegociável.
> **Data:** 2026-05-01
> **Origem:** decisão do usuário durante Phase 5 scaffold.

---

## A regra

> "Nunca confie na sua memória. Ela é compartilhada com vários projetos. SEMPRE escreva dentro do `handbook/` TUDO que é aprendizado. Olhe o handbook e veja se ele está atualizado ou desatualizado — se tiver desatualizado, ATUALIZE."

## Por quê

1. **Memória de agentes (LLM) é frágil e compartilhada.** Memórias persistidas em `~/.claude/projects/.../memory/` podem vazar entre sessões e contextos. O que o agente "lembra" não é canônico.

2. **Handbook é versionado em git.** Toda mudança aparece em diff, é reviewable, sobrevive a trocas de agente, time, ferramenta. Memória de LLM não tem nada disso.

3. **Onboarding humano e agente compartilham fonte.** Um dev novo + um Claude novo + um Gemini novo precisam encontrar a verdade no MESMO lugar. Esse lugar é `handbook/`.

4. **Stale knowledge é débito invisível.** Se o handbook diz "Atomic Design" mas o código deletou a UI, qualquer agente que consultar o handbook gera código errado. **Stale doc é pior que doc faltante** — induz confiança falsa.

## Como aplicar

### Antes de gravar memória

Pergunte: "isso pertence ao **handbook** (canon do projeto) ou à **memória** (preferência efêmera do colaborador)?"

| Tipo de informação | Local correto |
|--------------------|---------------|
| Decisão arquitetural ("usamos Drift, não Isar") | **handbook/architecture/DECISIONS.md** (ADR) |
| Layout do monorepo | **handbook/architecture/MONOREPO_LAYOUT.md** |
| Padrão de código aceito | **handbook/principles/** |
| Convenção de commit/branch | **handbook/process/** |
| Stack de ferramentas | **handbook/tooling/README.md** |
| Mapa de packages e features | **handbook/codebase/README.md** |
| Estado de fase em curso | **.pipeline/phase-N-X/STATE.md** |
| Preferência do usuário ("não use emoji em PR") | memória `feedback_*` |
| Forma como o usuário gosta de receber respostas | memória `feedback_*` |
| Fato sobre quem é o usuário (papel, contexto) | memória `user_*` |
| Pointer para sistema externo ("bugs ficam em X") | memória `reference_*` |

**Regra de ouro:** se a informação é verdade sobre **o projeto**, vai pro handbook. Se é verdade sobre **o colaborador** (humano ou estilo), vai pra memória.

### Antes de escrever código

Antes de implementar qualquer coisa não-trivial, leia:
1. `handbook/architecture/MONOREPO_LAYOUT.md` (onde os arquivos vão)
2. `handbook/architecture/DECISIONS.md` (decisões formais)
3. `handbook/principles/README.md` (regras inegociáveis)
4. `handbook/codebase/README.md` (mapa de packages)

Se algum deles está desatualizado em relação ao código, **PARE e atualize antes de seguir**. Continuar sobre prose stale é multiplicar débito.

### Auditoria periódica

Sempre que terminar uma fase grande (mudança de monorepo, delete batch, ADR novo, refactor cross-cutting):
1. `grep -rn "old_pattern" handbook/{architecture,principles,process,codebase,tooling,quality,cicd}` para achar refs obsoletas em docs **vivos**.
2. **NÃO atualizar docs históricos** — `handbook/{chat,audit,missions,reports,research,social_care_implementation,web-migration,implementation_plans}/` preservam estado de uma época. Reescrever passado é perda de memória organizacional.
3. Atualizar docs vivos com fato novo + adicionar nota de timestamp (`> Atualizado 2026-MM-DD reflectindo X.`)
4. Se um doc todo virou history (referencia stack que não existe mais), mover pra `handbook/reports/` em vez de deletar.

### Quando o handbook estiver errado

Não silencie a inconsistência. Trate como se fosse um teste vermelho (CLAUDE.md REGRA #2):
1. **Intenção:** o que o doc estava tentando dizer?
2. **Falha:** por que ele está errado agora?
3. **Veredicto:** o doc está errado, o código está errado, ou ambos divergiram intencionalmente sem decisão registrada?
4. **Opções:** atualizar doc / atualizar código / criar ADR registrando divergência intencional / mover doc para reports/.

Não escolha sozinho — verbalize ao usuário antes de mudar.

## Aplicação a esta sessão (2026-05-01)

Quando o usuário deu esta diretriz, o handbook tinha 4 READMEs com refs ao layout antigo:
- `handbook/README.md` — princípios "Micro-Frontend / Atomic Design" sem contexto de Phase 5
- `handbook/principles/README.md` — `package:design_system` em imports (deletado em D1.C)
- `handbook/process/README.md` — "Shell" + "3 plataformas" (deletados)
- `handbook/codebase/README.md` — mapa de packages com shell, design_system, isar
- `handbook/tooling/README.md` — Provider, Isar, deps de shell deletado

Ação tomada: atualizar os 5 com banner sobre estado atual + apontar pra MONOREPO_LAYOUT.md como canon. Docs históricos não tocados.

## Anti-patterns

- ❌ "Vou só lembrar disso pra próxima sessão" → **NÃO**. Escreva no handbook.
- ❌ "Vou anotar na memória do agente" → só se for **preferência do colaborador**, não fato do projeto.
- ❌ "O handbook está desatualizado mas eu sei a verdade" → **NÃO**. Pare e atualize.
- ❌ Deletar prose obsoleto sem registrar onde foi parar → mover pra `reports/` se tem valor histórico.

## Referência cruzada

- `CLAUDE.md` REGRA #1 — "O handbook/ é a fonte de verdade arquitetural."
- `CLAUDE.md` REGRA #2 — "No test cheating" (mesma lógica aplicada a docs).
- `handbook/principles/README.md` — princípios técnicos.
- `handbook/architecture/DECISIONS.md` — ADRs.

# Discuss Context — phase-3-bff-contract-a

## Mode: assumptions (usuário validou o plano; seguindo com defaults)

## Decisões fechadas
- **Breaking changes livres** — sem compat com versão anterior.
- **Testes deprecados** — 93 errors em tests do BFF ignorados; não consertar; podem ser deletados em A21 se quisermos.
- **Desktop não em produção** — pode quebrar durante a fase; só precisa voltar a compilar em A16-A18.
- **Rotas `/people/by-cpf/*` e `/team/people/*`** — ninguém consome; deletar em A15.
- **`SocialCareContract`** — deletada em A05.
- **BFF dita regra de negócio** — não é proxy. Orquestra, compõe, mantém estado, pede features ao backend.
- **Contract A ≠ Contract backend** — endpoints inventados pelo BFF conforme o APP precisa.

## Filosofia dos 3 contratos
| Contrato | Entre | Arquivos | Propriedade |
|----------|-------|----------|------------|
| **A — Público** | APP ↔ BFF | `bff/shared/dto/request/` + `dto/response/` | Feature-oriented, auto-suficiente, estável |
| **B — Orquestração** | BFF ↔ backends | `bff/shared/contracts/` + `bff/social_care_web/remote/` | Interno, conhece topologia |
| **C — Backend** | Backend Swift ↔ DB | (fora do escopo) | Swift/Vapor |

## Regras operacionais por ticket
1. Cada ticket traz o BFF para um estado melhor, nunca pior.
2. Pode quebrar outros módulos temporariamente (ex: A05 quebra Desktop → A16-A18 conserta).
3. `dart analyze bff/<modulo>` tem que terminar sem erros no fim do ticket (só no módulo alterado).
4. Testes: **ignorar**. Marcar pasta `test/` como deprecada, não mexer.
5. Cada ticket escreve `STATE.md` + `FINAL.md` curto.

## Open Items (descobrir em A01)
- Lista completa de ações do APP (só A01 fecha isso).
- Se há ações que o backend Swift NÃO suporta hoje → entram como "backend requests" em A01.
- Endpoints compostos definitivos (ex: `/api/lookups?tables=...` já acordado; outros podem surgir).

## Questões respondidas pelo usuário
1. Desktop em prod? **Não.** Pode quebrar.
2. `/people/by-cpf/*` e `/team/people/*` são consumidos? **Não.** Deletar.
3. `SocialCareContract` — deprecar ou deletar? **Deletar.**

## Próximo passo
Executar A01 — Contract A design (pesquisa no Flutter). Resultado é um documento que guia A02..A21.

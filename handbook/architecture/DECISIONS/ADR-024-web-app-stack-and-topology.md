# ADR-024 — Web App Stack & Topology (Vite + React + TS6, servido pelo BFF Shelf)

**Status:** Accepted
**Date:** 2026-05-12
**Deciders:** Phase 6+ Frontend Revival
**Supersedes:** Parcial — revisita ADR-006 (Adaptive Design 3 Pages) e ADR-001 (Flutter como stack Web)
**Related:** ADR-002 (BFF pattern), ADR-007 (BFF Edge), ADR-011 (Split-Token), ADR-012 (OIDC PKCE), ADR-022 (kernel/infra/apps layout), ADR-023 (Bearer forwarding), ADR-025 (API Contract), ADR-026 (Security Hardening)

---

## Contexto

### Estado atual do monorepo (Phase 5 CLI-first)

A UI Flutter foi removida em D1.C (commit `33626f0`, 2026-05): `packages/social_care`, `packages/design_system`, `packages/auth`, `apps/acdg_system` foram deletados. O monorepo Phase 5 entrega apenas:

- `apps/cli/` — CLI Dart (ticket pipeline C00–C11)
- `apps/social_care_bff/web/` — BFF Shelf (HTTP, OIDC, sessão)
- `apps/social_care_bff/desktop/` — BFF in-process para Desktop futuro
- `apps/social_care_bff/contracts/` — contratos compartilhados
- `kernel/`, `infra/` — camadas Dart-pure e Flutter-coupled
- `site/` — landing institucional pública (`https://conectararos.org.br`)

A revival da UI está prevista para Phase 6+. Antes de Phase 6 começar, este ADR fixa **qual stack** entra e **qual topologia** vamos usar.

### Por que não voltar com Flutter Web

A audit de Phase 6 (`handbook/archive/audit/2026-05-04-orchestrated/`) e a discussão arquitetural de 2026-05-12 convergiram em três problemas materiais com Flutter Web (WASM ou JS):

1. **ViewModel ↔ runtime Web:** o pattern MVVM definido em ADR-003/013 acopla ViewModels a `ChangeNotifier` + `ValueNotifier`, que têm semântica de listener thread-unsafe quando rodam sob isolates Web. ADR-024 foi prefigurado como "ADR-024 ViewModel-em-Jaspr pendente" durante essa discussão — esta é a resolução dessa pendência.
2. **Acessibilidade WCAG:** Flutter Web (CanvasKit ou skwasm) renderiza fora do DOM. Suporte a leitor de tela, foco, contraste e ARIA é mediado por `Semantics` widget — funcional mas custoso de auditar. Para um app de saúde com LGPD e cuidadores sociais usando tecnologia assistiva, HTML/ARIA nativo é caminho menos arriscado.
3. **Bundle inicial:** Flutter Web WASM produz ~1.5–3 MB de payload inicial (incluindo runtime). Web JS equivalente, em SPA bem feita, fica em 100–400 KB. Para usuário interno em rede corporativa o impacto operacional é baixo; o impacto **de auditoria de cadeia de suprimentos** é proporcional ao tamanho — mais código embarcado = mais a auditar.

Adicionalmente, o pool brasileiro de devs React 19 é materialmente maior que o de Flutter Web especialista, e o codegen de tipos a partir de OpenAPI tem ferramentas TS muito mais maduras (`openapi-typescript`, `orval`) que o equivalente Dart.

### Restrições inegociáveis declaradas pelo product owner

Em conversa 2026-05-12 (registrada em retro arquitetural):

> **R1 — BFF único.** O BFF é o que já existe (`apps/social_care_bff/web/` — Shelf, Dart). Não pode existir "BFF do BFF": nenhum servidor Node, Deno ou Bun rodando em produção entre o browser e o BFF Dart. Web pode ter runtime JS **só em build time**.

> **R2 — Toda regra de negócio no BFF.** Telas só executam regras de visualização. Qualquer cálculo derivado é responsabilidade do BFF entregar pronto no DTO.

> **R3 — Offline-first é benefício exclusivo de Nativo.** Web é sempre online — não tem SyncQueue própria, IndexedDB, Dexie/RxDB. Apenas cache de fetch (TanStack Query).

> **R4 — Aplicação interna.** Sem usuário público, sem SEO, sem indexação Google. Site institucional separado (já existe em `site/`).

> **R5 — Menor trabalho na hora de subir uma versão.** Otimizar para release operation, não para flexibilidade hipotética.

### Princípio arquitetural aplicado

Sam Newman, *Building Microservices*, capítulo 14 (User Interfaces):

> *"All too often, the user interface is an afterthought when it comes to system decomposition — we break apart our microservices but leave a monolithic user interface. This in turn leads to the problems of having separate frontend and backend teams. Instead, we want **stream-aligned teams, where one team owns all the functionality associated with an end-to-end slice of user functionality**. To make that change happen and get rid of siloed frontend and backend teams, we need to break apart our user interfaces."*
> — *(Linha 8929, p. 676, Sam Newman, Building Microservices)*

> *"backend for frontend (BFF) — **A server-side component that provides aggregation and filtering for a specific user interface**. An alternative to a general-purpose API gateway."*
> — *(Linha 9179, p. 683, Sam Newman, Building Microservices)*

O BFF, na origem do pattern, é **deployment unit acoplado à UI específica** que ele serve. Separar Web e BFF em containers distintos contradiz o pattern: a separação Caddy/Shelf seria operacional, não de domínio.

---

## Decisão

### Stack

| Camada | Tecnologia | Versão |
|---|---|---|
| Linguagem | TypeScript | 6.0 (strict, `noUncheckedIndexedAccess: true`, `exactOptionalPropertyTypes: true`) |
| Framework UI | React | 19.x |
| Build tool | Vite | 5.x (com migração natural para Rolldown quando virar default upstream) |
| Build runtime | Bun | 1.x — **apenas em CI**, nunca em produção |
| Router | TanStack Router | latest stable |
| Data fetching / cache | TanStack Query | latest stable |
| State (UI local) | React `useState` / `useReducer` — sem Redux/Zustand global |
| Forms | React Hook Form + Zod | latest |
| Tabela densa | TanStack Table | latest |
| Auth client | `oidc-client-ts` | latest |
| Estilos | CSS Modules + design tokens TS (Style Dictionary) | — |
| Testes | Vitest + Testing Library + Playwright | — |

### Topologia (β consolidado)

**Um container de produção** para o contexto Aplicação. Site institucional (`site/`) permanece em container separado por razão de domínio (não compartilha ciclo de mudança com o app interno).

```
┌─────────────────────────────────────────────────────────┐
│ Contexto Institucional (independente)                   │
│   site/ → Dockerfile.site → Caddy → site-acdg:vX.Y.Z    │
│   Domínio: posicionamento/marketing ACDG                │
│   Mudança independente do app                           │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Contexto Aplicação (acoplado pela mesma tag SemVer)     │
│                                                          │
│   apps/conecta_web/    (NOVO — Vite+React+TS6)          │
│   apps/social_care_bff/web/    (Shelf Dart)             │
│                                                          │
│   ┌──────────────────────────────────────────────┐      │
│   │ Dockerfile.bff (multi-stage)                 │      │
│   │                                               │      │
│   │ Stage A: Bun build                            │      │
│   │   - bun install --frozen-lockfile             │      │
│   │   - bun run build → apps/conecta_web/dist/   │      │
│   │                                               │      │
│   │ Stage B: Dart AOT                             │      │
│   │   - dart compile exe server.dart             │      │
│   │                                               │      │
│   │ Stage C: Distroless runtime                  │      │
│   │   - COPY --from=A /dist /app/static          │      │
│   │   - COPY --from=B /server /app/server        │      │
│   │   - ENTRYPOINT /app/server                   │      │
│   └──────────────────────────────────────────────┘      │
│                                                          │
│   Edge: Caddy (Caddyfile.gateway/.prod existentes)      │
│         TLS, rate limit, HSTS, security headers          │
│         reverse_proxy / → bff:8081                       │
└─────────────────────────────────────────────────────────┘
```

### Regras concretas

1. **Pasta:** `apps/conecta_web/`. Não `apps/web/` (colide mentalmente com `apps/social_care_bff/web/`).
2. **Versionamento:** uma única tag SemVer do monorepo cobre Web + BFF. Web nunca tem tag independente. Site institucional tem ciclo próprio.
3. **Bun não vai a produção.** Apenas runtime de build em CI. Se Bun morrer em 5 anos, migração para `npm`/`pnpm` é trivial (`package.json` é compatível).
4. **Sem SSR, sem Server Components, sem API routes.** R1 proíbe BFF-do-BFF; Next.js fica fora.
5. **Sem WebSockets/SSE no Web JS por default.** Se necessário, abrir ADR específico — não é parte deste.
6. **CSS Modules + design tokens.** Sem Tailwind, sem styled-components em runtime (`emotion` em runtime adiciona ~10KB e cria classe de bugs SSR/hidratação que não temos). Tokens via Style Dictionary (gera `tokens.css` + `tokens.dart`).
7. **`shelf_static` no BFF.** Adicionar `shelf_static: ^1.1.2` ao `apps/social_care_bff/web/pubspec.yaml`. Servir `/static/*` + fallback `index.html` para rotas client-side.
8. **Caddy continua existindo como edge reverse proxy.** Os Caddyfiles existentes (`Caddyfile.gateway`, `Caddyfile.prod`) permanecem; apenas trocam `file_server` por `reverse_proxy / → bff:8081`. Headers de segurança permanecem no edge (cross-ref ADR-026).

### Layout do `apps/conecta_web/`

```
apps/conecta_web/
├── package.json              # name: "@acdg/conecta-web", private: true
├── tsconfig.json             # extends ../../tsconfig.base.json
├── vite.config.ts
├── index.html
├── public/                   # favicons, manifest
├── src/
│   ├── main.tsx              # entry: ReactDOM.createRoot(...).render(<App/>)
│   ├── App.tsx               # RouterProvider + QueryClientProvider + AuthProvider
│   ├── routes/               # TanStack Router file-based
│   │   ├── __root.tsx
│   │   ├── login.tsx
│   │   ├── _authed/          # rotas protegidas (layout com guard)
│   │   │   ├── pacientes/
│   │   │   ├── acolhimento/
│   │   │   └── coordenacao/
│   ├── api/
│   │   ├── client.ts         # fetch wrapper + credentials: 'include'
│   │   ├── generated/        # tipos do OpenAPI (ver ADR-025) — gitignored
│   │   └── hooks/            # useQuery/useMutation wrappers tipados
│   ├── auth/
│   │   ├── oidc.ts           # oidc-client-ts setup (PKCE, Split-Token via cookie BFF)
│   │   └── useAuth.tsx       # context + guard
│   ├── components/
│   │   ├── ui/               # primitivos (Button, Input, Modal) — design system local
│   │   └── feature/          # widgets de feature (PacienteRow, FichaCard)
│   ├── styles/
│   │   ├── tokens.css        # GERADO por Style Dictionary — gitignored
│   │   ├── base.css          # reset + base
│   │   └── global.css
│   └── lib/
│       ├── formatters.ts     # APENAS regras de visualização (R2)
│       └── validators.ts     # APENAS validação client-side de UX (BFF é autoridade)
└── tests/
    ├── unit/
    └── e2e/                  # Playwright
```

### Garantias por construção

- **R1 (BFF único)** — atendido. Nenhum runtime JS em produção. Bun só em CI.
- **R2 (regra no BFF)** — atendido por convenção. CI fail se aparecer cálculo derivado em `src/` (lint rule simples: `// LGPD-OK` opcional, mas auditoria manual em PRs).
- **R3 (sem offline)** — atendido. Sem Dexie/IndexedDB. Apenas TanStack Query.
- **R4 (interno)** — atendido. Sem prerendering, sem sitemap, sem meta SEO.
- **R5 (menor trabalho na release)** — atendido. Mesma tag, mesmo CI, mesmo `flux apply`.

---

## Consequências

### Positivas

| Ganho | Como se materializa |
|---|---|
| **Stream-aligned team** | Web + BFF + tipos no mesmo PR, mesma tag, mesmo deploy. Equipe pensa em fatia vertical, não em silos. |
| **Drift de contrato eliminado** | Mesmo commit gera tipos TS + valida Dart. Versão dessincronizada Web↔BFF fica impossível. |
| **Acessibilidade WCAG nativa** | HTML/ARIA real, ferramentas maduras (Axe, Pa11y, Lighthouse CI). Cobre cuidadores com tecnologia assistiva sem custo extra. |
| **Bundle pequeno em produção** | 100–400 KB gzip vs 1.5–3 MB de Flutter Web WASM. Materialmente menos código auditável. |
| **DevTools de navegador** | Inspector, Network, Performance funcionam nativamente. Diagnóstico de bug em produção fica trivial. |
| **Pool de devs amplo** | React 19 + TS 6 é stack universal no Brasil. Onboarding mais rápido. |
| **Codegen de tipos maduro** | `openapi-typescript` gera tipos zero-runtime a partir do spec. Sem `as any`, sem casting. |
| **Supply chain pequeno** | 1 imagem Docker, 1 SBOM, 1 scan. Menos a manter atualizado. |
| **Sem SSR/RSC** | Surface menor. Sem ataque server-side de hidratação, sem RCE via deserialização SSR. |

### Negativas / Custos

| Custo | Como mitigamos |
|---|---|
| **2 stacks (Dart + TS)** | OpenAPI como única fonte (ver ADR-025). Codegen bidirecional remove a duplicação cognitiva no ponto onde ela machuca (contratos). |
| **Hiring bilíngue** | Time pode partir naturalmente em sub-times (frontend TS, backend Dart). Governança via OpenAPI + processo de PR cruzado evita silos. |
| **ADR-006 (3 Pages Adaptive Design) perde escopo Web** | Adaptive Design permanece **apenas** entre Desktop e Mobile Flutter (Phase 6+). Web sai dessa coordenação. Não é problema — Web e Native têm personas distintas (Web: Acolhimento/Coordenação/Indicadores; Native: Visitas/Atendimento). |
| **Design tokens duplicados (CSS + Dart)** | Style Dictionary com dual-emit. Mudança em token Figma propaga em 1 build. |
| **`shelf_static` no BFF** | Surface marginal. Package oficial Dart team, defaults seguros (`serveFilesOutsidePath: false`). Cobertura em ADR-026 §Static serving. |
| **Sem rollback independente Web/BFF** | Por design — rollback acoplado é **vantagem**, não custo (evita estado inconsistente). |
| **Sem escalonamento independente** | Improvável virar problema (app interno autenticado, carga conhecida). Se virar, ADR futuro pode separar. |
| **CSP + COEP/COOP migram pra middleware Shelf ou edge Caddy** | Cobertura em ADR-026. ~1 dia de trabalho. |

### Quebras se as regras forem violadas

| Violação | Consequência | Detecção |
|---|---|---|
| Adicionar rota Node em prod (Next API route, server action) | Viola R1. BFF-do-BFF reintroduzido. | Code review obrigatório + grep CI em `pages/api`, `app/api`, `+server.ts`. |
| Lógica de negócio em `src/lib/` ou `src/api/hooks/` | Viola R2. Cálculo derivado fora do BFF. | Code review + auditoria periódica. Exemplos: contagem agregada, ordenação business, formatação dependente de regra de domínio. |
| `localStorage`/`sessionStorage` para token | Viola ADR-011 (Split-Token). | grep CI bloqueante: `localStorage|sessionStorage` em arquivos que tocam auth. |
| Adicionar `IndexedDB`/`Dexie`/`RxDB` | Viola R3. Reintroduz complexidade offline. | grep CI em `package.json` e `src/`. |
| Tag SemVer separada Web/BFF | Viola R5 + Common Closure Principle. | Lint no script de release. |

---

## Alternativas consideradas

### Alternativa 1 — Manter Flutter Web (variante A original)

**Rejeitada.** Três motivos materiais:

1. **ADR-024 prefigurado pendia ViewModel-em-Web não-resolvido.** Persistir Flutter Web exige resolver `ChangeNotifier` thread-safety em isolates Web. Investimento desproporcional ao benefício.
2. **Acessibilidade.** Cuidador social com tecnologia assistiva é persona real. CanvasKit/skwasm + `Semantics` é caminho mais arriscado que HTML/ARIA nativo. Auditoria WCAG fica mais cara.
3. **Custo afundado é zero.** UI Flutter já foi deletada (D1.C). Persistir Flutter Web é decisão nova, não preservação de investimento.

### Alternativa 2 — Jaspr (Dart compila pra Web, variante B)

**Rejeitada.** Pool de devs Jaspr no Brasil é mínimo. Ecossistema imaturo. Acoplamento ViewModel ↔ ChangeNotifier persistiria.

### Alternativa 3 — Web JS com BFF dedicado em Node/Deno/Bun

**Rejeitada por R1.** Product owner foi explícito: BFF único, sem BFF-do-BFF. Esta alternativa contradiz R1.

### Alternativa 4 — α (2 containers: Caddy + Shelf, mesma tag)

**Rejeitada após análise de segurança e DevSecOps (turno arquitetural de 2026-05-12).** Resumo:

- **Defense in depth é placebo.** Caddy isola assets do BFF, mas assets são públicos por design — não contêm segredo. Isolamento que protege ativo público não é controle real.
- **Supply chain dobra.** 2 imagens, 2 SBOMs, 2 scans, 2 cadências de patch.
- **Rollback independente é falsa flexibilidade.** Web e BFF têm contrato acoplado; rollback parcial = estado inconsistente.
- **Newman favorece β.** Stream-aligned team owns end-to-end slice (citação acima).
- **Os Caddyfiles existentes permanecem** em β (como edge reverse proxy, fora do container) — perda de reuso é zero.

### Alternativa 5 — Svelte 5 + Vite + Bun

**Rejeitada por hiring.** Tecnicamente Svelte 5 é melhor em várias dimensões (bundle menor, DX). Mas em 2026 no mercado brasileiro o pool de devs Svelte é ~10× menor que React. Para app interno com vida útil longa, optar por pool maior reduz risco de manutenção.

**Revisitar em 2030+** se Svelte ultrapassar React em adoção brasileira.

### Alternativa 6 — Lit 3 + Web Components puros

**Rejeitada como default; mantida como "rota de evasão de lock-in".** Lit é tecnicamente excelente para durabilidade de 15+ anos (Web Components é padrão W3C). Custos: pool de devs menor, ecossistema de componentes (TanStack, headless UI) é menos consolidado.

Se React 19 for o "default seguro de hoje", Lit 3 é o "default seguro de 2035". Não rejeitada por mérito — rejeitada por horizonte de prazo.

### Alternativa 7 — Vanilla TS + Web Components (sem framework)

**Rejeitada por trabalho operacional.** Forms complexos (Acolhimento), tabelas densas (Pacientes), state cross-component em Vanilla TS é viável mas verboso. Trabalho de manutenção sobre a vida útil > custo de carregar React 19 (~40 KB).

### Alternativa 8 — Webpack 5

**Rejeitada por modernidade.** Webpack ainda funciona, mas escolher Webpack greenfield em 2026 é dívida nascida pronta. Vite tem build mais rápido, config mínima, e migração futura para Rolldown é flag.

### Alternativa 9 — Node 22 LTS como build runtime (em vez de Bun)

**Defensável, mas rejeitada por R5.** Node 22 LTS é "boring is good": risco quase zero, pool universal. Bun é ~3× mais rápido em CI install + build, e o risco se restringe a build time — em produção Bun não roda.

Se Bun morrer em 5 anos, migrar para Node é trivial (`package.json` compatível). O cenário onde escolher Node é mais defensável: time tem trauma com Bun e prefere consistência operacional com outros projetos Node. Não é o caso da ACDG.

---

## Future enforcement (TODO — quando primeiro PR de `apps/conecta_web/` aterrissar)

```yaml
# .github/workflows/web-build.yml (FUTURE)
name: web-build
on:
  pull_request:
    paths:
      - 'apps/conecta_web/**'
      - 'apps/social_care_bff/web/**'
      - 'kernel/contracts/**'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
        with:
          bun-version: 1.x
      - run: bun install --frozen-lockfile
        working-directory: apps/conecta_web
      - run: bun run typecheck    # tsc --noEmit
        working-directory: apps/conecta_web
      - run: bun run lint
        working-directory: apps/conecta_web
      - run: bun test
        working-directory: apps/conecta_web
      - run: bun run build
        working-directory: apps/conecta_web
      - name: Check bundle size budget
        run: |
          MAX_KB=400
          SIZE_KB=$(du -sk apps/conecta_web/dist | cut -f1)
          test $SIZE_KB -le $MAX_KB || (echo "Bundle excede ${MAX_KB}KB" && exit 1)
```

Bundle budget: 400 KB gzipped. Excede → CI bloqueia + decisão consciente (relaxar budget via PR específico, não silenciosamente).

---

## Open questions

1. **Dual-emit de tokens (CSS + Dart):** Style Dictionary é a escolha sugerida, mas há alternativas (Theo, Tokens Studio). Decisão deferida para o PR que introduzir o design system. Não bloqueia este ADR.
2. **TanStack Router file-based vs code-based:** file-based é default no template Vite + TanStack. Reavaliar se time preferir code-based para colocation de loaders. Não bloqueia.
3. **Sentry para erro reporting:** atual `Dockerfile.web` injeta `SENTRY_DSN` — manter ou descartar? Decisão deferida para ADR de observabilidade Web (futuro).
4. **i18n:** PT-BR único hoje. Se um dia precisar EN/ES, `react-intl` ou `i18next`. Não decidido — fora de escopo.
5. **Storybook:** vale ter para isolamento de componentes? Custo de manutenção real; ROI depende do tamanho do design system local. Decidir após primeiras 10 telas.

---

## Riscos não cobertos por este ADR

- **Bun runtime bug em CI** — improvável dado o uso restrito (apenas build), mas existe. Mitigação: pin de versão Bun no workflow + smoke build local antes de merge de bumps.
- **Mudança de licenciamento React** — React MIT desde 2017, risco hipotético. Se mudar, migrar para Preact (drop-in compatível) é mitigação.
- **Vulnerabilidade em `oidc-client-ts`** — package mantido pela comunidade IdentityModel. Mitigação: pinning + audit + plano de contingência (`react-oidc-context` alternativa).
- **shelf_static path traversal** — coberto em ADR-026 §Static serving.

---

## LGPD mapping

| Artigo | Controle | Aderência via ADR-024 |
|---|---|---|
| Art. 46 (medidas técnicas) | Stack moderno, surface menor que Flutter WASM | **Atendido**: bundle menor, HTML/ARIA nativo, supply chain reduzido. |
| Art. 47 (cooperação com agentes) | Auditoria via ferramentas maduras (Axe, Lighthouse, npm audit) | **Atendido**: ferramentas mainstream com ecossistema de relatórios. |
| Art. 50 (boas práticas) | ADR público + alternativas registradas + future enforcement | **Atendido**. |

Detalhes de hardening em ADR-026.

---

## Referências

- **ADRs relacionados**: ADR-002, ADR-007, ADR-011, ADR-012, ADR-022, ADR-023, ADR-025, ADR-026
- **Newman, Sam.** *Building Microservices*, 2nd ed., O'Reilly, 2021. Capítulo 14 (User Interfaces), p. 676, 683.
- **Common Closure Principle (Robert C. Martin)**, *Clean Architecture*: "The classes in a component should be closed against the same kinds of changes."
- **Discussão arquitetural** 2026-05-12 (registrada em handbook/architecture/PROPOSALS/2026-05-12-web-frontend-stack-decision.md — a criar)
- **Vite docs**: https://vitejs.dev/
- **React 19 release notes**: https://react.dev/blog/2024/12/05/react-19
- **TanStack Router/Query/Table**: https://tanstack.com/
- **Bun**: https://bun.sh/
- **Style Dictionary**: https://amzn.github.io/style-dictionary/

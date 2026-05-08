# External Review Charter — ACDG Frontend Monorepo

> **Status:** ATIVO. Atualizado quando uma policy do projeto muda — TODA atualização do `handbook/architecture/*POLICY.md` ou `.claude/skills/*/SKILL.md` deve verificar se o resumo aqui ainda reflete a verdade.
>
> **Propósito:** padronizar como o orchestrator (Claude/agente humano) compõe o **styleGuide do LLM externo** (Gemini, Kimi, etc.) ao invocar `mcp__acdg-skills__ai_gemini_review` ou `ai_pipeline_run`. Este documento é o **contrato entre o orchestrator e o LLM externo** — o LLM **não pode** verificar conformidade contra policies que não estão listadas aqui ou trazidas no `context`.
>
> **Princípio:** o LLM externo **não inventa políticas**. Ele só verifica conformidade contra o que recebeu. Se uma regra do projeto não chegou ao prompt, **violações dela passam despercebidas**. Este charter elimina esse risco enumerando explicitamente.
>
> **Particularidade do projeto:** este charter é específico ao ACDG. Outros projetos (acdg-backend, social-care-deno, edge-cloud-infra) têm seus próprios charters. A **convenção do nome e estrutura** é compartilhada — o conteúdo, não.

---

## §0 — Como o orchestrator USA este charter

A cada invocação de `ai_gemini_review` (ou `ai_pipeline_run`):

1. **Identificar paths tocados pelo diff** (via `git diff --name-only`).
2. **Mapear paths → policies relevantes** usando a tabela §3 (Auto-discovery).
3. **Compor o `styleGuide`** concatenando:
   a. §1 deste charter (header + must_fix categories).
   b. §2 deste charter (resumos compactos das policies/skills relevantes).
   c. **Sources-of-truth integrais** das policies marcadas como "anexar integral" pelo §3.
4. **Compor o `spec`** usando o template de §4 (perguntas adversariais NO TOPO).
5. **Compor o `context`** com trechos do código existente que o LLM precisa para julgar (ex: helpers que o diff usa mas não modifica).
6. **Após receber resposta do LLM:** filtrar findings via §5 (failsafe contra falsos positivos por truncagem).

---

## §1 — Header obrigatório do styleGuide (cole literal no prompt do LLM)

```
# ACDG Project — Mandatory Compliance Targets

You are reviewing code from the ACDG frontend monorepo (Dart/Flutter, BFF Web em shelf). Your role is SECONDARY — there is already an internal reviewer that has run. Your job is to find what the internal reviewer missed, NOT to re-validate basics.

## Severity scale (use exactly these labels)

- `must_fix`  — violates a hard project policy (listed below). Blocks merge.
- `should_fix` — violates a soft convention or improves robustness. Reviewer judgment.
- `info`      — observation, no action required.

## must_fix categories (EXAMINE EVERY DIFF FOR THESE)

1. `Result<T>` discipline — NO `as Success<T>` / `as Failure<T>` cast in production. NO `valueOrNull!`. Use switch / map / flatMap / combineWith. (See §P5 of PATTERN_MATCHING_POLICY summary in §2 of this charter.)
2. Throw-policy — `throw` PROHIBITED in domain/application layers. Permitted ONLY in adapter boundary (shelf middleware, parsers, FFI), and MUST be a defined panic with breadcrumb (StateError / ArgumentError) — NEVER bare `Exception`. (See ENCAPSULATION_POLICY §Throw Policy summary.)
3. Test cheating — moving a red test to make it pass without documenting the abandonment, swallowing it with `try/catch`, replacing assertion specificity with `anyOf`, etc. (See CLAUDE.md §REGRA #2 — verbatim in §2.)
4. PII / secret leak — CPF/CNS/NIS/RG/tokens/JWT/refresh-token in logs, error messages, exception toString(), or browser-visible JSON. (See appsec-code-reviewer skill summary in §2.)
5. Auth bypass — protected route reachable without authentication, or with wrong role. WWW-Authenticate header MUST NOT be added (deliberate single-oracle policy). 401 body MUST be canonical AUTH-001 / Invalid credentials in EVERY rejection path. (See auth-session-security skill summary in §2.)
6. Equatable contract — value types (DTO, VO, domain model, sealed variant) MUST `with Equatable` + `props` covering ALL final fields. Reference types (Service, Repository, UseCase, ViewModel, Store) MUST NOT mix in Equatable. (See ENCAPSULATION_POLICY §Value vs Reference summary.)
7. Sealed-class downcast — defended by lint `acdg_lints/no_sealed_class_downcast`. Bypass via `// ignore:` is must_fix unless explicitly accepted in handbook.
8. Single-oracle constants — error codes, body bytes, context keys MUST have ONE source. Duplication is allowed only when explicitly anchored by `// SEC:` annotation pointing to the cross-bundle invariant.

## How to report

For EACH must_fix finding: file path, line, the verbatim rule it violates, and the fix recommendation.
For EACH should_fix finding: same plus rationale.

## Failsafe — DECLARE if you didn't get something

If the diff payload was truncated (e.g., comments stripped, partial files only), say so EXPLICITLY in the summary as `partial_review: true` with a list of what is missing. Do NOT guess. False positives caused by missing context are worse than no findings.
```

---

## §2 — Compact rule extracts (cole no styleGuide quando relevante ao diff)

### §2.1 — `Result<T>` discipline (PATTERN_MATCHING_POLICY §P5)

Source-of-truth: `handbook/architecture/PATTERN_MATCHING_POLICY.md` (lines 619+, ~600 lines).

**must_fix**:
- ❌ `(result as Success<T>).value` em arquivos de produção (lib/).
- ❌ `result.valueOrNull!` em produção — bypass equivalente sem stack trace útil.
- ❌ Inventar `guard()` / `andThen()` / `unwrap()` em qualquer package que não seja `core_contracts`. Usar `flatMap` / `map` / `combineWith` JÁ EXISTENTES.
- ❌ `Failure(error)` sem propagar `stackTrace` em combinator novo. Use `Failure(error, stackTrace: stackTrace)`.
- ❌ `// ignore: no_sealed_class_downcast` em produção. Sempre exigir PR ao handbook §P5 antes.

**should_fix**:
- Cadeia de 4+ `flatMap` aninhados — sinal de Intent inflado, considerar `combineWith` ou quebrar em sub-funções.
- Side-effect (log, dispatch) DENTRO do closure de `combineWith`/`map`/`flatMap` — closure só roda no Success path; logging deve viver fora.
- Confusão `map` (closure retorna `R`) vs `flatMap` (closure retorna `Result<R>`) — `dart analyze` aponta o tipo aninhado.

**Exceção (testes):** em `*_test.dart`, `test/**`, `integration_test/**` — `(result as Success<T>).value` é a forma canônica de fail-fast. Switch defensivo em teste é must_fix (esconde regressão).

### §2.2 — Throw-policy + Defined panic (ENCAPSULATION_POLICY § Throw Policy)

Source-of-truth: `handbook/architecture/ENCAPSULATION_POLICY.md`.

**must_fix**:
- ❌ `throw` em camada `domain/` ou `application/`. Domain/application são zero-throw — TUDO retorna `Result<T, E>`.
- ❌ `throw Exception(...)` ou `throw 'string'` em qualquer camada. Use `StateError` (invariante violado), `ArgumentError` (input inválido), ou erros tipados privados (`_XxxParseError`).
- ❌ `catch (_)` que descarta cause + stackTrace. **Reprovação automática.**
- ❌ Mensagem de erro que ecoa input do usuário (`"Invalid value $cpf"`) — PII leak.
- ❌ Mensagem de erro que enumera campos missing (`"field X is required"`) — shape leak.

**should_fix**:
- Throw em adapter boundary sem `// SEC:` ou comentário explicando o defined panic.
- Mensagem genérica sem breadcrumb de operação (ex: `"misconfigured"` sem dizer QUAL pipeline).

### §2.3 — Test cheating (CLAUDE.md REGRA #2)

Source-of-truth: `CLAUDE.md` (root do projeto).

**must_fix** — qualquer um dos abaixo é reprovação automática:
- Mover teste para caso onde passa sem documentar abandono do original.
- Trocar `expect(404)` por `expect(anyOf(404, 500))` sem explicar o 500.
- `@Skip` ou `// skip` sem comentário explícito `"REGRA #2: aceito como dívida porque <motivo>"`.
- Adicionar `try/catch` na impl APENAS para teste passar.
- Reescrever teste para "afirmar o que a impl faz" em vez de "afirmar a intenção do contrato".

**Sinal vermelho automático para reviewer:** se o diff toca um teste E uma impl no mesmo commit, descrever no PR description **qual contrato mudou e por quê**.

### §2.4 — Equatable contract (ENCAPSULATION_POLICY §Value vs Reference)

Source-of-truth: `handbook/architecture/ENCAPSULATION_POLICY.md` (linhas 29-128).

**must_fix**:
- ❌ DTO / VO / Domain model / Data record sem `with Equatable` + `props` cobrindo todos os campos final.
- ❌ Service / Repository / UseCase / ViewModel / Store / Handler / Middleware **com** Equatable. Reference types nunca usam value equality.
- ❌ `with Equatable` mas `props` incompleto (campo final não listado) — silenciosamente quebra equality.

**Pergunta-pivô:** "duas instâncias com o mesmo conteúdo deveriam ser iguais?" Se sim → Equatable obrigatório. Se não → Equatable proibido.

### §2.5 — Auth & Session policies (skill `auth-session-security`)

Source-of-truth: `.claude/skills/auth-session-security/SKILL.md`.

**must_fix (ACDG-específico)**:
- ❌ Cookie de sessão sem prefixo `__Host-` em web. Cookie name DEVE ser `__Host-session`.
- ❌ Cookie de sessão sem `HttpOnly; Secure; SameSite=Strict`. Browser NUNCA ve token.
- ❌ Browser tendo acesso a JWT, Refresh Token, Client Secret, Backend URL — Iron Frontier viola.
- ❌ JWT validation aceitando `alg: none`, `alg: HS256` quando se espera RS256, ou skipping `iss`/`aud`/`exp`.
- ❌ Rota protegida sem middleware de auth wired (P0-1 anonymous bypass).
- ❌ 401 body diferenciado entre paths de rejeição (oracle leak) — todo 401 DEVE ser idêntico em status + body + headers.
- ❌ Adicionar header `WWW-Authenticate` em respostas 401 — decisão deliberada do projeto, comunica realm ao atacante.
- ❌ Localstorage / sessionStorage / cookie acessível por JS armazenando token.

**should_fix**:
- PKCE verifier sem TTL 5min ou sem cap de entries (max 1000).
- Session sem `expiresAt` field auto-purgado.
- Logging de tentativa de auth contendo o token, user agent puro, ou IP sem hash.

### §2.6 — API security (skill `api-security-guardian`)

Source-of-truth: `.claude/skills/api-security-guardian/SKILL.md`.

**must_fix (ACDG-específico)**:
- ❌ Mutação (POST/PUT/DELETE) ao backend sem header `X-Actor-Id` (auditoria).
- ❌ Mutação POST/PUT/DELETE no BFF web SEM `X-Requested-With: XMLHttpRequest` (CSRF protection).
- ❌ CSP com `unsafe-inline` ou sem nonce (`<Style nonce={...} />` é o canon).
- ❌ Headers `HSTS` + `X-Content-Type-Options: nosniff` + `X-Frame-Options: DENY` ausentes em qualquer middleware de saída.
- ❌ Validação de input no BFF AUSENTE — todo body de mutation deve passar por smart constructor antes do proxy.
- ❌ Backend URL ou client secret em qualquer arquivo `lib/` (deve vir de env compile-time `--dart-define-from-file=.env`).

### §2.7 — AppSec code review (skill `appsec-code-reviewer`)

Source-of-truth: `.claude/skills/appsec-code-reviewer/SKILL.md`.

10-dimension checklist (mesma do reviewer interno):

1. **Input Validation** — whitelist, validate Content-Type, size limits, parametrize.
2. **Output Encoding** — no concat HTML, no `dangerouslySetInnerHTML`, JSON `Content-Type` explicit.
3. **Auth/Authz** — bcrypt cost ≥12 / Argon2id, JWT claim checks, rate limit on login, role checks per resource (não só por role global).
4. **Data Protection** — `.env` no `.gitignore`, sem hardcoded secrets, logs sem PII, errors sem stack interno.
5. **SQL/NoSQL** — parametrized queries, ORM sem raw concat, NoSQL não aceita object do body direto.
6. **Dependency Health** — sem vulns conhecidas (CVE), pinned versions.
7. **HTTP Headers** — HSTS, CSP nonce, no-sniff, frame-deny, no `WWW-Authenticate` no 401 (decisão ACDG).
8. **Error Handling** — generic messages, no stack leak, defined panics com breadcrumb.
9. **File Operations** — path traversal protection, sandbox.
10. **CSRF** — token / sameSite + custom header, mutações exigem `X-Requested-With`.

### §2.8 — Decision Heuristics (`handbook/principles/DECISION_HEURISTICS.md`)

Source-of-truth: `handbook/principles/DECISION_HEURISTICS.md`.

**should_fix (judgment heuristics)**:
- **H1** — Refactor cirúrgico vs eager broad: aplicar quando <50% consumers precisam OU mudança é estética. NÃO aplicar quando é invariante OU >80% precisam.
- **H2** — Test the contract not the implementation: tests devem assert outcomes contratuais, não fields internos do patch local.
- **H3** — Constructor uniformity: manter params canônicos do pattern mesmo quando uma variant não usa todos (forward-compat valuable).
- **H4** — Cross-cutting boundary scoping: regra que se manifesta em N camadas → mapear quem testa qual boundary, evitar god-test.
- **H5** — Cross-layer Clock injection: TTL/staleness compartilhada por 2+ layers exige Clock injetável em ambas (não só na leitura).
- **H6** — `abstract interface class` para test fakes — proíbe `extends`, elimina fallback insidioso `super.now()`.

### §2.9 — Pattern Matching idioms (PATTERN_MATCHING_POLICY §P1-P4)

Source-of-truth: `handbook/architecture/PATTERN_MATCHING_POLICY.md` (linhas 1-618).

**should_fix** (estilo Dart 3 idiomático):
- **P1** — `if/else` encadeado com 2+ booleanos → switch com Record `(a, b, c)`. Compilador força exhaustividade.
- **P1** — `_ =>` catch-all em switch sobre tipo finito (enum, sealed) — cega o compilador. Use `_` apenas em **posição** de tupla, nunca na regra inteira.
- **P1** — `when` com chamada de função complexa — extrair booleano antes; switch só roteia.
- **P2** — Cast `as` + check manual em Map/JSON → `if case {chave: Tipo valor}`.
- **P2** — `is Tipo && x.campo == valor` → `if case Tipo(campo: valor, :final outro)`.
- **P2b** — `try/catch` sobre `fromJson` SÓ em adapter + DTO ≥10 campos OU PII-sensível. Sempre `catch (e, st)` + `obs?.logError` + `_XxxParseError` privado com toString fixo. **`catch (_)` é must_fix.**
- **P3** — `(x) => Foo.bar(x)` em `.map()` → tear-off `Foo.bar`.
- **P4** — `throw` espalhado em domain rules → função `Never domainError(...)` centralizada com Sentry/log.

---

## §3 — Auto-discovery: paths tocados → policies anexar

Tabela de roteamento usada pelo orchestrator. Cada linha: **se o diff toca** path X, **anexar** as policies/skills listadas (§2.N) ao styleGuide. "Integral" = anexar source-of-truth completo no `context`. "Resumo" = colar só a §2.N.

| Diff toca path... | Anexar (resumo) | Anexar (integral) |
|---|---|---|
| `**/middleware/**`, `**/handlers/**`, `**/routes/**`, `bff/**` | §2.1, §2.2, §2.5, §2.6, §2.7 | — |
| `**/auth/**`, `**/session*`, `**/jwt*`, `**/oidc*` | §2.5, §2.7 | `auth-session-security/SKILL.md` |
| `**/intents/**`, `**/parsers/**`, `**/dtos/**`, `**fromJson*` | §2.1, §2.2, §2.9 (focar P2/P2b) | — |
| `**/use_cases/**`, `**/usecases/**`, `**/commands/**` | §2.1, §2.2, §2.4, §2.8 | — |
| `**/services/**`, `**/repositories/**`, `**/adapters/**` | §2.1, §2.4, §2.7 | — |
| `**/domain/**`, `**/models/**`, `**/value_objects/**` | §2.2, §2.4, §2.9 | `ENCAPSULATION_POLICY.md` (§29-128 obrigatório) |
| `**/cache/**`, `**/store/**`, `**/sync*` | §2.4, §2.8 (H5 Clock) | — |
| `**/test/**`, `**/*_test.dart` | §2.3 (REGRA #2), §2.1 (exceção testes) | `CLAUDE.md` (REGRA #2 verbatim) |
| `pubspec.yaml`, `pubspec.lock` | §2.7 (Dependency Health) | — |
| `**/Dockerfile`, `**/.github/workflows/**` | skill `devsecops-pipeline` | — |
| `**/cli/**`, `apps/cli/**` | skill `cli-craftsman` | — |
| Qualquer arquivo `.dart` em produção (`lib/`) | §2.1 (P5), §2.2, §2.4 SEMPRE | — |

**Heurística adicional (manual):** se o ticket é **security-remediation** (Phase 6), SEMPRE anexar §2.5, §2.6, §2.7 integrais — independente do path tocado.

---

## §4 — Spec template (perguntas adversariais NO TOPO)

Template para o parâmetro `spec` do `ai_gemini_review`. Cole literal e edite o que está entre `<<...>>`:

```
# Adversarial Review Brief — ticket <<ID>>

## Q1 — Adversarial questions FIRST (answer these EXPLICITLY in your output)

<<Lista 3-7 perguntas específicas que o orchestrator quer que o LLM bata. Exemplos:
- O patch fecha completamente <<vuln-X>>? Existe caminho lateral via <<route-Y>> que ainda <<bypass>>?
- O oracle único do 401 vaza por timing (rota rápida sem crypto vs rota com RSA verify)?
- A ordem do pipeline (<<m1 → m2 → m3>>) é necessária e suficiente? E se <<m2>> rodar antes de <<m1>>?
- StateError vs assert — assert é stripped em release; StateError sempre joga. A escolha é defensiva correta?
- O patch introduz dead code? Test cheating (CLAUDE.md REGRA #2)?
- Qualquer violação de must_fix categorias listadas no styleGuide §1.>>

## Q2 — Context

<<Resumo 3-5 frases: o que é o ticket, qual a vulnerabilidade que fecha, qual o reviewer interno já aprovou (ou não).>>

## Q3 — What this patch is supposed to do

<<Bullet list: arquivos tocados, intent de cada mudança.>>

## Q4 — What this patch is NOT supposed to do

<<Lista de coisas FORA do escopo do bundle, para o LLM não levantar finding "fora do escopo".>>

## Q5 — Compliance targets specific to this ticket

<<Liste must_fix categories §1 que são HOT na review deste ticket. Ex: "must_fix #5 (auth bypass) é o foco"; ou "must_fix #1 (Result discipline) é menos relevante porque o patch é em adapter shelf".>>

## Q6 — How to deliver

Verdict: approved | rejected | partial_review (set partial_review:true se diff truncado/incompleto).
For each finding: severity (must_fix | should_fix | info), file path, line, rule citation (with §N.M reference to charter), recommendation.
Be terse. NO findings without exact line citation. NO findings without rule reference.
```

---

## §5 — Failsafe protocol (filtragem de output do LLM)

Após receber resposta do LLM externo, o orchestrator DEVE:

1. **Verificar `partial_review` flag.** Se TRUE → ler quais arquivos/comentários não chegaram, decidir se re-roda com payload completo ou aceita parcial com nota explícita.
2. **Cross-check cada finding contra o source code real** (não contra o diff submetido). Falsos positivos por truncagem são comuns — sempre verificar com `Read` do arquivo no working tree antes de incluir no relatório final.
3. **Para cada finding marcado `must_fix`:** verificar se o rule citation aponta para regra REAL no charter (§1 ou §2.N). Se não → o LLM inventou. Reportar como falso positivo.
4. **Findings extras gerados pelo orchestrator** (e.g., timing oracle, EXT-* findings) DEVEM ser claramente atribuídos no relatório final como "orchestrator review", não "LLM externo review".

---

## §6 — Manutenção do charter

Quando uma policy do projeto muda:

1. **Editar o documento source-of-truth** (`*POLICY.md`, `SKILL.md`, etc.) primeiro.
2. **Atualizar §2.N deste charter** com os bullets DO/DON'T atualizados.
3. **Atualizar §3** se a regra de auto-discovery mudar (path tocado → policy anexar).
4. **Mencionar em PR description** algo como "charter §2.N updated to reflect ENCAPSULATION_POLICY change".

Se uma policy é adicionada (novo doc):

1. Decidir se é must_fix (vai pra §1) ou should_fix (vai pra §2 com label).
2. Adicionar entrada nova em §2.
3. Adicionar linha em §3 com path patterns e severidade.
4. Atualizar `MEMORY.md` se a convenção de auto-discovery mudou.

---

## §7 — Reprodutibilidade auditável

Para CADA invocação de `ai_gemini_review`, o orchestrator DEVE produzir, dentro de `.pipeline/<ticket>/external-review/`:

- `STYLE_GUIDE_SUBMITTED.md` — exatamente o styleGuide passado ao LLM (snapshot deste charter + anexos integrais).
- `SPEC_SUBMITTED.md` — exatamente o spec passado.
- `DIFF_SUBMITTED.diff` — exatamente o diff passado (com nota de truncagem se aplicável).
- `LLM_RESPONSE_RAW.json` — output raw do LLM (lido de `.pipeline/<ticket>/ai-outputs/`).
- `EXTERNAL-REVIEW.md` — relatório final consolidado (orchestrator + LLM, com filtragem §5 aplicada).

Esse layout permite re-rodar a review meses depois com mesmos inputs e validar se o output muda — é a forma de detectar drift do LLM ou do charter.

---

## §8 — Histórico

| Data | Mudança | Trigger |
|---|---|---|
| 2026-05-07 | Charter criado. §1-§7. | Lição da rodada B1 — Gemini Flash gerou 4/5 falsos positivos por truncagem do diff. Necessidade de garantir que policies do projeto cheguem ao LLM externo de forma compacta e auditável. |

---

## §9 — Apêndice: índice mestre de fontes-de-verdade

| Doc | Path absoluto | Tamanho aprox | Coberto em §2 |
|---|---|---:|---|
| CLAUDE.md (root rules) | `/Users/gabriel_aderaldo/Desktop/Projetos/dev/envolve/acdg/frontend/CLAUDE.md` | 10KB | §2.3 |
| ENCAPSULATION_POLICY | `handbook/architecture/ENCAPSULATION_POLICY.md` | (consulte) | §2.2, §2.4 |
| PATTERN_MATCHING_POLICY | `handbook/architecture/PATTERN_MATCHING_POLICY.md` | 50KB+ | §2.1, §2.9 |
| AGENT_TESTING_POLICY | `handbook/architecture/AGENT_TESTING_POLICY.md` | (consulte) | §2.3 |
| CONCURRENCY_AND_PERFORMANCE_POLICY | `handbook/architecture/CONCURRENCY_AND_PERFORMANCE_POLICY.md` | (consulte) | (não coberto, anexar integral se diff toca async/isolate) |
| DECISIONS.md (ADRs) | `handbook/architecture/DECISIONS.md` + `DECISIONS/*.md` | (consulte) | (anexar ADR específico se mencionado no ticket) |
| DECISION_HEURISTICS | `handbook/principles/DECISION_HEURISTICS.md` | 18KB | §2.8 |
| ARCHITECTURAL_GOLD_STANDARD | `handbook/principles/ARCHITECTURAL_GOLD_STANDARD.md` | (consulte) | (anexar se ticket é arquitetural) |
| HANDBOOK_AS_SOURCE_OF_TRUTH | `handbook/principles/HANDBOOK_AS_SOURCE_OF_TRUTH.md` | (consulte) | (informativo apenas) |
| skill auth-session-security | `.claude/skills/auth-session-security/SKILL.md` | 30KB+ | §2.5 |
| skill api-security-guardian | `.claude/skills/api-security-guardian/SKILL.md` | 30KB+ | §2.6 |
| skill appsec-code-reviewer | `.claude/skills/appsec-code-reviewer/SKILL.md` | 30KB+ | §2.7 |
| skill flutter-expert | `.claude/skills/flutter-expert/SKILL.md` | 50KB+ | (anexar se diff é Flutter UI) |
| skill llm-ai-security | `.claude/skills/llm-ai-security/SKILL.md` | (consulte) | (anexar se ticket envolve LLM/RAG) |
| skill devsecops-pipeline | `.claude/skills/devsecops-pipeline/SKILL.md` | (consulte) | (anexar se diff toca CI/CD/Docker) |
| skill cli-craftsman | `.claude/skills/cli-craftsman/SKILL.md` | (consulte) | (anexar se diff toca apps/cli/) |
| skill threat-modeler | `.claude/skills/threat-modeler/SKILL.md` | (consulte) | (anexar para arquitetura review) |
| skill red-team-scanner | `.claude/skills/red-team-scanner/SKILL.md` | (consulte) | (anexar para pentest review) |

**Skills NÃO listadas acima** existem em `.claude/skills/` mas não são tipicamente acionadas em external review (e.g., `dart-collect-coverage`, `dart-resolve-package-conflicts` — são tooling helpers, não policies).

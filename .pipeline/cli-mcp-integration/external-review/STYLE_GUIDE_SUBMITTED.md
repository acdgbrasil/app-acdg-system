# ACDG Project — Mandatory Compliance Targets

You are reviewing code from the ACDG frontend monorepo (Dart/Flutter, apps/cli/ é Phase 5). Your role is SECONDARY — internal reviewers (W4 flutter-code-reviewer + W5 flutter-quality-checker) ALREADY ran and APPROVED. Your job is to find what the internal reviewers MISSED, NOT to re-validate basics.

## Severity scale

- `must_fix` — violates a hard project policy listed below. Blocks merge.
- `should_fix` — violates a soft convention or improves robustness. Reviewer judgment.
- `info` — observation only.

## must_fix categories

1. **`Result<T>` discipline** — NO `as Success<T>` / `as Failure<T>` cast in production. NO `valueOrNull!`. Use switch / map / flatMap / combineWith. Defended by lint `acdg_lints/no_sealed_class_downcast`. Bypass via `// ignore: no_sealed_class_downcast` is must_fix.
2. **Throw policy** — `throw` PROHIBITED in domain/application layers. Permitted ONLY at adapter boundary, and MUST be a defined panic with breadcrumb (StateError / ArgumentError) — NEVER bare `Exception` or `throw 'string'`. `catch (_)` reject — must always `catch (e, st)`.
3. **Test cheating (CLAUDE.md REGRA #2)** — moving a red test, swallowing with `try/catch`, replacing `expect(X)` with `expect(anyOf(...))` without justification, `@Skip` without explicit "REGRA #2 accepted" comment.
4. **PII / secret leak** — CPF/CNS/NIS/RG/tokens/JWT/refresh-token/access-token in logs, error messages, exception toString(), browser-visible JSON, or AI host responses. Stack trace must NEVER reach `CallToolResult`.
5. **Auth bypass** — protected route reachable without authentication, or with wrong role. Pipeline order load-bearing.
6. **Equatable contract** — value types (DTO, VO, domain model, sealed variant) MUST `with EquatableMixin` + `props` covering ALL final fields. Reference types (Service, Repository, UseCase, ViewModel, Store, Adapter, Registry, Logger setup) MUST NOT mix in Equatable. Pivotal question: "should two instances with the same content be equal?"
7. **Sealed-class downcast** — defended by lint. Use exhaustive `switch` over sealed family.
8. **Single-oracle constants** — error codes, body bytes, context keys MUST have ONE source. Duplication only allowed when explicitly anchored by `// SEC:` annotation citing the cross-bundle invariant.

## How to report

For EACH must_fix finding: file path, line, the verbatim rule it violates (cite charter section §N or skill name), fix recommendation.
For EACH should_fix finding: same plus rationale.

## Failsafe

If the diff payload is incomplete (e.g., comments stripped, partial files only), say so EXPLICITLY in the summary as `partial_review: true` with a list of what is missing. Do NOT guess. False positives caused by missing context are worse than no findings.

---

## §2.1 — `Result<T>` discipline (PATTERN_MATCHING_POLICY §P5)

Source-of-truth: `handbook/architecture/PATTERN_MATCHING_POLICY.md` (§619+).

**must_fix**:
- ❌ `(result as Success<T>).value` em arquivos de produção (lib/).
- ❌ `result.valueOrNull!` em produção — bypass equivalente sem stack trace útil.
- ❌ Inventar `guard()` / `andThen()` / `unwrap()` em qualquer package que não seja `core_contracts`. Use `flatMap` / `map` / `combineWith` JÁ EXISTENTES.
- ❌ `Failure(error)` sem propagar `stackTrace` em combinator novo. Use `Failure(error, stackTrace: stackTrace)`.
- ❌ `// ignore: no_sealed_class_downcast` em produção.

**should_fix**:
- Cadeia 4+ `flatMap` aninhados — sinal de Intent inflado.
- Side-effect (log, dispatch) DENTRO do closure de `combineWith`/`map`/`flatMap`.

**Exceção (testes):** em `*_test.dart` o cast `as Success<T>` é a forma canônica de fail-fast. Switch defensivo em test = must_fix (esconde regressão).

---

## §2.2 — Throw policy + Defined panic (ENCAPSULATION_POLICY)

**must_fix**:
- ❌ `throw` em camada `domain/` ou `application/` (zero-throw). Tudo retorna `Result<T, E>`.
- ❌ `throw Exception(...)` ou `throw 'string'`. Use `StateError` (invariante violado), `ArgumentError` (input inválido), ou erros tipados privados (`_XxxParseError`).
- ❌ `catch (_)` que descarta cause + stackTrace. Reprovação automática.
- ❌ Mensagem de erro que ecoa input do usuário (`"Invalid value $cpf"`) — PII leak.
- ❌ Mensagem de erro que enumera campos missing (`"field X is required"`) — shape leak.

**should_fix**:
- Throw em adapter boundary sem `// SEC:` ou comentário explicando o defined panic.
- Mensagem genérica sem breadcrumb de operação.

---

## §2.3 — Test cheating (CLAUDE.md REGRA #2 verbatim)

> Diante de teste vermelho, **PARE e verbalize ao usuario os 4 pontos abaixo** antes de propor qualquer mudanca:
> 1. **Intencao:** o que o teste estava tentando provar?
> 2. **Falha:** por que ele esta falhando agora?
> 3. **Veredicto:** a falha e da implementacao, da expectation do teste, ou de ambiguidade no design?
> 4. **Opcoes:** liste no minimo 2 caminhos para resolver. Nao escolha sozinho.
>
> **Anti-patterns proibidos:**
> - Mover o teste para um caso onde ele passe sem documentar abandono.
> - Trocar `expect(404)` por `expect(anyOf(404, 500))` sem entender o 500.
> - Comentar/skipar teste sem comentario explicito de "REGRA #2: aceito como debito porque <motivo>".
> - Adicionar `try/catch` na impl so para fazer teste passar.
> - Reescrever teste para "afirmar o que a impl faz" em vez de "afirmar a intencao do contrato".
>
> **Excecao:** quando o teste foi escrito de forma comprovadamente errada (typo no nome de campo, fixture invalida, etc) — corrigir e seguir, mencionando a correcao no commit.

**No diff submetido**, há UMA mudança de teste flagged como REGRA #2 exception: `e2e_stdio_test.dart:172-173` — `StreamController()` → `StreamController.broadcast()`. **Justificativa do W3 (verificada por W4):** `request()` chama `firstWhere` repetidamente em 4 chamadas JSON-RPC sequenciais; single-subscription stream lança `Bad state` na 2ª chamada. **W4 verdict:** legítima fixture-bug.

---

## §2.4 — Equatable contract (ENCAPSULATION_POLICY §Value vs Reference)

**must_fix**:
- ❌ DTO / VO / Domain model / Data record sem `with Equatable` + `props`.
- ❌ Service / Repository / UseCase / ViewModel / Store / Handler / Middleware **com** Equatable.
- ❌ `with Equatable` mas `props` incompleto.

**Pivotal question:** "deveriam X(a) == X(a) retornar `true`?"

**No diff submetido**, classes a verificar:
- `McpToolDefinition` — value type, `with EquatableMixin` + props (DESIGN §2.5). Verificar se props cobrem name/description/requiredRoles (W4 F2 catalogou que props EXCLUEM `inputSchema`).
- `McpServerAdapter` / `McpToolRegistry` / handlers / `McpLoggerSetup` / `McpErrorMapper` — reference types, sem Equatable.
- `McpAdapterError` + 4 subtypes — sealed family. Subtypes carregam `message` final — verificar contract.

---

## §2.5 — Auth & Session policies (skill `auth-session-security`)

Source-of-truth: `.claude/skills/auth-session-security/SKILL.md`.

**ACDG-specific**:
- Zitadel OIDC PKCE, 3 roles: `social_worker` (CRUD), `owner` (read-only), `admin` (read+gestão).
- Cookie `__Host-session` (HttpOnly, Secure, SameSite=Strict).
- Bearer JWT RS256 only (JWKS via Zitadel `https://auth.acdgbrasil.com.br/oauth/v2/keys`).
- BFF web: Confidential Client OIDC — browser NUNCA vê tokens.
- Desktop/CLI: Split-Token Pattern: Access Token em memória/keychain, Refresh Token em flutter_secure_storage / OS keychain.

**must_fix**:
- ❌ Cookie sem prefixo `__Host-` em web. ❌ Cookie sem `HttpOnly; Secure; SameSite=Strict`.
- ❌ Browser tendo acesso a JWT/Refresh Token/Client Secret/Backend URL.
- ❌ JWT validation aceitando `alg: none`, `alg: HS256` quando esperado RS256.
- ❌ Rota protegida sem middleware de auth.
- ❌ 401 body diferenciado entre paths de rejeição.
- ❌ Localstorage/sessionStorage/cookie acessível por JS armazenando token.

**No diff submetido**, MCP server expõe 5 tools com RBAC declarativo. Atenção:
- Tools `health` e `auth.status` têm `requiredRoles: {}` (no auth) — válido?
- Tools `patient.list/get`, `lookup.get` exigem `{social_worker, owner, admin}`.
- Sessão herdada do XDG keychain via `CredentialStore.read()`. Tool sem session → "Authentication required". Sem role válido → "Forbidden".

---

## §2.7 — AppSec code review checklist (skill `appsec-code-reviewer`)

10-dimension checklist:

1. **Input Validation** — JSON Schema antes do handler. Whitelist. Limits (max 50 em `patient.list`).
2. **Output Encoding** — JSON Content-Type explícito. Stack trace NUNCA em CallToolResult.
3. **Auth/Authz** — RBAC por tool, declarado em `requiredRoles`.
4. **Data Protection** — `.env` no `.gitignore`, sem hardcoded secrets, logs sem PII (CPF/CNS/NIS), tokens nunca em log.
5. **SQL/NoSQL** — N/A (CLI delega ao BFF).
6. **Dependency Health** — `dart_mcp: 0.5.1` PIN sem caret, lockfile commitado.
7. **HTTP Headers** — N/A para MCP stdio.
8. **Error Handling** — generic messages, no stack leak, defined panics com breadcrumb.
9. **File Operations** — N/A.
10. **CSRF** — N/A para stdio.

---

## §2.8 — Decision Heuristics (`handbook/principles/DECISION_HEURISTICS.md`)

**should_fix (judgment)**:
- **H1** — Refactor cirúrgico vs eager broad: <50% consumers precisam OU mudança estética → cirúrgico. >80% OU invariante → broad.
- **H2** — Test the contract not the implementation: tests devem assertar outcomes contratuais, não fields internos.
- **H3** — Constructor uniformity para variantes do mesmo pattern.
- **H4** — Cross-cutting boundary scoping: cada layer cuida do seu boundary; não god-tests.
- **H5** — Cross-layer Clock injection.
- **H6** — `abstract interface class` para test fakes.

---

## §2.9 — Pattern Matching idioms (PATTERN_MATCHING_POLICY §P1-P4)

**should_fix** (Dart 3 idioms):
- **P1** — `if/else` com 2+ booleanos → switch com Record. `_ =>` catch-all em sealed cega o compilador.
- **P2** — Cast `as` em Map/JSON → `if case {chave: Tipo valor}`. `is X && x.campo == valor` → `if case X(campo: valor, :final outro)`.
- **P2b** — `try/catch` sobre `fromJson` SÓ em adapter + DTO ≥10 campos. Sempre `catch (e, st)` + `obs?.logError` + `_XxxParseError` privado com toString fixo. `catch (_)` é must_fix.
- **P3** — `(x) => Foo.bar(x)` em `.map()` → tear-off `Foo.bar`.
- **P4** — `throw` espalhado → função `Never domainError(...)` centralizada.

---

## ENCAPSULATION_POLICY — extract relevante (Throw Policy + Sealed)

> ### Throw Policy
> - `throw` é PROIBIDO em camadas `domain/` e `application/` (zero-throw policy do projeto ACDG).
> - `throw` é permitido APENAS em adapter boundary (`shelf middleware`, `dart:io`, `Process.start`, parsers de fronteira).
> - Quando usado em adapter, DEVE ser:
>   - **Defined panic com breadcrumb**: `throw StateError('ClassName.method called on X — invariant Y violated')`.
>   - **Tipo concreto, nunca `Exception`**: `StateError`, `ArgumentError`, ou erro tipado privado.
> - **`// SEC:` annotation** no throw para documentar a invariante violada.
>
> ### Sealed family discipline
> - Use `sealed class` para hierarquias finitas conhecidas em compile-time.
> - `switch` sobre sealed deve ser EXAUSTIVO (sem `_ =>` catch-all).
> - Cada subtipo é `final class` (não permite extensão fora do file).
> - Cada subtipo carrega seus campos específicos imutáveis.
> - Adicionar novo subtipo aciona compile-time check em todos os switches.

---

## CLI Craftsman — extract relevante (10 Pillars cli-guidelines.org)

Source-of-truth: `.claude/skills/cli-craftsman/SKILL.md`.

**Aplicáveis ao MCP serve command**:
- **Pillar 5: Output formats** — JSON output deve ser válido e parseável; stderr para mensagens humanas; stdout para data/protocol.
- **Pillar 6: Errors** — exit codes seguindo sysexits.h (64 EX_USAGE, 70 EX_SOFTWARE, 74 EX_IOERR, etc.).
- **Pillar 8: Configuration** — flags / env / args. `--bff` / `--output` honrados.
- **NO_COLOR / TTY** — autodetect; respeitar pipe → JSON.

**No diff submetido**, MCP serve mode tem regra mais estrita:
- stdout RESERVADO para JSON-RPC (canal MCP).
- stderr para `package:logging` output.
- NÃO escrever texto humano em stdout em modo MCP.

---

## Project context — diff scope summary

Ticket: `cli-mcp-integration` v2 (v1 archived em `_archived-2026-05-07/` com 7 falhas estruturais).

**Scope:** integrar `dart_mcp` v0.5.1 oficial (Google) ao ACDG CLI, expondo 5 tools read-only via stdio MCP server.

**Pacote:** `dart_mcp 0.5.1` PIN sem caret. Audit em `handbook/audit/2026-05-07-mcp-package-reaudit.md` (re-auditoria reverteu decisão prévia que era `mcp_dart` v2.1.1).

**Tools MVP:**
| Tool | requiredRoles |
|---|---|
| `health` | `{}` |
| `auth.status` | `{}` |
| `patient.list` | `{social_worker, owner, admin}` |
| `patient.get` | `{social_worker, owner, admin}` |
| `lookup.get` | `{social_worker, owner, admin}` |

**Architecture:** boundary adapter pattern. `dart_mcp` import isolado em `lib/src/mcp/` (8 arquivos importam — registry+5 handlers+definition+adapter; ADR-MCP-003-v2 trade-off documentado).

**Pipeline waves:**
- W2 RED: 23 tests escritos (test-writer).
- W3 GREEN: 838 tests, AOT 7.9MB, 1 fixture-bug fix flagged (StreamController → broadcast).
- W4 REVIEW: APPROVED + 4 should_fix (mcp_tool_registry sealed exhaustivity, mcp_tool_definition props doc mismatch, EquatableMixin doc terminology, import order).
- W5 QUALITY: PASSED + 1 warning (format gap em test/, resolved).

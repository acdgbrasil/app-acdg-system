# Re-auditoria: Pacote MCP para ACDG CLI

> **Data:** 2026-05-07
> **Trigger:** ticket cli-mcp-integration reaberto. Audit anterior (2026-05-06) recomendou `mcp_dart` v2.1.1 com base em features (HTTP, OAuth, SSE). Mas ADR-MCP-002 já fixou **stdio-only** — todas as features extras viram apenas superfície de ataque sem benefício.
> **Metodologia:** aplicar EXTERNAL_REVIEW_CHARTER §1 (8 must_fix categories) sobre os dois candidatos. O critério "features que não usaremos" é descartado; o critério "superfície + supply chain + strict typing" passa a dominar.
> **Documento anterior:** `handbook/audit/2026-05-06-mcp-packages-audit.md` — referência factual mantida (LOC, deps, etc); apenas o veredicto é re-julgado.

---

## §1 — Premissas re-fixadas

| Premissa | Valor |
|---|---|
| Transport | **STDIO apenas** (ADR-MCP-002). HTTP/SSE/WebSocket fora do escopo. |
| Auth do MCP server | OIDC herdado do XDG store + RBAC por tool. **Não** usa OAuth do pacote. |
| Compile target | AOT exclusivo (`dart compile exe`). |
| Threat model | AI host (Claude Desktop, Cursor, ChatGPT) é processo **untrusted** por convenção LGPD. Pacote MCP é boundary adapter — não dá ao pacote acesso direto a nada do domain. |
| Escopo MVP | 5 tools read-only (health, auth.status, patient.list, patient.get, lookup.get). |
| Critério de superfície | Cada KB de `lib/` do pacote = código a auditar a cada upgrade. Cada `dynamic` = potencial cast failure em runtime. |

Com essas premissas, **as features que motivaram a recomendação anterior (HTTP, OAuth, SSE, IOStream) são irrelevantes ou negativas**.

---

## §2 — Aplicando os 8 `must_fix` categories do Charter

### MFC#1 — `Result<T>` discipline
- `dart_mcp`: usa `try/catch`; pacote externo, esperado.
- `mcp_dart`: usa `try/catch`; pacote externo, esperado.
- **Veredicto: empate.** Boundary adapter converte ambos para `Result<T>` na fronteira. Nenhum pacote satisfaz nativamente; nosso adapter resolve.

### MFC#2 — Throw policy + Defined panic
- `dart_mcp`: throws explícitos com `catch (e, s)` consistente.
- `mcp_dart`: `catch (e)` SEM `s` "em muitos lugares" (audit §3.2 — "Tratamento de erros inconsistente"); conversão genérica para `StateError`.
- **Veredicto: dart_mcp vence.** Stack trace preservado nos throws permite mapeamento limpo no nosso `McpErrorMapper`. Em `mcp_dart` perdemos contexto.

### MFC#3 — Test cheating
- N/A para pacote externo.

### MFC#4 — PII / secret leak
- `dart_mcp`: protocol log sink loga JSON completo. **Erros de tool default expõem stack trace ao cliente** (audit §4.5: `'$e\n$s'`). **Risco alto se não for sobrescrito.**
- `mcp_dart`: logger sem redação automática. Tokens podem vazar para logs.
- **Ambos têm leak risk.** Nosso adapter precisa override em ambos os casos. **`dart_mcp` é mais perigoso por default** mas o override é trivial (`onCallToolError: (e, s) => CallToolResult(isError: true, content: [TextContent(text: 'tool failed')])`).
- **Veredicto: empate operacional** — ambos exigem hardening explícito no adapter; checklist deve cobrir.

### MFC#5 — Auth bypass
- N/A para transport-level. Auth é nossa responsabilidade no `McpToolRegistry` antes de executar a tool.

### MFC#6 — Equatable contract
- N/A para pacote externo.

### MFC#7 — Sealed-class downcast
- `dart_mcp`: usa **extension types** (Dart 3) sobre `Map<String, Object?>` para zero-cost wrappers. Cleanup elegante; sem downcast.
- `mcp_dart`: usa **sealed classes extensivas** (`JsonRpcMessage`, `Content`, `ToolCallback`) com pattern matching exaustivo. Boa prática; sem downcast aparente.
- **Veredicto: empate; ambos seguem práticas modernas.** Em uso real (nosso código consumindo), `dart_mcp` extension types tendem a ser mais previsíveis (sem subtyping); `mcp_dart` sealed exige `switch` exhaustive (mais verboso).

### MFC#8 — Single-oracle constants
- N/A para pacote externo.

---

## §3 — `should_fix` categories (decisivos no empate técnico)

| Critério | dart_mcp | mcp_dart | Vantagem |
|---|---:|---:|:-:|
| Total `dynamic` em lib/ | **2** | 739 | dart_mcp ✅ |
| `strict-casts` no analysis_options | **ON** | OFF | dart_mcp ✅ |
| `strict-inference` | **ON** | OFF | dart_mcp ✅ |
| `strict-raw-types` | **ON** | OFF (comentado) | dart_mcp ✅ |
| LOC `lib/` | **6.241** | 17.129 | dart_mcp ✅ (menos código a auditar) |
| Test/lib ratio | **70%** | 18% | dart_mcp ✅ |
| Publisher verificado pub.dev | **Sim (Google)** | Não (`leehack`) | dart_mcp ✅ |
| Deps runtime (transitivas) | 6 (~15 transitivas) | 1 (`http`, ~5 transitivas) | mcp_dart ⚠ |
| `runInShell:false` em Process spawn | N/A (não dá spawn) | OK | dart_mcp ✅ (zero attack surface) |
| Supply-chain risk (compromise probability) | Baixíssimo | Moderado | dart_mcp ✅ |
| Velocity de breaking change | Alta (v0.x) | Baixa (SemVer v2.x) | mcp_dart ✅ |

---

## §4 — Trade-off central

Há **uma única vantagem real** de `mcp_dart` sobre `dart_mcp`:

**SemVer estabilidade.** v0.x do dart_mcp pode introduzir breaking change a qualquer release; v2.x do mcp_dart promete estabilidade.

Toda outra dimensão favorece `dart_mcp`:
- Menos código (29 vs 57 arquivos, 6K vs 17K LOC).
- Strict modes ON em todos os flags.
- 365× menos `dynamic`.
- Publisher verificado.
- 4× mais test coverage relativo.
- Sem `Process.start` (zero attack surface de spawn).

**O risco de breaking change é mitigado por nosso boundary adapter.** Já desenhamos `McpServerAdapter` exatamente para isolar o pacote externo — se v0.6 do `dart_mcp` quebrar API, o impacto fica restrito a uma classe (`McpServerAdapter`). Pin de versão (`dart_mcp: 0.5.1`, sem caret) + lockfile + CI gate de upgrade fecha a equação.

---

## §5 — Veredicto

**Adotar `dart_mcp` v0.5.1 (oficial Google).**

Justificativa em uma frase: **para um BFF stdio-only num projeto LGPD onde o pacote MCP é um boundary externo, a superfície mínima + strict typing + supply chain verificado do `dart_mcp` superam a estabilidade SemVer do `mcp_dart` — porque nosso adapter já foi desenhado para absorver volatilidade de versão.**

### Hardening adicional necessário (independente do pacote)

| Hardening | Onde |
|---|---|
| Override `onCallToolError` para emitir mensagem genérica sem stack trace | `McpServerAdapter` |
| Logger sempre `stderr`/file — nunca `stdout` (colisão fatal com transport) | `McpServerAdapter` + `Logger` config no `McpServeCommand` |
| Validação de schema no `inputSchema` antes de executar tool | `McpToolRegistry` |
| RBAC enforcement antes de cada tool call | `McpToolRegistry` |
| Pin de versão exato (sem `^`) + lockfile commitado | `pubspec.yaml` |
| CI gate: `dart compile exe` deve suceder no PR | `.github/workflows/cli.yaml` |

### Mudanças no plano original

| Item | Antes (mcp_dart) | Agora (dart_mcp) |
|---|---|---|
| `pubspec.yaml` | `mcp_dart: 2.1.1` | `dart_mcp: 0.5.1` |
| Imports | `package:mcp_dart/mcp_dart.dart` | `package:dart_mcp/server.dart` etc |
| `McpServer` API | construtor `Implementation(name, version)` | `MCPServer with ToolsSupport` mixin |
| `Transport` | `StdioServerTransport` | `stdioChannel()` retorna stream channel |
| Tool registration | `server.registerTool(name, ...)` | `registerTool` via `ToolsSupport` mixin |
| Error model | `McpError` com `code`+`message` | tool retorna `CallToolResult(isError: true)` |
| Sealed JSON-RPC types | usados | extension types sobre Map |

---

## §6 — Anexo: charter §3 auto-discovery aplicado

Diff do ticket vai tocar:
- `apps/cli/pubspec.yaml` → MFC#7 (Dependency Health) — exigir pin
- `apps/cli/lib/src/mcp/**` (novo) → MFC#1, #2, #4, #6, #7 — boundary adapter, error mapper, tool registry, all final classes with proper Equatable contract
- `apps/cli/lib/src/cli_runner.dart` → cross-cutting (refator stdout sink injection); MFC#2 throw policy
- `apps/cli/lib/src/errors/cli_error.dart` → MFC#6 Equatable; MFC#2 (sealed family)
- `apps/cli/test/mcp/**` (novo) → MFC#3 test cheating + Result discipline em testes (PATTERN_MATCHING_POLICY §P5 exceção testes)

→ external review do ticket DEVE anexar (charter §3): §2.1, §2.2, §2.3, §2.4, §2.7, §2.8 + skill `appsec-code-reviewer` integral + skill `cli-craftsman` integral (porque toca `apps/cli/`).

---

## §7 — Histórico

| Data | Decisão | Razão |
|---|---|---|
| 2026-05-06 | Adotar `mcp_dart` v2.1.1 | Audit baseada em features (HTTP, OAuth) |
| 2026-05-07 | **Reverter para `dart_mcp` v0.5.1 oficial** | Premissa "stdio-only" torna features extras irrelevantes; charter §1 prioriza superfície + strict typing + supply chain |

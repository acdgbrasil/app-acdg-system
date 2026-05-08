# Pipeline: CLI-MCP-Integration (v2 — fresh)

> **Ticket:** CLI-MCP-INTEGRATION
> **Versão:** v2 (reescrito do zero em 2026-05-07).
> **Versão anterior arquivada em:** `_archived-2026-05-07/` — preservada como referência histórica + diagnóstico do que NÃO repetir.
> **Escopo MVP:** integrar `dart_mcp` v0.5.1 ao ACDG CLI e expor 5 comandos read-only como MCP tools (stdio).
> **Metodologia:** 6-Wave Pipeline (W0 discuss → W1 design → W2 tests RED → W3 impl GREEN → W4 review → W5 quality).
> **Pipeline canônico:** 4-agent BFF/CLI (test-writer → flutter-bff-implementer → flutter-code-reviewer → flutter-quality-checker), conforme memória `feedback_3_agent_pipeline.md`.
> **External review final:** charter `handbook/audit/EXTERNAL_REVIEW_CHARTER.md` aplicado em §1, §2.1, §2.2, §2.3, §2.4, §2.7, §2.8 + skill `appsec-code-reviewer` integral + skill `cli-craftsman` integral.

---

## Por que v2 — diagnóstico da v1

A v1 (arquivada em `_archived-2026-05-07/`) tinha 7 falhas estruturais:

1. **Stdio collision fatal** — `StdioServerTransport` usa `stdin/stdout` para JSON-RPC; commands escreviam `stdout` por `OutputFormatter`. Tool delegava ao `CliRunner` → corrupção do frame JSON-RPC. Não havia injeção real de StringSink (admitido como TODO no impl).
2. **Recursão de `CliRunner`** — registry recebia `this` do runner; tool handler chamava `_cliRunner.run([...])` — reentrância em estado mutável de `CommandRunner`.
3. **Logger no stdout default** — `_logger.info('MCP server started')` ia pro mesmo stdout do transport. Mesma colisão.
4. **`McpAdapterError` monolítico** — único subtype para tudo (parse / transport / tool fail / schema fail). Discriminação por string. Triage impossível.
5. **Sem modelo de auth/RBAC** — tool acessava sessão XDG sem checar role; AI host (untrusted) ganha acesso à sessão "ativa" do humano sem confirmação.
6. **Pacote off-target** — auditoria 2026-05-06 escolheu `mcp_dart` v2.1.1 por features (HTTP, OAuth) que ADR-MCP-002 já tinha eliminado (stdio-only). Re-auditoria 2026-05-07 reverte para `dart_mcp` oficial (Google).
7. **Sem teste de stdio real** — design previa apenas IOStreamTransport (in-memory), onde o bug #1 não aparece. E2E ausente.

A v2 elimina todos os 7 — ver `001-design/DESIGN.md` §"Diferenças vs v1".

---

## Decisões consolidadas (2026-05-07, com user)

| Decisão | Valor | Origem |
|---|---|---|
| Pacote MCP | **`dart_mcp` v0.5.1 oficial (Google)**, pin sem caret | `handbook/audit/2026-05-07-mcp-package-reaudit.md` |
| Escopo MVP | **5 tools read-only**: `health`, `auth.status`, `patient.list`, `patient.get`, `lookup.get` | User decision |
| Auth model | OIDC herdado do XDG keychain via `CredentialStore` + RBAC declarativo por tool | User decision |
| Stdio strategy | `CliRunner` JÁ aceita `IOSink` injetáveis (descoberto na auditoria de código). Tool handlers chamam `BffClient` direto, sem reentrância no `CommandRunner` | User decision (ajustada após mapeamento do código real) |

---

## Estrutura

```
cli-mcp-integration/
├── _archived-2026-05-07/        # v1 obsoleta — referência histórica, NÃO consultar como fonte de verdade
├── 000-discuss/CONTEXT.md       # W0 — threat model + decisões + ADRs
├── 001-design/DESIGN.md         # W1 — design end-state com classes e fluxos
├── 002-tests/REPORT.md          # W2 — RED tests (a escrever via test-writer)
├── 003-impl/REPORT.md           # W3 — GREEN impl (a escrever via flutter-bff-implementer)
├── 004-code-review/REVIEW.md    # W4 — defensive review (flutter-code-reviewer)
├── 005-quality/REPORT.md        # W5 — quality gates (flutter-quality-checker)
├── external-review/             # External review com Charter (post-W5)
└── README.md                    # Este arquivo
```

---

## ADRs (v2)

| ADR | Decisão | Status |
|-----|---------|--------|
| ADR-MCP-001-v2 | Pacote `dart_mcp` v0.5.1 oficial, pin sem caret | ✅ |
| ADR-MCP-002-v2 | Modo MCP Server stdio (mantido da v1) | ✅ |
| ADR-MCP-003-v2 | Boundary Adapter Pattern (mantido) | ✅ |
| ADR-MCP-004-v2 | Tool registration explícita, **sem delegação a `CliRunner`** | ✅ |
| ADR-MCP-005-v2 | Logger sempre stderr ou file — nunca stdout | ✅ |
| ADR-MCP-006-v2 | Sealed `McpAdapterError` com 4 subtypes | ✅ |
| ADR-MCP-007-v2 | RBAC declarativo por tool (`requiredRoles`) | ✅ |
| ADR-MCP-008-v2 | E2E test com stdio real (subprocess) — IOStream-only é insuficiente | ✅ |

---

## Quality gates (W5)

| Gate | Comando | Critério |
|---|---|---|
| Static analysis | `dart analyze apps/cli` | 0 issues |
| Format | `dart format --set-exit-if-changed apps/cli` | clean |
| Unit tests | `dart test apps/cli/test/mcp/` | 100% pass |
| AOT compile | `dart compile exe apps/cli/bin/acdg.dart` | success, binário ≤ 15MB |
| E2E stdio test | `apps/cli/test/mcp/e2e_stdio_test.dart` | spawns binary, JSON-RPC handshake, 1 tool call, clean shutdown |
| External review (charter) | Manual via `ai_gemini_review` com auto-discovery | verdict `approved` |

---

## Execution checklist

- [x] W0 discuss/CONTEXT.md (este commit)
- [x] W1 design/DESIGN.md (este commit)
- [ ] **APROVAÇÃO DO USER NO DESIGN** — ANTES de despachar test-writer
- [ ] W2 tests/REPORT.md — `test-writer` agent (RED, deve falhar contra impl ausente)
- [ ] W3 impl/REPORT.md — `flutter-bff-implementer` agent (GREEN, mínimo pra passar W2)
- [ ] W4 review/REVIEW.md — `flutter-code-reviewer` agent (defensive)
- [ ] W5 quality/REPORT.md — `flutter-quality-checker` agent (gates)
- [ ] External review com Charter

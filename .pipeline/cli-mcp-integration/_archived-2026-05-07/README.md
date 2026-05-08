# Pipeline: CLI-MCP-Integration

> **Ticket:** CLI-MCP-INTEGRATION  
> **Data:** 2026-05-06  
> **Escopo:** Adicionar `mcp_dart` v2.1.1 ao ACDG CLI e expor comandos como MCP Server (stdio)  
> **Metodologia:** 4-Wave Pipeline (W0→W1→W2→W3→W4→W5)

---

## Visão Geral

Esta pipeline implementa a integração do protocolo **Model Context Protocol (MCP)** no ACDG CLI, permitindo que AI hosts (Claude Desktop, ChatGPT, Cursor) se conectem ao CLI via stdio e invoquem comandos como tools MCP.

A decisão de adotar `mcp_dart` v2.1.1 (comunidade) em vez de `dart_mcp` v0.5.1 (oficial) está documentada na auditoria de segurança:
- `frontend/handbook/audit/2026-05-06-mcp-packages-audit.md`

---

## Estrutura da Pipeline

```
cli-mcp-integration/
├── 000-discuss/CONTEXT.md      # W0 — ADRs e decisões arquiteturais
├── 001-design/DESIGN.md        # W1 — Design do end-state
├── 002-tests/REPORT.md         # W2 — Tests RED (TDD)
├── 003-impl/REPORT.md          # W3 — Implementação GREEN
├── 004-code-review/REVIEW.md   # W4 — Code review (98% score)
├── 005-quality/REPORT.md       # W5 — Quality gates (all passed)
└── README.md                   # Este arquivo
```

---

## Decisões Arquiteturais (ADRs)

| ADR | Decisão | Status |
|-----|---------|--------|
| ADR-MCP-001 | Pacote `mcp_dart` v2.1.1 (pinned) | ✅ Aceito |
| ADR-MCP-002 | Modo MCP Server via stdio | ✅ Aceito |
| ADR-MCP-003 | Boundary Adapter Pattern | ✅ Aceito |
| ADR-MCP-004 | Tool Registration explicit (no reflection) | ✅ Aceito |
| ADR-MCP-005 | Validar command path + Redact logs | ✅ Aceito |
| ADR-MCP-006 | Fakes para testes (nunca mocks) | ✅ Aceito |

---

## Classes Criadas

| Classe | Tipo | Responsabilidade |
|--------|------|------------------|
| `McpServerAdapter` | Reference | Isola `mcp_dart`, gerencia lifecycle |
| `McpToolRegistry` | Reference | Registra CLI commands como MCP tools |
| `McpErrorMapper` | Reference | Converte exceções MCP → `CliError` |
| `McpAdapterError` | Value | `CliError` subtype (exitCode 70) |
| `McpServeCommand` | Reference | `acdg mcp serve` command |
| `McpCommand` | Reference | Container `acdg mcp` command |

---

## Quality Gates

| Gate | Resultado |
|------|-----------|
| `dart analyze` | 0 issues |
| `dart format` | Clean |
| `dart test` | 28/28 GREEN |
| `dart compile exe` | ✅ (12M) |
| `melos bootstrap` | ✅ |
| Security audit | No leaks |

---

## Uso

### Configurar Claude Desktop

```json
{
  "mcpServers": {
    "acdg": {
      "command": "acdg",
      "args": ["mcp", "serve"]
    }
  }
}
```

### Executar manualmente

```bash
acdg mcp serve
```

---

## Riscos e Mitigações

| Risco | Mitigação |
|-------|-----------|
| `mcp_dart` breaking change | Pin version + lockfile |
| Publisher não verificado | Audit antes de upgrade |
| Stack trace leak | `McpErrorMapper` strips traces |
| Log de dados sensíveis | `protocolLogSink` NÃO configurado |

---

## Próximos Passos

1. Expandir registry com mais comandos CLI (team, person, etc.)
2. Adicionar transporte StreamableHTTP (remoto)
3. Integrar auth OAuth quando suportado pelo `mcp_dart`
4. Documentar uso no `README.md` do CLI

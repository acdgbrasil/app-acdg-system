# W0 — DISCUSS: Integração MCP no ACDG CLI

> **Ticket:** CLI-MCP-INTEGRATION  
> **Data:** 2026-05-06  
> **Pipeline:** 4-Wave (W0→W1→W2→W3)  
> **Escopo:** Adicionar `mcp_dart` v2.1.1 ao CLI e expor comandos como MCP Server (stdio)  
> **Motivação:** Permitir que stakeholders (ex: gestores) usem AI hosts (ChatGPT, Claude Desktop) para interagir com o sistema ACDG via MCP.

---

## Decisões Arquiteturais (ADRs)

### ADR-MCP-001: Pacote escolhido — `mcp_dart` v2.1.1

**Status:** Aceito  
**Contexto:** Dois pacotes disponíveis: `dart_mcp` (oficial, v0.5.1, experimental) e `mcp_dart` (comunidade, v2.1.1, estável).  
**Decisão:** Adotar `mcp_dart` v2.1.1.  
**Justificativa:**
- Suporta stdio + StreamableHTTP (futuro-proof).
- OAuth2/PKCE completo (alinhado com ADR-012 do projeto).
- Sem breaking changes previstas (SemVer v2.x).
- AOT compatível (validado em auditoria 2026-05-06).
- Apenas 1 dependência runtime (`http`).

**Consequências:**
- Publisher não verificado (`leehack`). Mitigação: pin de versão + lockfile.
- 739× uso de `dynamic` no pacote. Mitigação: wrapper types internos.

---

### ADR-MCP-002: Modo de operação — MCP Server (stdio)

**Status:** Aceito  
**Contexto:** MCP pode operar como Client (conecta a servidores externos) ou Server (expõe capabilities).  
**Decisão:** Implementar **MCP Server** via stdio transport.  
**Justificativa:**
- AI hosts (Claude Desktop, ChatGPT, Cursor) esperam se conectar a MCP servers via stdio.
- O CLI já é um processo CLI — stdio é o transporte natural.
- Cada comando do CLI (`patient get`, `team list`, etc.) será exposto como uma MCP Tool.

**Consequências:**
- O comando `acdg mcp serve` inicia o servidor MCP.
- AI hosts configuram o CLI como um server process (`command: "acdg", args: ["mcp", "serve"]`).
- Futuro: StreamableHTTP transport para uso remoto.

---

### ADR-MCP-003: Boundary Adapter Pattern — Isolar `mcp_dart`

**Status:** Aceito  
**Contexto:** `mcp_dart` usa exceções (`throw`) e `dynamic`, enquanto o ACDG CLI usa `Result<T>` disciplina.  
**Decisão:** Criar `McpServerAdapter` (reference type, sem Equatable) que isola todo contato com `mcp_dart`.  
**Justificativa:**
- Previne vazamento de exceções do pacote externo para o domínio CLI.
- Permite trocar `mcp_dart` por `dart_mcp` no futuro sem impacto no restante do código.
- Converte exceções MCP em `CliError` polimórfico com `exitCode` apropriado.

**Consequências:**
- Toda chamada a `mcp_dart` passa pelo adapter.
- Adapter vive em `lib/src/mcp/`.
- Testes usam fakes do adapter, nunca mocks do pacote externo.

---

### ADR-MCP-004: Tool Registration — Reflection-free, Explicit

**Status:** Aceito  
**Contexto:** Como registrar comandos do CLI como tools MCP sem usar `dart:mirrors`?  
**Decisão:** Registro explícito via `Map<String, McpToolHandler>` construído no construtor do adapter.  
**Justificativa:**
- `dart:mirrors` não funciona em AOT (`dart compile exe`).
- Registro explícito é previsível, testável e type-safe.
- Cada commando CLI exposto como tool requer um `McpToolHandler` que traduz args MCP para invocation do commando.

**Consequências:**
- Adicionar um novo comando ao MCP requer adicionar uma entrada no mapa.
- Código boilerplate reduzido via funções helper (`_registerPatientTools`, etc.).

---

### ADR-MCP-005: Segurança — Validar command path + Redact logs

**Status:** Aceito  
**Contexto:** Auditoria identificou que `StdioClientTransport` não valida caminho do executável; logging pode vazar tokens.  
**Decisão:**
1. Não usar `StdioClientTransport` no server mode (irrelevante).
2. Redactar dados sensíveis em qualquer log de protocolo.
3. Nunca expor stack traces em respostas de tool (corrigir comportamento padrão do `mcp_dart`).

---

### ADR-MCP-006: Testes — Fakes, nunca mocks

**Status:** Aceito  
**Contexto:** ADR-013 do projeto exige fakes, nunca mocks.  
**Decisão:** Criar `FakeMcpTransport` e `FakeMcpServer` para testes de integração.  
**Justificativa:**
- Fakes são determinísticos e não quebram com refatoração interna do pacote.
- Testes de integração MCP usam transporte in-memory (`IOStreamTransport`).

---

## Contexto do Código-base

### CLI atual
- **Entry:** `bin/cli.dart` → `CliRunner`.
- **Commands:** 40+ commands em `lib/src/commands/`.
- **Error hierarchy:** `sealed class CliError` com `exitCode` e `stderrMessage` polimórficos.
- **Formatter:** `OutputFormatter` (JSON/YAML/text).
- **Auth:** OIDC PKCE + keychain storage.
- **Tests:** 815 tests, zero analyze issues.

### Onde tocar
```
lib/
├── cli.dart                          # Add McpServeCommand export
├── src/
│   ├── cli_runner.dart               # Add 'mcp' top-level command
│   ├── commands/
│   │   └── mcp_serve_command.dart    # NEW: acdg mcp serve
│   ├── mcp/                          # NEW: boundary adapter
│   │   ├── mcp_server_adapter.dart   # NEW: isolates mcp_dart
│   │   ├── mcp_tool_registry.dart    # NEW: maps CLI commands → MCP tools
│   │   └── mcp_error_mapper.dart     # NEW: mcp exceptions → CliError
│   └── errors/cli_error.dart         # Add McpError subtype
```

---

## Riscos Identificados

| Risco | Severidade | Mitigação |
|-------|------------|-----------|
| `mcp_dart` breaking change em v3 | Média | Pin version + lockfile |
| Publisher compromise | Baixa | Pin + audit antes de upgrade |
| AOT compilation regression | Baixa | CI gate: `dart compile exe` |
| Stack trace leak (default mcp_dart) | Média | Override error handler no adapter |
| Performance com 40+ tools registradas | Baixa | Lazy registration + filtering |

---

## Próximos Passos

1. **W1 (DESIGN):** Detalhar `McpServerAdapter` API, `McpToolRegistry`, e `McpServeCommand`.
2. **W2 (RED):** Escrever tests que falham (TDD).
3. **W3 (GREEN):** Implementar adapter, registry, command, error mapper.
4. **W4 (REVIEW):** Code review com checklist do flutter-orchestrator.
5. **W5 (QUALITY):** `dart analyze`, `dart format`, `dart test`, AOT compile.

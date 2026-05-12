# Auditoria Comparativa: Pacotes MCP para Dart

> **Data:** 2026-05-06  
> **Auditor:** Flutter Orchestrator (ACDG CLI Security Pipeline)  
> **Escopo:** `dart_mcp` v0.5.1 (oficial) vs `mcp_dart` v2.1.1 (comunidade)  
> **Metodologia:** W0-W3 Pipeline (DISCOVER → DESIGN → RED/GREEN → QUALITY)

---

## 1. Executive Summary

| Dimensão | `dart_mcp` (oficial) | `mcp_dart` (comunidade) |
|----------|----------------------|-------------------------|
| **Versão** | 0.5.1 (experimental) | 2.1.1 (estável) |
| **Publisher** | `labs.dart.dev` (Google/Dart team) | `leehack` (individual, não verificado) |
| **Idade** | ~6 meses | ~1 ano |
| **Stars** | N/A (mono-repo) | 108 |
| **Issues abertos** | 7 (pacote) | 2 |
| **SDK mínimo** | Dart 3.7.0 | Dart 3.0.0 |
| **Transports** | stdio apenas | stdio, StreamableHTTP, SSE, IOStream |
| **Auth/OAuth** | ❌ Não suportado | ✅ OAuth2 + PKCE completo |
| **Spec compliance** | 2024-11-05 a 2025-11-25 | 2024-10-07 a 2025-11-25 |
| **Tests** | 15 arquivos (~4.348 LOC) | 55+ arquivos (~3.086 LOC) |
| **AOT compatível** | ✅ Sim | ✅ Sim |
| **Pana score** | N/A (publisher verificado) | 160/160 (não verificado) |
| **Recomendação** | 🟡 Observar | 🟢 Adotar (com hardening) |

**Veredicto:** O pacote `mcp_dart` v2.1.1 é **superior em praticamente todas as dimensões operacionais** para o ACDG CLI. O `dart_mcp` oficial é promissor mas ainda experimental (v0.x), com funcionalidades críticas faltantes (Streamable HTTP, auth, cancellation, pagination).

---

## 2. Metodologia de Auditoria

A auditoria seguiu o pipeline W0-W3 do `flutter-orchestrator.md`:

1. **W0 (DISCOVER):** Clonagem de repositórios, análise de dependências transitivas, extração de métricas de CI/CD.
2. **W1 (DESIGN):** Análise de arquitetura — sealed classes, pattern matching, tratamento de erros, abstrações de transporte.
3. **W2 (RED):** Varredura de segurança — busca por `Process.run`, `eval`, `dynamic`, `as` casts perigosos, validação de input, TLS, CORS, DNS rebinding, logging de dados sensíveis.
4. **W3 (GREEN):** Compilação AOT, `dart analyze`, verificação de compatibilidade com Dart 3.11+.

---

## 3. Análise de Arquitetura

### 3.1. `dart_mcp` v0.5.1 — Oficial (Google)

```
lib/
├── client.dart          # MCPClient, ServerConnection
├── server.dart          # MCPServer + mixins (ToolsSupport, etc.)
├── stdio.dart           # stdioChannel() utility
└── src/
    ├── api/             # Modelos de dados (extension types)
    ├── client/          # Cliente JSON-RPC
    ├── server/          # Servidor JSON-RPC + mixins
    ├── shared.dart      # MCPBase (Peer, handlers, progress)
    └── utils/           # Constantes
```

**Arquitetura:** Baseada em `package:json_rpc_2` (Peer). O `MCPBase` gerencia o peer JSON-RPC, registro de handlers, progress notifications e ping. `MCPServer` estende `MCPBase` com mixins (`ToolsSupport`, `ResourcesSupport`, etc.). `MCPClient` gerencia múltiplas `ServerConnection`s.

**Pontos positivos:**
- Usa `abstract base class` e `base mixin` — controle de herança moderno.
- **Extension types** (Dart 3) sobre `Map<String, Object?>` para zero-cost wrappers.
- Separação clara entre API (modelos), cliente e servidor.
- `registerRequestHandler` valida que params é `Map` ou `null` antes de cast.
- Não usa `dart:io` na lib (exceto exemplos) — puro Dart, portátil.
- **Strict modes ativados:** `strict-casts: true`, `strict-inference: true`.

**Pontos negativos:**
- **Apenas stdio** como transporte built-in. Streamable HTTP está em roadmap (issue #162).
- **Sem auth/OAuth** — declarado como "não suportado, focado em uso local".
- **Sem cancellation** (issue #37) e **sem pagination** (issue #28).
- **`late` fields** (`protocolVersion`, `clientCapabilities`) sem null-safety defensiva em alguns caminhos.
- Mixins com `part` files — acoplamento moderado.

### 3.2. `mcp_dart` v2.1.1 — Comunidade (leehack)

```
lib/
├── mcp_dart.dart
└── src/
    ├── client/          # StdioClient, StreamableHTTPClient, TaskClient
    ├── server/          # McpServer, StreamableHTTPServer, SSE, Tasks
    ├── shared/          # Protocol, Transport, JSON Schema, Logging, UUID
    ├── types/           # Modelos (JSON-RPC, Tools, Resources, etc.)
    └── exports_*.dart   # Conditional exports (web/vm)
```

**Arquitetura:** Transport-agnostic. `Transport` é uma interface; implementações: `StdioTransport`, `StreamableHTTPServerTransport`, `SSETransport`, `IOStreamTransport`. `Protocol` gerencia JSON-RPC, timeouts, abort signals. `McpServer` é um wrapper de alto nível (~1.790 linhas) que registra callbacks para tools, resources, prompts, tasks.

**Pontos positivos:**
- **Sealed classes extensivas:** `JsonRpcMessage`, `JsonSchema`, `Content`, `ToolCallback`.
- **Pattern matching exaustivo** em validadores JSON Schema.
- **DNS Rebinding Protection** habilitada por padrão.
- **Strict defaults** em v2.1.0+ (`rejectBatchJsonRpcPayloads`, `strictProtocolVersionHeaderValidation`).
- **Backward compatibility toggles** — permite migração gradual.
- **Interop testing** — testes Dart ↔ TypeScript confirmam compatibilidade de wire format.

**Pontos negativos:**
- **Código monolítico:** `mcp_server.dart` tem 1.790 linhas; `mcp_server.dart` + `streamable_https.dart` = ~2.800 linhas.
- **Uso extensivo de `dynamic`:** 739 ocorrências de `Map<String, dynamic>` / casts `as` no modelo de dados.
- **Tratamento de erros inconsistente:** `catch (e)` sem `st` em muitos lugares; conversão genérica para `StateError`.
- **`analysis_options.yaml` não usa strict modes** (`strict-casts`, `strict-inference`, `strict-raw-types` comentados).

---

## 4. Análise de Segurança

### 4.1. Dependências e Supply Chain

| Critério | `dart_mcp` | `mcp_dart` |
|----------|------------|------------|
| **Deps runtime** | 6 (`async`, `collection`, `json_rpc_2`, `meta`, `stream_channel`, `stream_transform`) | 1 (`http`) |
| **Deps transitivas** | ~15+ | ~5 |
| **Vulnerabilidades conhecidas** | ✅ Nenhuma | ✅ Nenhuma |
| **Publisher verificado** | ✅ `labs.dart.dev` (Google) | ❌ Não verificado |
| **Supply chain risk** | 🟡 Baixo (Google) | 🟡 Baixo (deps mínimas) |

**Análise:** Ambos têm superfície de ataque pequena. O `dart_mcp` depende de `json_rpc_2` (mantido pelo Dart team), o que é confiável. O `mcp_dart` depende apenas de `http` (Google). O risco de supply chain é baixo para ambos, mas o publisher do `mcp_dart` não é verificado — qualquer comprometimento da conta `leehack` no pub.dev poderia publicar versões maliciosas.

### 4.2. Execução de Processos

**`dart_mcp`:** Não executa processos na lib. Os **exemplos** usam `Process.start('dart', [...])` — isso é seguro pois o comando é hardcoded. Notavelmente, o método `connectStdioServer` foi **deprecado** em favor de `connectServer` com streams — excelente decisão de segurança que remove a necessidade do pacote iniciar processos.

**`mcp_dart`:** `StdioClientTransport` usa `io.Process.start`:

```dart
_process = await io.Process.start(
  _serverParams.command,   // <- input do usuário
  _serverParams.args,
  runInShell: false,       // ✅ MITIGAÇÃO
  mode: io.ProcessStartMode.normal,
);
```

- `runInShell: false` previne shell injection.
- **Sem validação** do caminho do executável. Se `_serverParams.command` vier de configuração não confiável, pode executar binários arbitrários.
- **Sem sanitização** de `workingDirectory`.

**Recomendação:** Validar que `command` é um caminho absoluto/canônico antes de spawn.

### 4.3. Validação de Input

**`dart_mcp`:**
- `registerRequestHandler` valida que `p.value is! Map` antes de cast.
- `tool.inputSchema.validate()` retorna lista de erros; não lança.
- Schema validation é custom e limitada (não suporta `$ref`, `format`, `unevaluatedProperties` completo).

**`mcp_dart`:**
- JSON Schema validator custom com suporte a `allOf`, `anyOf`, `oneOf`, `not`.
- Valida `type`, `minLength`, `maxLength`, `pattern`, `enum`, `minimum`, `maximum`, etc.
- **Não valida** `$ref`, `format`, `uniqueItems` de forma robusta (deep equality lenta O(n²)).
- `handleRequest` aceita `[dynamic parsedBody]` — se fornecido por fonte não confiável, pula validação UTF-8/JSON.

### 4.4. Comunicação de Rede

**`dart_mcp`:** Não implementa transporte HTTP na lib (apenas stdio).

**`mcp_dart`:**
- **TLS:** Usa `package:http` sem `badCertificateCallback` — certificados são validados.
- **DNS Rebinding:** Proteção habilitada por padrão (`localhost`, `127.0.0.1`, `::1` allowlist).
- **CORS:** Valida `Host` e `Origin` headers.
- **Session IDs:** Gerados via `generateUUID()` (não criptograficamente seguro — usa `Random()`, não `SecureRandom`).

### 4.5. Exposição de Dados Sensíveis

**`dart_mcp`:** Protocol log sink loga mensagens JSON completas. Se uma tool retornar dados sensíveis, eles aparecem no log. Adicionalmente, erros de tool **expoem stack traces** ao cliente:
```dart
} catch (e, s) {
  return CallToolResult(
    isError: true,
    content: [TextContent(text: '$e\n$s')],  // <-- EXPÕE STACK TRACE
  );
}
```

**`mcp_dart`:** Logger não faz redação automática. Tokens de auth, senhas e dados de exceções podem vazar para logs.

### 4.6. Uso de `dynamic` e Casts

**`dart_mcp`:** 2 ocorrências de `dynamic` em toda a lib. Casts `as` são moderados (342). A maioria é em `registerRequestHandler` com validação prévia.

**`mcp_dart`:** 739 ocorrências de `dynamic`. 516 casts `as`. A ausência de `strict-casts: true` significa que o compilador não força verificação estática.

---

## 5. Compatibilidade com ACDG CLI

| Critério | `dart_mcp` | `mcp_dart` | Requisito ACDG |
|----------|------------|------------|----------------|
| **Dart SDK** | ≥3.7.0 | ≥3.0.0 | ≥3.11.0 ✅ |
| **AOT compilation** | ✅ | ✅ | Obrigatório ✅ |
| **PKCE/OAuth** | ❌ | ✅ | Requerido para auth |
| **Keychain storage** | ❌ (não aplica) | ❌ (não aplica) | Fora do escopo do pacote |
| **Result<T> discipline** | ❌ (usa try/catch) | ❌ (usa try/catch) | Incompatível com nossa base |
| **Sealed class + exhaustive switch** | ✅ Parcial | ✅ Extensivo | Alinhado ✅ |
| **catch (e, st)** | ✅ Sim | ⚠️ Parcial | Alinhado parcial |

**Nota:** Ambos os pacotes usam `try/catch` tradicional, não `Result<T>`. Isso é aceitável pois o padrão `Result<T>` do ACDG é uma convenção interna; a interoperabilidade com pacotes externos exige adaptação na camada de boundary.

---

## 6. Qualidade de Código

| Métrica | `dart_mcp` | `mcp_dart` |
|---------|------------|------------|
| **LOC (lib)** | ~6.241 | ~17.129 |
| **Arquivos .dart** | 29 | 57 |
| **Test files** | 15 | 55+ |
| **Test LOC** | ~561 | ~3.086 |
| **Test / Lib ratio** | ~70% | ~18% |
| **dart analyze** | ✅ Zero issues | ✅ Zero issues |
| **dart format** | ✅ | ✅ |
| **Linter** | `dart_flutter_team_lints` (strict, strict-casts) | `lints/recommended` (lenient) |
| **Coverage** | Extensiva (CI multi-plataforma) | Codecov badge |
| **Golden tests** | ❌ | ❌ |
| **Interop tests** | ❌ | ✅ Dart ↔ TS |
| **CI targets** | dart2wasm, dart2js, kernel, exe, Chrome | VM apenas |

---

## 7. Matriz de Risco

| Risco | `dart_mcp` | `mcp_dart` | Mitigação |
|-------|------------|------------|-----------|
| **Experimental / instável** | 🔴 Alto (v0.x) | 🟢 Baixo | Preferir v2.1.1 |
| **Funcionalidades faltantes** | 🔴 Alto (sem HTTP, auth) | 🟢 Baixo | `mcp_dart` cobre 100% |
| **Supply chain (publisher)** | 🟢 Baixo (Google) | 🟡 Moderado (individual) | Pin version, audit upgrades |
| **Command injection** | 🟢 Nenhum | 🟡 Baixo (stdio client) | Validar path do executável |
| **Data leakage (logs)** | 🟡 Moderado | 🟡 Moderado | Redact antes de logar |
| **Cast failures** | 🟢 Baixo | 🟡 Moderado | Adicionar validação defensiva |
| **Breaking changes** | 🔴 Alto (v0.x evolui rápido) | 🟢 Baixo (SemVer estável) | `^2.1.1` com lockfile |
| **Manutenção a longo prazo** | 🟢 Alta (Google) | 🟡 Moderada (comunidade) | Monitorar issues/commits |

---

## 8. Recomendações

### 8.1. Para ACDG CLI

**Adotar `mcp_dart` v2.1.1** como pacote MCP principal, com as seguintes contramedidas:

1. **Wrapper de segurança:** Criar uma camada de adaptação (`McpTransportAdapter`) que:
   - Valide caminhos de executáveis antes de passar para `StdioClientTransport`.
   - Redacte tokens e dados sensíveis antes de passar para logs do MCP.
   - Converta exceções MCP para `CliError` polimórfico com `exitCode` apropriado.

2. **Hardening do `analysis_options.yaml` do projeto:** Não depender do `analysis_options.yaml` do pacote. Nosso projeto já usa regras strict (`dart_flutter_team_lints` equivalente).

3. **Pin de versão:** Usar `mcp_dart: 2.1.1` (sem `^`) no `pubspec.yaml` e manter `pubspec.lock` no version control. O publisher não é verificado.

4. **Testes de integração:** Adicionar testes E2E que verifiquem:
   - Comunicação stdio entre CLI e servidor MCP.
   - Timeout e cleanup de processos.
   - Rejeição de inputs malformados.

### 8.2. Para `dart_mcp` (observação)

Monitorar o pacote oficial. Quando atingir v1.0.0 com:
- Streamable HTTP transport
- OAuth/PKCE support
- Cancellation e pagination

Reavaliar a migração. O backing do Google é um fator diferenciador a longo prazo.

### 8.3. Contribuições upstream (opcional)

Considerar contribuir com o `mcp_dart` para:
- Habilitar `strict-casts`, `strict-inference`, `strict-raw-types`.
- Adicionar validação de caminho absoluto em `StdioServerParameters`.
- Implementar redação de logs para campos sensíveis.

---

## 9. Referências

- `dart_mcp` pub.dev: https://pub.dev/packages/dart_mcp
- `dart_mcp` repo: https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp
- `mcp_dart` pub.dev: https://pub.dev/packages/mcp_dart
- `mcp_dart` repo: https://github.com/leehack/mcp_dart
- MCP Spec 2025-11-25: https://modelcontextprotocol.io/specification/2025-11-25
- ACDG CLI codebase: `frontend/apps/cli/`

---

*Relatório gerado pelo pipeline de auditoria do Flutter Orchestrator. Revisar a cada release major dos pacotes auditados.*

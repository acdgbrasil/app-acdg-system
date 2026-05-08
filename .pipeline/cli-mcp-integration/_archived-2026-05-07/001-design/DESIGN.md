# W1 — DESIGN: End-State da Integração MCP

> **Ticket:** CLI-MCP-INTEGRATION  
> **Data:** 2026-05-06  
> **Output:** Design completo de todas as classes, interfaces e fluxos.

---

## 1. Visão Geral do Fluxo

```
AI Host (Claude Desktop / ChatGPT)
  │
  │ spawns process
  │ command: "acdg", args: ["mcp", "serve"]
  ▼
┌─────────────────┐
│ McpServeCommand │  ← Command<int>, parseia args, cria adapter
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ McpServerAdapter    │  ← Reference type, SEM Equatable
│ (boundary adapter)  │    Isola mcp_dart do domínio CLI
└────────┬────────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌──────────────┐
│McpServer│ │ McpToolRegistry│  ← Map<String, McpToolHandler>
│(mcp_dart)│ │ (nosso código) │    Cada entry = 1 comando CLI
└────────┘ └──────────────┘
         │
         ▼
┌─────────────────┐
│ CliRunner       │  ← Reusa lógica existente
│ (internal run)  │    Executa comando com args parseados
└─────────────────┘
         │
         ▼
    stdout (MCP JSON-RPC)
```

---

## 2. API Pública (Exports)

`lib/cli.dart` (barrel file) adiciona:

```dart
library;

// Existing exports...
export 'src/cli_runner.dart';
export 'src/errors/cli_error.dart';
// ... etc

// NEW MCP exports
export 'src/commands/mcp_serve_command.dart';
```

---

## 3. Classes e Interfaces

### 3.1. `McpServeCommand` — `final class`, Reference type

```dart
/// `acdg mcp serve` — starts the MCP server over stdio.
///
/// AI hosts spawn this command and communicate via JSON-RPC over
/// stdin/stdout. Each registered CLI command is exposed as an MCP tool.
final class McpServeCommand extends Command<int> {
  McpServeCommand({
    required CliRunner cliRunner,
    required OutputFormatter formatter,
    Logger? logger,
  }) : _adapter = McpServerAdapter(
         cliRunner: cliRunner,
         formatter: formatter,
         logger: logger ?? Logger('mcp_server'),
       );

  final McpServerAdapter _adapter;

  @override String get name => 'serve';
  @override String get description => 'Start MCP server (stdio transport).';

  @override
  Future<int> run() async {
    await _adapter.start();
    await _adapter.done;
    return 0;
  }
}
```

**Regras:**
- `CliRunner` é injetado (não construído internamente) — permite testes com fake.
- `Logger` do `package:logging` ou nosso wrapper.
- Não expõe `mcp_dart` types na API pública.

---

### 3.2. `McpServerAdapter` — `final class`, Reference type

```dart
/// Boundary adapter that isolates `package:mcp_dart` from the CLI domain.
///
/// Responsible for:
/// - Creating and configuring the [McpServer].
/// - Registering CLI commands as MCP tools.
/// - Converting MCP exceptions into [CliError] instances.
/// - Redacting sensitive data from protocol logs.
final class McpServerAdapter {
  McpServerAdapter({
    required CliRunner cliRunner,
    required OutputFormatter formatter,
    required Logger logger,
  }) : _cliRunner = cliRunner,
       _formatter = formatter,
       _logger = logger,
       _registry = McpToolRegistry(
         cliRunner: cliRunner,
         formatter: formatter,
       );

  final CliRunner _cliRunner;
  final OutputFormatter _formatter;
  final Logger _logger;
  final McpToolRegistry _registry;

  McpServer? _server;
  late final Transport _transport;

  /// Completes when the server shuts down.
  Future<void> get done => _done.future;
  final Completer<void> _done = Completer<void>();

  /// Starts the MCP server over stdio.
  Future<void> start() async {
    _transport = StdioServerTransport();
    _server = McpServer(
      Implementation(name: 'acdg-cli', version: '1.0.0'),
    );

    _registry.registerAll(_server!);
    _server!.onError = _onError;

    await _server!.connect(_transport);
    _logger.info('MCP server started (stdio)');
  }

  void _onError(Error error) {
    final mapped = McpErrorMapper.toCliError(error);
    _logger.severe('MCP error: ${mapped.stderrMessage}');
  }

  /// Gracefully shuts down the server.
  Future<void> shutdown() async {
    await _server?.close();
    if (!_done.isCompleted) _done.complete();
  }
}
```

**Regras:**
- SEM `Equatable` (reference type).
- Todos os fields são `final` e privados (`_`).
- Nunca expõe `McpServer` ou `Transport` para fora do package.
- `Logger` redacta tokens automaticamente.

---

### 3.3. `McpToolRegistry` — `final class`, Reference type

```dart
/// Registry that maps CLI commands to MCP tools.
///
/// Each tool accepts arguments (from the AI host), invokes the
/// corresponding CLI command internally, and returns formatted output.
final class McpToolRegistry {
  McpToolRegistry({
    required CliRunner cliRunner,
    required OutputFormatter formatter,
  }) : _cliRunner = cliRunner,
       _formatter = formatter;

  final CliRunner _cliRunner;
  final OutputFormatter _formatter;

  /// Registers all CLI commands as MCP tools on [server].
  void registerAll(McpServer server) {
    _registerPatientTools(server);
    _registerTeamTools(server);
    // ... etc
  }

  void _registerPatientTools(McpServer server) {
    server.registerTool(
      name: 'patient_get',
      description: 'Fetch a single patient by ID.',
      inputSchema: _patientGetSchema,
      callback: _handlePatientGet,
    );
    // ...
  }

  Future<CallToolResult> _handlePatientGet(
    Map<String, dynamic> args,
    RequestHandlerExtra extra,
  ) async {
    final patientId = args['patient_id'];
    if (patientId == null || patientId is! String) {
      return CallToolResult(
        isError: true,
        content: [TextContent(text: 'Missing or invalid patient_id')],
      );
    }

    // Reuse existing CLI logic
    final exitCode = await _cliRunner.run([
      'patient', 'get', patientId,
    ]);

    // Capture stdout via injected StringSink
    // (CliRunner must support stdout injection for this)
    final output = _captureStdout();

    return CallToolResult(
      content: [TextContent(text: output)],
    );
  }

  // --- JSON Schema helpers ---

  ToolInputSchema get _patientGetSchema => ToolInputSchema(
    properties: {
      'patient_id': JsonString(description: 'Patient UUID'),
    },
    required: ['patient_id'],
  );
}
```

**Regras:**
- Cada tool tem `inputSchema` com validação JSON Schema.
- Args são validados antes de passar para `_cliRunner`.
- Saída é formatada via `_formatter`.
- Erros são convertidos para `CallToolResult(isError: true)` — NUNCA lançam exceções para o cliente MCP.

---

### 3.4. `McpErrorMapper` — `final class`, Reference type (namespace)

```dart
/// Converts MCP / mcp_dart exceptions into [CliError] instances.
///
/// Prevents leakage of stack traces to AI hosts.
final class McpErrorMapper {
  const McpErrorMapper._();

  static CliError toCliError(Object error) => switch (error) {
    McpError(:final code, :final message) => _fromMcpErrorCode(code, message),
    StateError(:final message) => McpAdapterError(message),
    FormatException(:final message) => McpAdapterError('Invalid format: $message'),
    _ => McpAdapterError('Unexpected MCP error: $error'),
  };

  static CliError _fromMcpErrorCode(int code, String message) => switch (code) {
    -32700 => McpAdapterError('Parse error: $message'),
    -32600 => McpAdapterError('Invalid request: $message'),
    -32601 => McpAdapterError('Method not found: $message'),
    -32602 => McpAdapterError('Invalid params: $message'),
    -32603 => McpAdapterError('Internal error: $message'),
    _ => McpAdapterError('MCP error ($code): $message'),
  };
}
```

**Regras:**
- Nunca inclui `StackTrace` na mensagem retornada.
- Usa `switch` exhaustivo sobre tipos conhecidos.
- Fallback genérico para tipos desconhecidos.

---

### 3.5. `McpAdapterError` — `final class`, Value type

```dart
/// Error subtype for MCP adapter failures.
///
/// Exit code 70 (software error) per sysexits.h.
final class McpAdapterError extends CliError with Equatable {
  const McpAdapterError(super.message);

  @override
  int get exitCode => 70;

  @override
  String get stderrMessage => 'MCP adapter error: $message';

  @override
  List<Object?> get props => [message];
}
```

**Regras:**
- Extende `CliError` (já é `sealed`).
- `with Equatable` (value type).
- `props` cobre todos os fields.

---

### 3.6. `McpServeCommand` no `CliRunner`

```dart
// cli_runner.dart
CliRunner() : super('acdg', 'ACDG CLI') {
  // existing commands...
  addCommand(PatientGetCommand(...));
  
  // NEW: MCP top-level command
  addCommand(McpCommand());
}

// mcp_command.dart — container command
final class McpCommand extends Command<int> {
  McpCommand() {
    addCommand(McpServeCommand(...));
  }

  @override String get name => 'mcp';
  @override String get description => 'MCP server integration.';
}
```

---

## 4. Fluxo de Dados

### 4.1. Tool Invocation

```
AI Host → stdin → JSON-RPC "tools/call"
                → McpServer (mcp_dart)
                → McpToolRegistry._handlePatientGet
                → CliRunner.run(['patient', 'get', id])
                → PatientGetCommand.run()
                → BffClient.get('/patients/$id')
                → stdout → McpServer → AI Host
```

### 4.2. Error Flow

```
Exception in tool handler
  → catch (e, st) in McpToolRegistry
  → NUNCA rethrow
  → CallToolResult(isError: true, content: [safeMessage])
  → Log stack trace locally via Logger
```

---

## 5. Testes (Preview W2)

| Test | Tipo | Onde |
|------|------|------|
| `McpServerAdapter.start()` inicia servidor | Unit | `test/mcp/mcp_server_adapter_test.dart` |
| `McpServerAdapter.shutdown()` fecha gracefully | Unit | `test/mcp/mcp_server_adapter_test.dart` |
| `McpToolRegistry` registra tools corretamente | Unit | `test/mcp/mcp_tool_registry_test.dart` |
| `McpErrorMapper` converte exceções sem stack trace | Unit | `test/mcp/mcp_error_mapper_test.dart` |
| Tool invocation via IOStreamTransport | Integration | `test/mcp/mcp_integration_test.dart` |
| `McpAdapterError` é CliError com exitCode 70 | Unit | `test/errors/cli_error_test.dart` |
| `dart compile exe` sucede | AOT | CI gate |

---

## 6. Quality Gates (Preview W5)

```bash
# Analyze
melos run analyze --no-select  # ou dart analyze apps/cli/

# Format
dart format --set-exit-if-changed apps/cli/

# Tests
dart test apps/cli/

# AOT
dart compile exe apps/cli/bin/cli.dart -o /tmp/acdg-cli-mcp-test
```

---

## 7. Checklist de Design

- [x] `McpServerAdapter` isola `mcp_dart` (boundary adapter).
- [x] `McpToolRegistry` registra tools explicitamente (sem reflection).
- [x] `McpErrorMapper` converte exceções sem vazar stack traces.
- [x] `McpAdapterError` estende `CliError` com `exitCode` polimórfico.
- [x] `McpServeCommand` integra ao `CliRunner` existente.
- [x] Testes usam fakes (não mocks).
- [x] AOT compilation é gate obrigatório.

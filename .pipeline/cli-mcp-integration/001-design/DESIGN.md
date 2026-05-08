# W1 — DESIGN: CLI-MCP-INTEGRATION (v2)

> **Ticket:** CLI-MCP-INTEGRATION
> **Data:** 2026-05-07
> **Pré-requisito:** `000-discuss/CONTEXT.md` aprovado.
> **Output:** desenho end-state que o `test-writer` (W2) traduz para tests RED, e o `flutter-bff-implementer` (W3) traduz para código GREEN.

---

## §1 — Overview & sequência

### 1.1 — Diagrama do fluxo

```
┌──────────────────────┐
│  AI host (Claude)    │
│  spawns:             │
│  acdg mcp serve      │
└────────┬─────────────┘
         │ stdin / stdout (binary)
         ▼
┌──────────────────────────────────────┐
│  bin/acdg.dart                       │
│  ─ CliRunner(stdout, stderr) ─       │
│  ─ argv = ["mcp","serve"] ─          │
└────────┬─────────────────────────────┘
         │ args dispatch
         ▼
┌──────────────────────────────────────┐
│  McpServeCommand.run()               │
│  1. McpLoggerSetup.redirectToStderr()│
│  2. build adapter w/ deps            │
│  3. await adapter.start()            │
│  4. await adapter.done               │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│  McpServerAdapter                    │
│  ─ owns dart_mcp.MCPServer ─         │
│  ─ owns stdioChannel ─               │
│  ─ wires McpToolRegistry ─           │
│  ─ converts errors via Mapper ─      │
└────────┬─────────────────────────────┘
         │ stdio JSON-RPC peer
         ▼
┌──────────────────────────────────────┐
│  McpToolRegistry                     │
│  Map<String, McpToolDefinition>      │
│  ┌──────────────────────────────┐    │
│  │ on tools/call(name, args):   │    │
│  │  1. lookup tool              │    │
│  │  2. validate args (schema)   │    │
│  │  3. RBAC check vs session    │    │
│  │  4. invoke handler           │    │
│  │  5. wrap result/error        │    │
│  └──────────────────────────────┘    │
└────────┬─────────────────────────────┘
         │
         ├─► HealthTool      ──► BffClient.get(/health/ready)
         ├─► AuthStatusTool  ──► CredentialStore.read()
         ├─► PatientListTool ──► BffClient.get(/patients)
         ├─► PatientGetTool  ──► BffClient.get(/patients/:id)
         └─► LookupGetTool   ──► BffClient.get(/lookups/:id)
```

### 1.2 — Camadas e responsabilidades

| Layer | Module | Responsabilidade | Throw policy |
|---|---|---|---|
| Command | `mcp_command.dart`, `mcp_serve_command.dart` | Wire deps, fire adapter | Allowed (adapter boundary, defined panic) |
| Adapter | `mcp/mcp_server_adapter.dart` | Isola `dart_mcp`; lifecycle | Allowed; converte `dart_mcp` exceptions para sealed errors |
| Registry | `mcp/mcp_tool_registry.dart` | RBAC; schema; dispatch | NEVER; retorna `CallToolResult(isError: true)` |
| Tool handler | `mcp/handlers/*_tool.dart` | Lógica de uma tool | NEVER; retorna `Result<Object>` mapeado para `CallToolResult` |
| Error mapper | `mcp/mcp_error_mapper.dart` | dart_mcp exception → sealed error | N/A (puro switch) |
| Logger setup | `mcp/mcp_logger_setup.dart` | Redirect Logger root para stderr | N/A |

---

## §2 — Classes e signatures

### 2.1 — `McpCommand` (container, `acdg mcp`)

```dart
// apps/cli/lib/src/commands/mcp_command.dart
import 'package:args/command_runner.dart';

import '../session/bff_client.dart';
import '../session/credential_store.dart';
import 'mcp_serve_command.dart';

/// `acdg mcp` — container for MCP server operations.
///
/// Currently only `serve` (stdio MCP server). Future: `serve --http` (B6+).
final class McpCommand extends Command<int> {
  McpCommand({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required StringSink stdout,
    required StringSink stderr,
  }) {
    addCommand(
      McpServeCommand(
        bffClient: bffClient,
        credentialStore: credentialStore,
        stdout: stdout,
        stderr: stderr,
      ),
    );
  }

  @override
  String get name => 'mcp';

  @override
  String get description => 'Model Context Protocol server integration.';
}
```

### 2.2 — `McpServeCommand` (`acdg mcp serve`)

```dart
// apps/cli/lib/src/commands/mcp_serve_command.dart
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../mcp/mcp_logger_setup.dart';
import '../mcp/mcp_server_adapter.dart';
import '../session/bff_client.dart';
import '../session/credential_store.dart';

/// `acdg mcp serve` — starts the MCP server over stdio.
///
/// **STDIO contract**: this command takes ownership of stdin/stdout for
/// JSON-RPC. Logger is redirected to stderr BEFORE the adapter starts.
/// Any `print` / `stdout.write` outside [adapter] WILL corrupt the channel.
final class McpServeCommand extends Command<int> {
  McpServeCommand({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required StringSink stdout,
    required StringSink stderr,
  }) : _bffClient = bffClient,
       _credentialStore = credentialStore,
       _stderr = stderr;

  final BffClient _bffClient;
  final CredentialStore _credentialStore;
  final StringSink _stderr;

  @override
  String get name => 'serve';

  @override
  String get description => 'Start the MCP server (stdio transport).';

  @override
  Future<int> run() async {
    // SEC: redirect Logger root to stderr BEFORE any other initialization.
    // dart_mcp internals use package:logging; without redirect they would
    // write to stdout and corrupt the JSON-RPC frame.
    McpLoggerSetup.redirectToStderr(_stderr);

    final adapter = McpServerAdapter(
      bffClient: _bffClient,
      credentialStore: _credentialStore,
      logger: Logger('acdg.mcp'),
    );

    await adapter.start();
    await adapter.done;
    return 0;
  }
}
```

### 2.3 — `McpServerAdapter`

```dart
// apps/cli/lib/src/mcp/mcp_server_adapter.dart
import 'dart:async';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart' as mcp;
import 'package:dart_mcp/stdio.dart' as stdio;
import 'package:logging/logging.dart';

import '../session/bff_client.dart';
import '../session/credential_store.dart';
import 'mcp_error_mapper.dart';
import 'mcp_tool_registry.dart';

/// Boundary adapter that isolates `package:dart_mcp` from the CLI domain.
///
/// **Single responsibility**: own the `dart_mcp` server lifecycle. Conversion
/// of dart_mcp exceptions into sealed [McpAdapterError] happens here.
final class McpServerAdapter {
  McpServerAdapter({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required Logger logger,
    @visibleForTesting Stream<List<int>>? stdinOverride,
    @visibleForTesting io.IOSink? stdoutOverride,
  }) : _registry = McpToolRegistry(
         bffClient: bffClient,
         credentialStore: credentialStore,
         logger: logger,
       ),
       _logger = logger,
       _stdin = stdinOverride ?? io.stdin,
       _stdout = stdoutOverride ?? io.stdout;

  final McpToolRegistry _registry;
  final Logger _logger;
  final Stream<List<int>> _stdin;
  final io.IOSink _stdout;

  _AcdgMcpServer? _server;
  final _done = Completer<void>();

  /// Completes when the JSON-RPC peer closes (clean shutdown or error).
  Future<void> get done => _done.future;

  /// Starts the MCP server. Idempotent guard — second call throws StateError.
  Future<void> start() async {
    if (_server != null) {
      throw StateError('McpServerAdapter.start() called twice');
    }

    final channel = stdio.stdioChannel(stdin: _stdin, stdout: _stdout);

    final server = _AcdgMcpServer(
      _registry,
      onError: _onUnhandledError,
      logger: _logger,
    );
    _server = server;

    server.connect(channel);
    server.done.whenComplete(() {
      if (!_done.isCompleted) _done.complete();
    });

    _logger.info('acdg-mcp server connected (stdio)');
  }

  void _onUnhandledError(Object error, StackTrace? stack) {
    final mapped = McpErrorMapper.toAdapterError(error);
    _logger.severe('mcp.unhandled', mapped, stack);
    // SEC: never re-throw to dart_mcp default handler — it would emit the
    // raw exception to stdout. Mapping handles redaction.
  }

  /// Graceful shutdown. Idempotent.
  Future<void> shutdown() async {
    final server = _server;
    if (server == null) return;
    await server.shutdown();
    _server = null;
    if (!_done.isCompleted) _done.complete();
  }
}

/// Internal `MCPServer` subclass with `ToolsSupport` mixin and our error hook.
///
/// Lives inside [McpServerAdapter] so the dart_mcp dependency never escapes
/// the adapter file.
final class _AcdgMcpServer extends mcp.MCPServer with mcp.ToolsSupport {
  _AcdgMcpServer(this._registry, {required this.onError, required this.logger})
    : super(
        implementation: const mcp.Implementation(
          name: 'acdg-mcp',
          version: '0.1.0',
        ),
      );

  final McpToolRegistry _registry;
  final void Function(Object, StackTrace?) onError;
  final Logger logger;

  @override
  Future<List<mcp.Tool>> listTools(mcp.ListToolsRequest req) async =>
      _registry.allDefinitions().map((d) => d.toMcpTool()).toList();

  @override
  Future<mcp.CallToolResult> callTool(mcp.CallToolRequest req) =>
      _registry.dispatch(req.name, req.arguments ?? const {});
}
```

> **Note:** the exact dart_mcp API may differ — `_AcdgMcpServer` impl in W3 follows whatever the v0.5.1 surface dictates. The W1 design fixes the **boundary** (one class, no leak) and the **error contract** (every error path goes through `McpErrorMapper`). Method names from `MCPServer` / `ToolsSupport` are corrected at impl time without re-doing the design.

### 2.4 — `McpToolRegistry`

```dart
// apps/cli/lib/src/mcp/mcp_tool_registry.dart
import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;
import 'package:logging/logging.dart';

import '../errors/cli_error.dart';
import '../session/bff_client.dart';
import '../session/credential_store.dart';
import '../session/oidc_session.dart';
import 'handlers/auth_status_tool.dart';
import 'handlers/health_tool.dart';
import 'handlers/lookup_get_tool.dart';
import 'handlers/patient_get_tool.dart';
import 'handlers/patient_list_tool.dart';
import 'mcp_tool_definition.dart';

/// Routes incoming MCP tool calls.
///
/// **Responsibilities (in order):**
/// 1. Look up the tool definition by name.
/// 2. Validate args against the JSON Schema.
/// 3. Resolve session via [CredentialStore]; check `requiredRoles`.
/// 4. Invoke the handler.
/// 5. Wrap success/failure into `CallToolResult` (NEVER throws to dart_mcp).
final class McpToolRegistry {
  McpToolRegistry({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required Logger logger,
  }) : _credentialStore = credentialStore,
       _logger = logger,
       _tools = {
         HealthTool.definition.name: HealthTool(bffClient: bffClient),
         AuthStatusTool.definition.name: AuthStatusTool(
           credentialStore: credentialStore,
         ),
         PatientListTool.definition.name: PatientListTool(bffClient: bffClient),
         PatientGetTool.definition.name: PatientGetTool(bffClient: bffClient),
         LookupGetTool.definition.name: LookupGetTool(bffClient: bffClient),
       };

  final CredentialStore _credentialStore;
  final Logger _logger;
  final Map<String, McpToolHandler> _tools;

  Iterable<McpToolDefinition> allDefinitions() =>
      _tools.values.map((t) => t.definition);

  Future<mcp.CallToolResult> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    final tool = _tools[toolName];
    if (tool == null) {
      return _errorResult('Unknown tool: $toolName');
    }

    // SEC: schema validation FIRST — handler trusts the args shape.
    final schemaError = tool.definition.validateArgs(args);
    if (schemaError != null) {
      return _errorResult('Invalid arguments: $schemaError');
    }

    // SEC: RBAC check — load session + intersect roles.
    if (tool.definition.requiredRoles.isNotEmpty) {
      final session = await _credentialStore.read();
      final authError = _checkRbac(session, tool.definition.requiredRoles);
      if (authError != null) return authError;
    }

    // Handler must NEVER throw — try/catch is a safety net here.
    try {
      final result = await tool.invoke(args);
      return switch (result) {
        Success(:final value) => _successResult(value),
        Failure(:final error) => _errorResult(_redactCliError(error)),
      };
    } catch (e, st) {
      _logger.severe('tool.${tool.definition.name}.handler_threw', e, st);
      return _errorResult('Tool handler crashed (logged).');
    }
  }

  /// Returns `CallToolResult(isError: true, ...)` if RBAC denies; null otherwise.
  mcp.CallToolResult? _checkRbac(OidcSession? session, Set<String> required) {
    if (session == null) {
      return _errorResult(
        'Authentication required. Run "acdg auth login" first.',
      );
    }
    final actorRoles = session.roles.toSet();
    if (actorRoles.intersection(required).isEmpty) {
      return _errorResult(
        'Forbidden: requires one of [${required.join(', ')}].',
      );
    }
    return null;
  }

  mcp.CallToolResult _successResult(Object value) =>
      mcp.CallToolResult(content: [mcp.TextContent(text: _toJson(value))]);

  mcp.CallToolResult _errorResult(String message) => mcp.CallToolResult(
    isError: true,
    content: [mcp.TextContent(text: message)],
  );

  String _toJson(Object value) {
    // Use a stable JSON serializer — never expose StackTrace, Logger,
    // BffClient, or other non-data objects.
    // Implementation TBD in W3.
    throw UnimplementedError();
  }

  /// Sanitises CliError messages BEFORE they reach the AI host.
  ///
  /// Keep `stderrMessage` for `AuthRequiredError` (already user-safe).
  /// Replace technical details (NetworkError stack, ServerError raw body) with
  /// a generic blurb. Local logs still have the raw form via [_logger].
  String _redactCliError(Object error) => switch (error) {
    AuthRequiredError() => error.stderrMessage,
    RefreshTokenInvalidError() => error.stderrMessage,
    InvalidArgError(:final message) => 'Invalid argument: $message',
    NetworkError() => 'Network error reaching BFF (logged).',
    ServerError(:final statusCode) =>
      'Server returned $statusCode (logged).',
    KeychainUnavailable() ||
    KeychainOperationFailed() ||
    KeychainCorruptEntry() => 'Credential storage error (logged).',
    _ => 'Unexpected error (logged).',
  };
}

abstract interface class McpToolHandler {
  McpToolDefinition get definition;
  Future<Result<Object>> invoke(Map<String, Object?> args);
}
```

### 2.5 — `McpToolDefinition`

```dart
// apps/cli/lib/src/mcp/mcp_tool_definition.dart
import 'package:dart_mcp/server.dart' as mcp;
import 'package:equatable/equatable.dart';

/// Static metadata for a single MCP tool.
///
/// Value type — Equatable for golden test stability.
final class McpToolDefinition with EquatableMixin {
  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.requiredRoles,
  });

  /// Tool name as exposed via JSON-RPC (e.g. `"patient.list"`).
  final String name;

  /// Human-readable description for the AI host's tool picker.
  final String description;

  /// JSON Schema (JSON Schema draft 2020-12, what dart_mcp expects).
  final Map<String, Object?> inputSchema;

  /// Empty set = tool is unauthenticated (e.g. `health`).
  /// Non-empty = caller's session MUST have at least one of these roles.
  final Set<String> requiredRoles;

  /// Returns null on valid args; returns a short error message on invalid.
  /// W3 will use a small JSON Schema validator (or dart_mcp's helper).
  String? validateArgs(Map<String, Object?> args) {
    // W3 implements minimal schema validation: type checks + required fields.
    // Full $ref/format validation is out of MVP scope.
    throw UnimplementedError();
  }

  mcp.Tool toMcpTool() => mcp.Tool(
    name: name,
    description: description,
    inputSchema: inputSchema,
  );

  @override
  List<Object?> get props => [name, description, inputSchema, requiredRoles];
}
```

### 2.6 — Tool handlers (5 arquivos, padrão único)

Cada handler segue o mesmo shape. Exemplo `PatientGetTool`:

```dart
// apps/cli/lib/src/mcp/handlers/patient_get_tool.dart
import 'package:core_contracts/core_contracts.dart';

import '../../session/bff_client.dart';
import '../mcp_tool_definition.dart';
import '../mcp_tool_registry.dart';

final class PatientGetTool implements McpToolHandler {
  PatientGetTool({required BffClient bffClient}) : _bffClient = bffClient;

  final BffClient _bffClient;

  static const McpToolDefinition definition = McpToolDefinition(
    name: 'patient.get',
    description: 'Fetch a single patient by id (full detail).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'patientId': {
          'type': 'string',
          'description': 'Patient UUID',
        },
      },
      'required': ['patientId'],
      'additionalProperties': false,
    },
    requiredRoles: {'social_worker', 'owner', 'admin'},
  );

  @override
  McpToolDefinition get definition => PatientGetTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final patientId = args['patientId'] as String;
    final result = await _bffClient.get<Object?>('/patients/$patientId');
    return switch (result) {
      Success(:final value) => Success<Object>(_extractData(value)),
      Failure(:final error) => Failure<Object>(error),
    };
  }

  Object _extractData(Object? value) =>
      value is Map<String, Object?> && value.containsKey('data')
          ? value['data'] ?? const <String, Object?>{}
          : value ?? const <String, Object?>{};
}
```

Padrão para os outros 4:
- `HealthTool.invoke` → `bffClient.get<Object?>('/health/ready')`.
- `AuthStatusTool.invoke` → lê `_credentialStore.read()`, retorna `{ authenticated, userId, roles, expiresAt }`. Não faz BFF call.
- `PatientListTool.invoke` → valida `limit` ≤ 50, monta query string, chama `bffClient.get('/patients?limit=N&offset=M')`.
- `LookupGetTool.invoke` → `bffClient.get<Object?>('/lookups/$lookupId')`.

### 2.7 — `McpErrorMapper`

```dart
// apps/cli/lib/src/mcp/mcp_error_mapper.dart
import '../errors/cli_error.dart';

/// Converts dart_mcp / unknown exceptions into our sealed [McpAdapterError]
/// family. Used by the adapter's `onError` hook AND any catch-all in the
/// registry.
final class McpErrorMapper {
  const McpErrorMapper._();

  static McpAdapterError toAdapterError(Object error) => switch (error) {
    StateError(:final message) when _looksLikeTransport(message) =>
      McpTransportError(message),
    FormatException(:final message) =>
      McpProtocolError('Invalid frame: $message'),
    _ => McpProtocolError('Unexpected MCP error: ${error.runtimeType}'),
  };

  static bool _looksLikeTransport(String msg) =>
      msg.contains('stdio') || msg.contains('peer closed');
}
```

### 2.8 — Sealed `McpAdapterError`

Adicionar em `apps/cli/lib/src/errors/cli_error.dart` (manter sealed `CliError` como root):

```dart
/// MCP server adapter failures. Sealed sub-family of [CliError].
///
/// All four variants pass through the existing [CliError] machinery so
/// `acdg` exits with a meaningful code if the MCP server crashes.
sealed class McpAdapterError extends CliError {
  const McpAdapterError(super.message);
}

/// JSON-RPC protocol or schema malformed.
final class McpProtocolError extends McpAdapterError {
  const McpProtocolError(super.message);
  @override
  int get exitCode => 70; // EX_SOFTWARE
  @override
  String get stderrMessage => 'MCP protocol error: $message';
}

/// Stdio peer closed unexpectedly, transport-level failure.
final class McpTransportError extends McpAdapterError {
  const McpTransportError(super.message);
  @override
  int get exitCode => 74; // EX_IOERR
  @override
  String get stderrMessage => 'MCP transport error: $message';
}

/// A tool handler could not produce a valid result. Should be rare — the
/// registry catches handler exceptions and wraps as `CallToolResult`.
final class McpToolError extends McpAdapterError {
  const McpToolError(super.message);
  @override
  int get exitCode => 1;
  @override
  String get stderrMessage => 'MCP tool error: $message';
}

/// Caller has no session OR lacks the required role for the tool.
final class McpAuthError extends McpAdapterError {
  const McpAuthError(super.message);
  @override
  int get exitCode => 2;
  @override
  String get stderrMessage => 'MCP auth error: $message';
}
```

### 2.9 — `McpLoggerSetup`

```dart
// apps/cli/lib/src/mcp/mcp_logger_setup.dart
import 'package:logging/logging.dart';

/// Idempotent helper that pipes `Logger.root` to a [StringSink] (typically
/// `stderr`).
///
/// **MUST** run before [McpServerAdapter.start] — otherwise package:logging
/// records leak to `stdout` and corrupt the JSON-RPC frame.
final class McpLoggerSetup {
  const McpLoggerSetup._();

  static bool _installed = false;

  static void redirectToStderr(StringSink stderr) {
    if (_installed) return;
    _installed = true;
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((rec) {
      // SEC: never `print()` here — that's stdout.
      stderr.writeln(
        '[${rec.level.name}] ${rec.loggerName}: ${rec.message}'
        '${rec.error != null ? "\n  error: ${rec.error}" : ""}',
      );
    });
  }

  /// Test-only — resets the install flag so unit tests can re-attach.
  @visibleForTesting
  static void resetForTesting() {
    _installed = false;
  }
}
```

---

## §3 — Fluxo de uma tool call

Sequência do `tools/call patient.get { patientId: "P-1234" }`:

1. AI host envia JSON-RPC frame via stdin → `_AcdgMcpServer.callTool`.
2. `callTool` delega para `McpToolRegistry.dispatch('patient.get', {patientId: 'P-1234'})`.
3. Registry lookups `_tools['patient.get']` → `PatientGetTool`.
4. Registry chama `tool.definition.validateArgs({patientId: 'P-1234'})`. Schema OK → null.
5. Registry chama `_credentialStore.read()` → retorna `OidcSession` ou null.
6. RBAC: `requiredRoles = {social_worker, owner, admin}`. Sessão tem `social_worker` → OK.
7. Registry chama `tool.invoke({patientId: 'P-1234'})`.
8. `PatientGetTool.invoke` chama `bffClient.get('/patients/P-1234')`.
9. BFF retorna `{ "data": { "id": "P-1234", "name": "...", ... } }`.
10. `Success<Object?>` → registry envolve em `_successResult(value)` → `CallToolResult(content: [TextContent(text: jsonEncoded)])`.
11. `_AcdgMcpServer` retorna o `CallToolResult` ao peer; frame JSON-RPC sai via stdout.

Erro em qualquer ponto da sequência:
- 4 (schema): `_errorResult('Invalid arguments: <field>')`.
- 5 (sessão null): `_errorResult('Authentication required.')`.
- 6 (RBAC): `_errorResult('Forbidden: requires one of [...]')`.
- 8 (BFF 401): handler retorna `Failure(AuthRequiredError())` → registry redacta para `_errorResult('Authentication required. Run: acdg auth login')`.
- 8 (BFF 5xx): `Failure(ServerError(503, ...))` → `_errorResult('Server returned 503 (logged).')`. Detalhe técnico fica em `Logger.severe`.
- 8 (network): `Failure(NetworkError(...))` → `_errorResult('Network error reaching BFF (logged).')`.

**Em NENHUM caso o `CallToolResult` carrega stack trace, raw exception message, ou PII além do que o BFF já retornou.**

---

## §4 — Diferenças vs v1 (resumo executivo)

| Tema | v1 (errado) | v2 (este DESIGN) |
|---|---|---|
| Pacote | `mcp_dart` v2.1.1 (17K LOC, 739 dynamic) | `dart_mcp` v0.5.1 (Google, strict-casts, 6K LOC) |
| Stdio collision | TODO admitido em REPORT.md | Logger redirect explícito (`McpLoggerSetup`) + handlers chamam `BffClient` direto, sem stdout do CLI |
| Recursão CliRunner | `_cliRunner.run([...])` no handler | Handlers chamam `BffClient` + `CredentialStore` direto |
| Error model | Único `McpAdapterError(message)` | Sealed family: Protocol / Transport / Tool / Auth |
| RBAC | Ausente | `requiredRoles` declarativo na `McpToolDefinition` |
| Schema validation | Pseudo-código | `inputSchema` como JSON Schema literal + `validateArgs()` |
| Stack trace ao AI host | Default exposto pelo dart_mcp/mcp_dart | Adapter override + redaction no registry |
| E2E test | IOStream-only (in-memory) | **Subprocess stdio test** (`Process.start` + JSON-RPC handshake real) |

---

## §5 — RBAC matriz

| Tool | requiredRoles | Comportamento sem auth | Comportamento com role inválida |
|---|---|---|---|
| `health` | `{}` (none) | OK (sem check) | N/A |
| `auth.status` | `{}` (none) | retorna `{ authenticated: false }` | N/A |
| `patient.list` | `{social_worker, owner, admin}` | `Authentication required.` | `Forbidden: requires one of [...]` |
| `patient.get` | `{social_worker, owner, admin}` | idem | idem |
| `lookup.get` | `{social_worker, owner, admin}` | idem | idem |

---

## §6 — JSON Schemas (5 tools — fonte de verdade)

```dart
// HealthTool
inputSchema: { 'type': 'object', 'properties': {}, 'additionalProperties': false }

// AuthStatusTool
inputSchema: { 'type': 'object', 'properties': {}, 'additionalProperties': false }

// PatientListTool
inputSchema: {
  'type': 'object',
  'properties': {
    'limit': { 'type': 'integer', 'minimum': 1, 'maximum': 50, 'default': 10 },
    'offset': { 'type': 'integer', 'minimum': 0, 'default': 0 },
  },
  'additionalProperties': false,
}

// PatientGetTool
inputSchema: {
  'type': 'object',
  'properties': { 'patientId': { 'type': 'string', 'description': 'Patient UUID' } },
  'required': ['patientId'],
  'additionalProperties': false,
}

// LookupGetTool
inputSchema: {
  'type': 'object',
  'properties': { 'lookupId': { 'type': 'string', 'description': 'Lookup UUID' } },
  'required': ['lookupId'],
  'additionalProperties': false,
}
```

`validateArgs()` valida no MVP: `type: object`, presence of `required`, `additionalProperties: false`, basic type check de cada property. Não suporta `$ref`, `oneOf`, `pattern` (out of scope).

---

## §7 — Tests (preview W2 — RED)

| Test | Tipo | Localização |
|---|---|---|
| `McpServerAdapter.start()` connects via injected stdin/stdout | Unit | `test/mcp/mcp_server_adapter_test.dart` |
| `McpServerAdapter.start()` is idempotent guard (StateError on 2nd call) | Unit | idem |
| `McpServerAdapter.shutdown()` completes `done` | Unit | idem |
| `McpToolRegistry.dispatch` returns `Unknown tool` for unregistered name | Unit | `test/mcp/mcp_tool_registry_test.dart` |
| `McpToolRegistry.dispatch` validates schema before invoking handler | Unit | idem |
| `McpToolRegistry.dispatch` returns `Authentication required` when no session | Unit | idem |
| `McpToolRegistry.dispatch` returns `Forbidden` on role mismatch | Unit | idem |
| `McpToolRegistry.dispatch` redacts `NetworkError` to generic message | Unit | idem |
| `McpToolRegistry.dispatch` keeps `AuthRequiredError.stderrMessage` literal | Unit | idem |
| `HealthTool.invoke` returns Success on BFF 200 | Unit | `test/mcp/handlers/health_tool_test.dart` |
| `AuthStatusTool.invoke` returns `{ authenticated: false }` on null session | Unit | `test/mcp/handlers/auth_status_tool_test.dart` |
| `PatientListTool.invoke` rejects `limit > 50` via schema | Unit | `test/mcp/handlers/patient_list_tool_test.dart` |
| `PatientGetTool.invoke` extracts `data` envelope | Unit | `test/mcp/handlers/patient_get_tool_test.dart` |
| `LookupGetTool.invoke` propagates `Failure(ServerError(404))` | Unit | `test/mcp/handlers/lookup_get_tool_test.dart` |
| `McpErrorMapper.toAdapterError` switches over known error types | Unit | `test/mcp/mcp_error_mapper_test.dart` |
| `McpErrorMapper.toAdapterError` falls back to `McpProtocolError` | Unit | idem |
| `McpLoggerSetup.redirectToStderr` is idempotent | Unit | `test/mcp/mcp_logger_setup_test.dart` |
| `McpLoggerSetup` writes to stderr, never stdout | Unit | idem |
| **E2E stdio test:** `dart compile exe` + spawn + `initialize` + `tools/list` + `tools/call health` + clean shutdown | E2E | `test/mcp/e2e_stdio_test.dart` |
| **E2E stdio test:** stdout contains ONLY JSON-RPC frames (no log leak) | E2E | idem |
| **E2E stdio test:** logger output captured on stderr | E2E | idem |
| `McpAdapterError` sealed exhaustivity (compile-time) | Unit | `test/errors/cli_error_test.dart` |
| `McpProtocolError.exitCode == 70`, `McpTransportError == 74`, etc | Unit | idem |

> Total estimado: **23 tests** (4 mais que v1, todos cobrindo gaps reais do v1).

### Fakes necessárias (em `test/mcp/testing/`)

- `FakeBffClient` — implementa `BffClient` interface; setup `stub('/path', Result<T>)`.
- `FakeCredentialStore` — implementa `CredentialStore` interface; setup `stub(OidcSession?)`.
- `FakeLogger` — captura records para asserts em testes de logger.
- `FakeMcpStdioChannel` — para testes do adapter sem subprocess.

---

## §8 — Public API impact

`apps/cli/lib/cli.dart` ganha:

```dart
export 'src/commands/mcp_command.dart' show McpCommand;
// NÃO exportar McpServerAdapter, McpToolRegistry, handlers — internos.
```

`apps/cli/pubspec.yaml`:

```yaml
dependencies:
  # ...
  dart_mcp: 0.5.1   # PIN sem caret — boundary adapter absorve mudanças (ADR-MCP-001-v2)
```

`apps/cli/lib/src/cli_runner.dart` `_assemble`:

```dart
// add depois de team command:
..addCommand(
  McpCommand(
    bffClient: bffClient,
    credentialStore: _credentialStore,
    stdout: _stdout,
    stderr: _stderr,
  ),
)
```

---

## §9 — Critérios de "design completo"

- [x] Threat model identifica 6 vetores (CONTEXT §2).
- [x] 8 ADRs registradas (CONTEXT §3).
- [x] Cada classe tem signature concreta (DESIGN §2).
- [x] Fluxo de tool call mapeado passo-a-passo (DESIGN §3).
- [x] Sealed `McpAdapterError` com 4 variants + exitCode (DESIGN §2.8).
- [x] RBAC matriz declarativa, auditável (DESIGN §5).
- [x] 5 JSON Schemas literais (DESIGN §6).
- [x] 23 tests previstos cobrem cada classe + E2E stdio real (DESIGN §7).
- [x] Diferenças vs v1 documentadas — cada falha de v1 tem mitigação explícita (DESIGN §4).
- [x] Public API impact contained — único export é `McpCommand` (DESIGN §8).

---

## §10 — Próximo passo

**Aguardando aprovação do user no DESIGN.md e CONTEXT.md.**

Após aprovação:

1. Despachar agent **`test-writer`** (W2) — escrever 23 tests RED em `test/mcp/`. Tests devem falhar contra o estado atual (sem nenhum dos arquivos `mcp/`). Não escreve código de produção.
2. Despachar agent **`flutter-bff-implementer`** (W3) — implementar W2 GREEN seguindo este DESIGN. Adiciona `dart_mcp` ao pubspec, cria os arquivos de `lib/src/mcp/` e `lib/src/commands/mcp_*.dart`, ajusta `cli_runner.dart` + `cli.dart` + `cli_error.dart`.
3. Despachar agent **`flutter-code-reviewer`** (W4) — defensive review. Verifica REGRA #2, sealed exhaustivity, redaction, stdio policy. Output: APPROVED | REJECTED com routing.
4. Despachar agent **`flutter-quality-checker`** (W5) — `dart analyze`, `dart format`, `dart test`, `dart compile exe`, E2E stdio test.
5. **External review com Charter** — auto-discovery: paths tocados (`apps/cli/lib/src/mcp/`, `commands/mcp_*.dart`, `cli_error.dart`, `pubspec.yaml`, `cli_runner.dart`) → anexa charter §2.1 (Result discipline), §2.2 (throw policy), §2.3 (REGRA #2), §2.4 (Equatable contract), §2.7 (appsec checklist) + skill `cli-craftsman` integral. Spec adversarial NO TOPO.

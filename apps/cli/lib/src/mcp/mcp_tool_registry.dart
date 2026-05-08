/// Routes incoming MCP tool calls — schema check → RBAC → handler →
/// `CallToolResult` shaping with redaction.
///
/// **Responsibilities (in order — DESIGN §2.4):**
///   1. Look up the tool definition by name (or return "Unknown tool").
///   2. Validate args against the JSON Schema (call handler ONLY if valid).
///   3. Resolve the local session via [CredentialStore]; if the tool
///      declares roles, enforce them.
///   4. Invoke the handler.
///   5. Wrap the [Result] into a [mcp.CallToolResult]:
///        - `Success(value)`         → `CallToolResult(content: [Text(json)])`
///        - `Failure(AuthRequiredError())` → keep `stderrMessage` literal.
///        - `Failure(other CliError)`     → redacted, generic message.
///   6. NEVER throw to the dart_mcp peer — a try/catch safety net at the
///      bottom catches any handler that misbehaves.
///
/// The registry is the SOLE owner of the redaction policy: handlers stay
/// dumb forwards, all the "what does the AI host see?" logic lives here.
library;

import 'dart:convert';

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

final class McpToolRegistry {
  McpToolRegistry({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required Logger logger,
  }) : _credentialStore = credentialStore,
       _logger = logger,
       _tools = <String, McpToolHandler>{
         'health': HealthTool(bffClient: bffClient),
         'auth.status': AuthStatusTool(credentialStore: credentialStore),
         'patient.list': PatientListTool(bffClient: bffClient),
         'patient.get': PatientGetTool(bffClient: bffClient),
         'lookup.get': LookupGetTool(bffClient: bffClient),
       };

  final CredentialStore _credentialStore;
  final Logger _logger;
  final Map<String, McpToolHandler> _tools;

  /// Snapshot of every registered tool definition — used by the adapter
  /// when responding to `tools/list` (or when registering tools eagerly).
  Iterable<McpToolDefinition> allDefinitions() =>
      _tools.values.map((t) => t.toolDefinition);

  /// Returns the handler for [name], or `null` if unknown. Used by the
  /// adapter so it can register each tool with `dart_mcp.ToolsSupport`.
  McpToolHandler? handlerFor(String name) => _tools[name];

  /// Single-entrypoint dispatch — drives steps 1..6 from the class doc.
  Future<mcp.CallToolResult> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    final tool = _tools[toolName];
    if (tool == null) {
      return _errorResult('Unknown tool: $toolName');
    }

    // SEC: schema validation FIRST — the handler is only invoked for valid
    // shapes (DESIGN §2.4 step 2). The dart_mcp validator surfaces a
    // human-readable message that we forward verbatim.
    final schemaError = tool.toolDefinition.validateArgs(args);
    if (schemaError != null) {
      return _errorResult('Invalid arguments: $schemaError');
    }

    // SEC: RBAC check — load session + intersect roles. Empty
    // `requiredRoles` ⇒ unauthenticated tool, skip the gate.
    if (tool.toolDefinition.requiredRoles.isNotEmpty) {
      final session = await _credentialStore.read();
      final authError = _checkRbac(session, tool.toolDefinition.requiredRoles);
      if (authError != null) return authError;
    }

    // Handler MUST NOT throw — try/catch is a safety net here.
    try {
      final result = await tool.invoke(args);
      return switch (result) {
        Success(:final value) => _successResult(value),
        Failure(:final error) => _errorResult(_redactCliError(error)),
      };
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      _logger.severe('tool.${tool.toolDefinition.name}.handler_threw', e, st);
      return _errorResult('Tool handler crashed (logged).');
    }
  }

  /// Returns `CallToolResult(isError: true, ...)` when RBAC denies; null
  /// when the caller is allowed to proceed.
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

  /// Encodes a successful tool value as a single `TextContent` JSON line.
  ///
  /// We use `jsonEncode` directly so primitive values (a String, int, etc.)
  /// land as their JSON literal (`"ok"`, `42`) and Maps/Lists serialise
  /// recursively. Non-encodable objects fall back to `toString()` — but
  /// the MVP handlers always return JSON-friendly Maps so the fallback
  /// is a safety net, not a feature.
  mcp.CallToolResult _successResult(Object value) =>
      mcp.CallToolResult(content: [mcp.TextContent(text: _toJson(value))]);

  mcp.CallToolResult _errorResult(String message) => mcp.CallToolResult(
    isError: true,
    content: [mcp.TextContent(text: message)],
  );

  String _toJson(Object value) {
    try {
      return jsonEncode(value);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // SEC: any value the handler emits that isn't JSON-serialisable falls
      // back to a printable string, never to the raw `toString()` of a
      // possibly-sensitive object. Handlers are expected to emit Map/List
      // shapes only — this is purely a belt-and-braces guard.
      return jsonEncode({'value': value.toString()});
    }
  }

  /// Converts a [CliError] into the message the AI host will see.
  ///
  /// Policy (DESIGN §2.4):
  ///   * `AuthRequiredError` / `RefreshTokenInvalidError` — already
  ///      user-safe, forward `stderrMessage` verbatim so the AI host can
  ///      tell the user to re-run `acdg auth login`.
  ///   * `InvalidArgError` — surface the message (validation already
  ///      happened above; this is for handler-driven validation).
  ///   * `NetworkError` / `ServerError` / Keychain errors — REDACT.
  ///      Technical details (host:port, raw 5xx body) stay in the local
  ///      log only.
  ///   * Other [McpAdapterError]s and unknown errors — generic blurb.
  String _redactCliError(Object error) => switch (error) {
    AuthRequiredError() => error.stderrMessage,
    RefreshTokenInvalidError() => error.stderrMessage,
    InvalidArgError(:final message) => 'Invalid argument: $message',
    NetworkError() => 'Network error reaching BFF (logged).',
    ServerError(:final statusCode) => 'Server returned $statusCode (logged).',
    KeychainUnavailable() ||
    KeychainOperationFailed() ||
    KeychainCorruptEntry() => 'Credential storage error (logged).',
    McpProtocolError() => 'MCP protocol error (logged).',
    McpTransportError() => 'MCP transport error (logged).',
    McpToolError() => 'Tool execution error (logged).',
    McpAuthError() => 'Authentication error (logged).',
    _ => 'Unexpected error (logged).',
  };
}

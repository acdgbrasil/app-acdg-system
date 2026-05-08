/// Static metadata for a single MCP tool.
///
/// Holds a `dart_mcp` [mcp.ObjectSchema] so the package's own validator
/// (`Schema.validate(data) → List<ValidationError>`) drives [validateArgs].
/// We keep the validation surface as a `String?` (null = ok, non-null =
/// human readable error) so the registry can pass the message straight
/// through to the AI host without coupling to `dart_mcp` types.
///
/// **Why this is a value type with [Equatable].** Tool definitions are
/// declarative metadata; two definitions with the same name + schema +
/// roles must compare equal so golden tests on `tools/list` are stable.
/// Per the encapsulation policy (H4), value types use `with EquatableMixin`
/// rather than `extends Equatable` (the latter is the project canon).
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

/// Static metadata for a single MCP tool.
///
/// Equatable on `(name, description, requiredRoles, schemaSnapshot)` —
/// where `schemaSnapshot` is the underlying JSON map of the schema, since
/// `mcp.ObjectSchema` is itself an extension type around a `Map`.
final class McpToolDefinition with Equatable {
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

  /// JSON Schema (a `dart_mcp` [mcp.ObjectSchema]) describing the expected
  /// arguments. Used both by [validateArgs] (server-side gate) AND by
  /// [toMcpTool] (advertised to the client).
  final mcp.ObjectSchema inputSchema;

  /// Empty set = tool is unauthenticated (e.g. `health`, `auth.status`).
  /// Non-empty = caller's session MUST have at least one of these roles.
  final Set<String> requiredRoles;

  /// Validates [args] against [inputSchema].
  ///
  /// Returns `null` when valid; otherwise returns a single user-readable
  /// error message that the registry can surface in `CallToolResult.text`.
  /// We collapse the (possibly multiple) `ValidationError`s into one line
  /// so the AI host gets a stable, paste-friendly message.
  String? validateArgs(Map<String, Object?> args) {
    final errors = inputSchema.validate(args);
    if (errors.isEmpty) return null;
    return errors.map((e) => e.toErrorString()).join('; ');
  }

  /// Materialises the [mcp.Tool] that `dart_mcp` advertises for `tools/list`.
  mcp.Tool toMcpTool() =>
      mcp.Tool(name: name, description: description, inputSchema: inputSchema);

  @override
  List<Object?> get props => [name, description, requiredRoles];
}

/// Contract every MVP tool handler implements.
///
/// Lives in this file to break the import cycle between handlers/ and the
/// registry (the registry holds a `Map<String, McpToolHandler>` and the
/// handlers carry their own [definition] back to the registry without
/// reaching across).
///
/// **Naming note.** The instance accessor is [toolDefinition] (not
/// `definition`) so each handler is free to expose a `static final
/// definition` field — Dart forbids a class from defining a static and
/// instance member with the same name. The static is what tests reach
/// for (`PatientListTool.definition.validateArgs(...)`); the instance
/// getter is what the registry walks (`tool.toolDefinition`).
abstract interface class McpToolHandler {
  /// Static metadata for this tool — used by the registry for routing,
  /// schema validation, and RBAC checks.
  McpToolDefinition get toolDefinition;

  /// Pure invocation. Returns a [Result] — handlers MUST NOT throw.
  /// The registry redacts [Failure] values before they reach the AI host.
  Future<Result<Object>> invoke(Map<String, Object?> args);
}

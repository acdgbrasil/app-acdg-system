/// `health` MCP tool — `GET /health/ready` (no auth, no schema).
///
/// The smoke test of the MVP set (DESIGN §6). Surfaces whatever the BFF
/// returns; the registry serialises it into the [CallToolResult].
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

import '../../session/bff_client.dart';
import '../mcp_tool_definition.dart';

final class HealthTool implements McpToolHandler {
  HealthTool({required BffClient bffClient}) : _bffClient = bffClient;

  final BffClient _bffClient;

  /// Static schema — empty object. The MVP `health` tool takes no args.
  static final McpToolDefinition definition = McpToolDefinition(
    name: 'health',
    description: 'BFF readiness probe — returns status and version.',
    inputSchema: mcp.ObjectSchema(
      properties: const <String, mcp.Schema>{},
      additionalProperties: false,
    ),
    // SEC: empty roles — `health` is unauthenticated by design.
    requiredRoles: const <String>{},
  );

  @override
  McpToolDefinition get toolDefinition => HealthTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final result = await _bffClient.get<Object?>('/health/ready');
    return result.map((value) => value ?? const <String, Object?>{});
  }
}

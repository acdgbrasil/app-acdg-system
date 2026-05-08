/// `lookup.get` MCP tool — `GET /lookups/:id`.
///
/// Failure propagation contract: the handler MUST forward `Failure(...)`
/// untouched so the registry's redaction layer can decide what reaches
/// the AI host (DESIGN §2.4 `_redactCliError`).
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

import '../../session/bff_client.dart';
import '../mcp_tool_definition.dart';

final class LookupGetTool implements McpToolHandler {
  LookupGetTool({required BffClient bffClient}) : _bffClient = bffClient;

  final BffClient _bffClient;

  static final McpToolDefinition definition = McpToolDefinition(
    name: 'lookup.get',
    description: 'Fetch a lookup table by id.',
    inputSchema: mcp.ObjectSchema(
      properties: <String, mcp.Schema>{
        'lookupId': mcp.Schema.string(description: 'Lookup UUID'),
      },
      required: const <String>['lookupId'],
      additionalProperties: false,
    ),
    requiredRoles: const <String>{'social_worker', 'owner', 'admin'},
  );

  @override
  McpToolDefinition get toolDefinition => LookupGetTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final lookupId = args['lookupId']! as String;
    final result = await _bffClient.get<Object?>('/lookups/$lookupId');
    return result.map(_extractData);
  }

  Object _extractData(Object? value) {
    if (value is Map<String, Object?> && value.containsKey('data')) {
      return value['data'] ?? const <String, Object?>{};
    }
    return value ?? const <String, Object?>{};
  }
}

/// `patient.list` MCP tool — paginated list (`GET /patients?limit=N&offset=M`).
///
/// Schema enforces `limit ∈ [1, 50]` and `offset ≥ 0` so the AI host
/// cannot ask for more than 50 patients in a single shot. The hard ceiling
/// is in the BFF too (defence-in-depth) but the MCP gate trips first with
/// a clearer error.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

import '../../session/bff_client.dart';
import '../mcp_tool_definition.dart';

final class PatientListTool implements McpToolHandler {
  PatientListTool({required BffClient bffClient}) : _bffClient = bffClient;

  final BffClient _bffClient;

  /// Public so tests can call `PatientListTool.definition.validateArgs(...)`
  /// without instantiating the handler. Same field on every handler.
  static final McpToolDefinition definition = McpToolDefinition(
    name: 'patient.list',
    description:
        'List patients (paginated). Returns up to 50 entries per call.',
    inputSchema: mcp.ObjectSchema(
      properties: <String, mcp.Schema>{
        'limit': mcp.Schema.int(
          description: 'Max items per page (1..50).',
          minimum: 1,
          maximum: 50,
        ),
        'offset': mcp.Schema.int(
          description: 'Zero-based offset into the result set.',
          minimum: 0,
        ),
      },
      additionalProperties: false,
    ),
    requiredRoles: const <String>{'social_worker', 'owner', 'admin'},
  );

  @override
  McpToolDefinition get toolDefinition => PatientListTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final limit = args['limit'] is int ? args['limit'] as int : 10;
    final offset = args['offset'] is int ? args['offset'] as int : 0;
    final result = await _bffClient.get<Object?>(
      '/patients',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return result.map(_extractData);
  }

  /// Surfaces the inner `data` envelope when present so the AI host sees
  /// the patient list directly. Mirrors [PatientGetTool._extractData].
  Object _extractData(Object? value) {
    if (value is Map<String, Object?> && value.containsKey('data')) {
      return value['data'] ?? const <String, Object?>{};
    }
    return value ?? const <String, Object?>{};
  }
}

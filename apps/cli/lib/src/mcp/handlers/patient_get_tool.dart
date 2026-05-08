/// `patient.get` MCP tool — `GET /patients/:id`.
///
/// Strips the BFF's `{ data, meta }` envelope so the AI host sees only the
/// patient document. PII tarjada is the BFF's responsibility — this layer
/// just forwards.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

import '../../session/bff_client.dart';
import '../mcp_tool_definition.dart';

final class PatientGetTool implements McpToolHandler {
  PatientGetTool({required BffClient bffClient}) : _bffClient = bffClient;

  final BffClient _bffClient;

  static final McpToolDefinition definition = McpToolDefinition(
    name: 'patient.get',
    description: 'Fetch a single patient by id (full detail).',
    inputSchema: mcp.ObjectSchema(
      properties: <String, mcp.Schema>{
        'patientId': mcp.Schema.string(description: 'Patient UUID'),
      },
      required: const <String>['patientId'],
      additionalProperties: false,
    ),
    requiredRoles: const <String>{'social_worker', 'owner', 'admin'},
  );

  @override
  McpToolDefinition get toolDefinition => PatientGetTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final patientId = args['patientId']! as String;
    final result = await _bffClient.get<Object?>('/patients/$patientId');
    return result.map(_extractData);
  }

  /// BFF wraps successful responses in `{ "data": {...}, "meta": {...} }`.
  /// The AI host should see only the patient document.
  Object _extractData(Object? value) {
    if (value is Map<String, Object?> && value.containsKey('data')) {
      return value['data'] ?? const <String, Object?>{};
    }
    return value ?? const <String, Object?>{};
  }
}

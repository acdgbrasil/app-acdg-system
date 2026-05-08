/// `auth.status` MCP tool — reads the local [CredentialStore] and returns
/// the authentication snapshot.
///
/// Does NOT call the BFF; the snapshot reflects what the CLI sees on disk
/// (XDG keychain). When no session is present, the response is
/// `{ authenticated: false }`.
library;

import 'package:core_contracts/core_contracts.dart';
import 'package:dart_mcp/server.dart' as mcp;

import '../../session/credential_store.dart';
import '../mcp_tool_definition.dart';

final class AuthStatusTool implements McpToolHandler {
  AuthStatusTool({required CredentialStore credentialStore})
    : _credentialStore = credentialStore;

  final CredentialStore _credentialStore;

  static final McpToolDefinition definition = McpToolDefinition(
    name: 'auth.status',
    description:
        'Local authentication snapshot — userId, roles, and token expiry.',
    inputSchema: mcp.ObjectSchema(
      properties: const <String, mcp.Schema>{},
      additionalProperties: false,
    ),
    // SEC: no roles required — the tool itself reports "no session" cleanly.
    requiredRoles: const <String>{},
  );

  @override
  McpToolDefinition get toolDefinition => AuthStatusTool.definition;

  @override
  Future<Result<Object>> invoke(Map<String, Object?> args) async {
    final session = await _credentialStore.read();
    if (session == null) {
      return const Success<Object>(<String, Object?>{'authenticated': false});
    }
    return Success<Object>(<String, Object?>{
      'authenticated': true,
      'userId': session.sub,
      'email': session.email,
      'roles': session.roles,
      'expiresAt': session.accessExpiresAt.toUtc().toIso8601String(),
    });
  }
}

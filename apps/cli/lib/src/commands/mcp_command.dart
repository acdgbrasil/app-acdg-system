/// `acdg mcp` — Model Context Protocol parent command.
///
/// MVP exposes a single subcommand (`serve`). Future waves may add
/// `mcp serve --http` (B6+) under the same parent — keeping a parent
/// container makes the discovery surface stable.
library;

import 'package:args/command_runner.dart';

import '../session/bff_client.dart';
import '../session/credential_store.dart';
import 'mcp_serve_command.dart';

final class McpCommand extends Command<int> {
  McpCommand({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required StringSink stdout,
    required StringSink stderr,
  }) {
    addSubcommand(
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

/// `acdg mcp serve` — starts the MCP server over stdio.
///
/// **STDIO contract.** This command takes ownership of `stdin`/`stdout` for
/// JSON-RPC. [McpLoggerSetup.redirectToStderr] runs BEFORE the adapter
/// starts so any `package:logging` consumer (including `dart_mcp` itself)
/// writes to stderr only. A rogue `print` / `stdout.write` from any
/// dependency would corrupt the channel — guarded by the e2e stdio test.
library;

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../mcp/mcp_logger_setup.dart';
import '../mcp/mcp_server_adapter.dart';
import '../session/bff_client.dart';
import '../session/credential_store.dart';

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
    // SEC: redirect Logger root to stderr BEFORE any other init. dart_mcp
    // internals AND every package using `package:logging` would otherwise
    // emit to stdout and corrupt the JSON-RPC frame.
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

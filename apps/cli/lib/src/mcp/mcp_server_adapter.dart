/// Boundary adapter that isolates `package:dart_mcp` from the CLI domain.
///
/// **Single responsibility (DESIGN §2.3):** own the dart_mcp server
/// lifecycle. Conversion of dart_mcp exceptions into the sealed
/// [McpAdapterError] family happens here.
///
/// **Why a private subclass of [mcp.MCPServer]?** `dart_mcp` requires a
/// concrete `MCPServer` implementation to mix in `ToolsSupport`. Keeping
/// `_AcdgMcpServer` private to this file ensures the only place that
/// imports `package:dart_mcp/server.dart` is this single adapter file —
/// every other layer talks through [McpToolRegistry] using only the
/// [Result] / [CliError] domain types.
///
/// SEC: throw policy. The adapter boundary is the ONLY place `throw` is
/// allowed (defined panic): a second [start] call is a programmer error
/// and trips a [StateError] so tests catch it loudly. Internal `dart_mcp`
/// errors are converted, never re-thrown to the peer.
library;

import 'dart:async';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart' as mcp;
import 'package:dart_mcp/stdio.dart' as stdio;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../session/bff_client.dart';
import '../session/credential_store.dart';
import 'mcp_error_mapper.dart';
import 'mcp_tool_registry.dart';

/// Lifecycle wrapper around the underlying [mcp.MCPServer].
final class McpServerAdapter {
  McpServerAdapter({
    required BffClient bffClient,
    required CredentialStore credentialStore,
    required Logger logger,
    @visibleForTesting Stream<List<int>>? stdinOverride,
    @visibleForTesting StreamSink<List<int>>? stdoutOverride,
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
  final StreamSink<List<int>> _stdout;

  _AcdgMcpServer? _server;
  final Completer<void> _done = Completer<void>();

  /// Completes when the JSON-RPC peer closes (clean shutdown or error).
  Future<void> get done => _done.future;

  /// Starts the MCP server and registers every tool with `dart_mcp`.
  ///
  /// Idempotent guard — a second call throws [StateError] (defined panic
  /// at the adapter boundary; ADR-019 allows this on the throw policy).
  Future<void> start() async {
    if (_server != null) {
      throw StateError('McpServerAdapter.start() called twice');
    }

    final channel = stdio.stdioChannel(input: _stdin, output: _stdout);

    final server = _AcdgMcpServer(channel, logger: _logger);
    _server = server;

    // Register every MVP tool. The dispatch goes through the registry so
    // schema validation, RBAC, and redaction happen in ONE place. We pass
    // `validateArguments: false` because the registry already validates
    // (single source of truth — DESIGN §2.4 step 2).
    for (final def in _registry.allDefinitions()) {
      server.registerTool(
        def.toMcpTool(),
        (request) =>
            _registry.dispatch(request.name, request.arguments ?? const {}),
        validateArguments: false,
      );
    }

    // The dart_mcp `done` future completes once the peer closes; bridge it
    // into our own `done` so callers awaiting the adapter shut down with
    // the same lifecycle.
    unawaited(
      server.done.whenComplete(() {
        if (!_done.isCompleted) _done.complete();
      }),
    );

    // SEC: emit AFTER tools are registered so a `tools/list` racing the
    // first frame still sees the full set. This log line also doubles as
    // the e2e stdio test's stderr canary (DESIGN §1.2 line 244).
    _logger.info('acdg-mcp server connected (stdio)');
  }

  /// Graceful shutdown. Idempotent — safe to call multiple times.
  Future<void> shutdown() async {
    final server = _server;
    if (server == null) {
      // Even when nothing was started, completing `done` keeps callers
      // who awaited it from hanging.
      if (!_done.isCompleted) _done.complete();
      return;
    }
    await server.shutdown();
    _server = null;
    if (!_done.isCompleted) _done.complete();
  }

  // SEC (intentionally unused): the registry catches every handler-side
  // throw before dart_mcp sees it, so dart_mcp never receives a raw
  // exception that would leak via its default `onError`. Kept for parity
  // with DESIGN §2.3 and reachable from the registry's safety net log if
  // we ever route adapter-level errors through it.
  // ignore: unused_element
  void _onUnhandledError(Object error, StackTrace? stack) {
    final mapped = McpErrorMapper.toAdapterError(error);
    _logger.severe('mcp.unhandled', mapped, stack);
  }
}

/// Internal `MCPServer` subclass with [mcp.ToolsSupport] mixin.
///
/// Lives inside [McpServerAdapter] so the dart_mcp dependency stays
/// confined to a single file.
final class _AcdgMcpServer extends mcp.MCPServer with mcp.ToolsSupport {
  _AcdgMcpServer(super.channel, {required Logger logger})
    : _logger = logger,
      super.fromStreamChannel(
        implementation: mcp.Implementation(name: 'acdg-mcp', version: '0.1.0'),
      );

  // Reserved for protocol-level diagnostics (server name in log lines).
  // ignore: unused_field
  final Logger _logger;
}

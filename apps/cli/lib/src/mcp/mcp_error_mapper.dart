/// Maps low-level / `dart_mcp` exceptions into the sealed [McpAdapterError]
/// family.
///
/// Used by:
///   * [McpServerAdapter._onUnhandledError] — when `dart_mcp` surfaces an
///     unhandled error on the channel, we map it BEFORE logging to keep
///     redaction consistent.
///   * Anywhere else that needs to coerce an arbitrary [Object] into the
///     typed family without a `try/catch` ladder.
///
/// SEC (DESIGN §2.7) — the fallback arm carries only the runtime type name,
/// never the original message, so a leaked stack-trace string in the
/// exception's `toString()` doesn't end up in the user-facing CallToolResult.
library;

import '../errors/cli_error.dart';

/// Pure mapping function — no I/O, no state.
final class McpErrorMapper {
  const McpErrorMapper._();

  /// Converts [error] into the matching [McpAdapterError] variant.
  ///
  /// Known arms:
  ///   * [StateError] whose message mentions stdio or peer-closed → [McpTransportError].
  ///   * [FormatException] → [McpProtocolError] (JSON-RPC framing).
  ///   * Anything else → [McpProtocolError] carrying the runtime type only.
  static McpAdapterError toAdapterError(Object error) => switch (error) {
    StateError(:final message) when _looksLikeTransport(message) =>
      McpTransportError(message),
    FormatException(:final message) => McpProtocolError(
      'Invalid frame: $message',
    ),
    // SEC: fallback intentionally drops the original `toString()` so a
    // stack-trace-laden message cannot leak to the AI host. The runtime
    // type alone is enough for the adapter log to triage the cause.
    _ => McpProtocolError('Unexpected MCP error: ${error.runtimeType}'),
  };

  /// Heuristic — a [StateError] originating from stdio / peer close
  /// usually mentions one of these tokens. Kept defensive: false negatives
  /// land on the generic protocol-error fallback (still safe).
  static bool _looksLikeTransport(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('stdio') ||
        lower.contains('peer closed') ||
        lower.contains('peer_closed') ||
        lower.contains('closed the stdio');
  }
}

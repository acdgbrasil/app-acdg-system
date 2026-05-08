/// Logger redirect helper — pipes `Logger.root` records to the supplied
/// [StringSink] (typically `stderr`).
///
/// **Why this exists.** `acdg mcp serve` claims `stdout` for JSON-RPC frames
/// (ADR-MCP-002-v2). Any package using `package:logging` (including
/// `dart_mcp` itself, `dio`, etc.) that writes to `stdout` would corrupt the
/// MCP wire format. This helper installs ONE listener that funnels every
/// log record into the supplied sink — no `print()`, no `stdout.write` —
/// so the canal stays clean.
///
/// **Idempotency.** [redirectToStderr] tracks an install flag; a second
/// call is a no-op so importers (and tests) cannot double-attach the
/// listener and emit each record twice.
///
/// SEC: ADR-MCP-005-v2 — must run BEFORE `McpServerAdapter.start`.
library;

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// Idempotent helper that pipes [Logger.root] to a [StringSink] (stderr in
/// production).
final class McpLoggerSetup {
  const McpLoggerSetup._();

  static bool _installed = false;

  /// Installs a single listener on [Logger.root] that writes every record
  /// to [sink]. The format is intentionally simple (one line per record)
  /// so an operator tailing stderr sees a coherent log stream.
  ///
  /// Subsequent calls are no-ops — see class doc for rationale.
  static void redirectToStderr(StringSink sink) {
    if (_installed) return;
    _installed = true;
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((rec) {
      // SEC: never `print()` here — that's stdout.
      final errorSuffix = rec.error != null ? '\n  error: ${rec.error}' : '';
      sink.writeln(
        '[${rec.level.name}] ${rec.loggerName}: ${rec.message}$errorSuffix',
      );
    });
  }

  /// Test-only — resets the install flag so unit tests can re-attach the
  /// listener inside their own `setUp`. Production callers never invoke
  /// this; the flag is meant to be sticky for the lifetime of the process.
  @visibleForTesting
  static void resetForTesting() {
    _installed = false;
  }
}

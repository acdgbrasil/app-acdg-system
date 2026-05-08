/// W2 RED helper — captures `package:logging` records for stderr-redirect
/// assertions. Stays self-contained so the McpLoggerSetup tests can attach
/// without colliding with the global `Logger.root` listener that the helper
/// itself installs (each test owns its own subscription).
library;

import 'dart:async';

import 'package:logging/logging.dart';

/// Subscribes to [Logger.root] and accumulates every [LogRecord] emitted
/// while the subscription is open. Tests that mutate the global root must
/// call [dispose] in `tearDown` (or an equivalent cleanup hook) to avoid
/// leaking subscriptions across tests.
final class FakeLogger {
  FakeLogger() {
    Logger.root.level = Level.ALL;
    _subscription = Logger.root.onRecord.listen(records.add);
  }

  final List<LogRecord> records = [];
  late final StreamSubscription<LogRecord> _subscription;

  Future<void> dispose() async {
    await _subscription.cancel();
  }
}

/// Captures writes against a [StringSink] so tests can assert that the
/// MCP logger setup emits to stderr (and only stderr).
final class CapturingStringSink implements StringSink {
  final StringBuffer buffer = StringBuffer();

  @override
  void write(Object? object) => buffer.write(object);

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  void writeln([Object? object = '']) => buffer.writeln(object);
}

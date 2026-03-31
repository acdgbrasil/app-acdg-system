import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logger for the ACDG ecosystem.
///
/// Uses [package:logging] and outputs to [dart:developer.log] in debug mode.
abstract final class AcdgLogger {
  static bool _initialized = false;

  /// Initializes the logging system.
  ///
  /// Should be called at app startup (e.g., in main()).
  static void initialize() {
    if (_initialized) return;

    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        dev.log(
          record.message,
          time: record.time,
          sequenceNumber: record.sequenceNumber,
          level: record.level.value,
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      }
    });

    _initialized = true;
  }

  /// Returns a logger for a specific [name].
  static Logger get(String name) => Logger(name);
}

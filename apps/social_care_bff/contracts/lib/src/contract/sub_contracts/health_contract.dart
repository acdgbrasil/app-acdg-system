import 'package:core_contracts/core_contracts.dart';

/// Health check contract — liveness and readiness probes.
abstract interface class HealthContract {
  /// Liveness probe — returns success if the service is running.
  Future<Result<void>> checkHealth();

  /// Readiness probe — checks connectivity with dependencies.
  Future<Result<void>> checkReady();
}

import 'package:core_contracts/core_contracts.dart';

import '../../use_cases/health/check_health_use_case.dart';
import '../../use_cases/health/check_ready_use_case.dart';

/// Health sub-facade — 2 thin pass-through methods over the Health use
/// cases (A18b-v2). Health is Pattern 3 — pure passthrough; no cache,
/// no queue.
class HealthFacade {
  HealthFacade.internal({
    required CheckHealthUseCase checkHealth,
    required CheckReadyUseCase checkReady,
  }) : _checkHealth = checkHealth,
       _checkReady = checkReady;

  final CheckHealthUseCase _checkHealth;
  final CheckReadyUseCase _checkReady;

  Future<Result<void>> checkHealth() => _checkHealth();

  Future<Result<void>> checkReady() => _checkReady();
}

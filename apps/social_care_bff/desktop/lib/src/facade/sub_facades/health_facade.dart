import 'package:core_contracts/core_contracts.dart';

import '../composition/builders/health_use_cases.dart';

/// Health sub-facade — 2 thin pass-through methods over the Health use
/// cases (A18b-v2). Health is Pattern 3 — pure passthrough; no cache,
/// no queue.
///
/// Backed by [HealthUseCases] — a data class grouping the 2 probe use
/// cases (D02).
class HealthFacade {
  HealthFacade.internal({required HealthUseCases useCases})
    : _useCases = useCases;

  final HealthUseCases _useCases;

  Future<Result<void>> checkHealth() => _useCases.checkHealth();

  Future<Result<void>> checkReady() => _useCases.checkReady();
}

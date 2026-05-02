/// Bundles the 2 Health probe use cases (A18b-v2). Pure passthroughs —
/// no cache, no outbox, no engine, no clock:
///   * `CheckHealthUseCase` — `remote: HealthContract` only
///   * `CheckReadyUseCase`  — `remote: HealthContract` only
///
/// Health's [build] is the slimmest of the 7 — only `remote:`. The
/// asymmetry is documented in the data class itself.
library;

import 'package:shared/shared.dart';

import '../../../use_cases/health/check_health_use_case.dart';
import '../../../use_cases/health/check_ready_use_case.dart';

/// Data class grouping the 2 Health use cases.
class HealthUseCases {
  HealthUseCases({required this.checkHealth, required this.checkReady});

  final CheckHealthUseCase checkHealth;
  final CheckReadyUseCase checkReady;

  /// Constructs both Health probe use cases from the shared remote.
  static HealthUseCases build({required HealthContract remote}) {
    return HealthUseCases(
      checkHealth: CheckHealthUseCase(remote: remote),
      checkReady: CheckReadyUseCase(remote: remote),
    );
  }
}

import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Pattern 3 — pure passthrough.
///
/// Liveness probes are real-time signals; caching them would surface
/// stale "service is up" assertions. Use case delegates to the
/// remote and forwards the [Result] verbatim.
class CheckHealthUseCase {
  CheckHealthUseCase({required HealthContract remote}) : _remote = remote;

  final HealthContract _remote;

  Future<Result<void>> call() => _remote.checkHealth();
}

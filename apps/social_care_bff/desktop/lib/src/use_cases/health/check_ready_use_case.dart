import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

/// Pattern 3 — pure passthrough. Mirrors [CheckHealthUseCase] for the
/// readiness probe.
class CheckReadyUseCase {
  CheckReadyUseCase({required HealthContract remote}) : _remote = remote;

  final HealthContract _remote;

  Future<Result<void>> call() => _remote.checkReady();
}

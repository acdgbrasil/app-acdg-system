import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '_shared/remote_base.dart';

/// Health probe remote — `GET /health` and `GET /ready`.
///
/// Liveness/readiness signals are intentionally simpler than the other
/// remotes: any throw or non-2xx response surfaces as `Failure(e)` so
/// the caller can react with "alive vs not alive" semantics. We do NOT
/// route through `backendFailure` — the probe shape doesn't carry a
/// structured `BackendError`. This mirrors the legacy contract.
class HealthRemote extends RemoteBase implements HealthContract {
  HealthRemote({required super.dio});

  @override
  Future<Result<void>> checkHealth() async {
    try {
      await dio.get<void>('/health');
      return const Success<void>(null);
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> checkReady() async {
    try {
      await dio.get<void>('/ready');
      return const Success<void>(null);
    } catch (e, stackTrace) {
      return Failure<void>(e, stackTrace: stackTrace);
    }
  }
}

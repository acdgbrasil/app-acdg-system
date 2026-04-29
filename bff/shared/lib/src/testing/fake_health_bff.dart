import 'package:core_contracts/core_contracts.dart';

import '../contract/sub_contracts/health_contract.dart';

/// In-memory fake for [HealthContract] — used in tests and local simulation.
class FakeHealthBff implements HealthContract {
  @override
  Future<Result<void>> checkHealth() async => const Success(null);

  @override
  Future<Result<void>> checkReady() async => const Success(null);
}

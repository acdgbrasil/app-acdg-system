import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/protection_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — cache-only read for the single-per-patient placement
/// history blob. Returns `Success(null)` on cache miss.
class FetchPlacementHistoryUseCase {
  FetchPlacementHistoryUseCase({
    required ProtectionCache cache,

    /// Param accepted for Pattern 1 uniformity (H3 — handbook
    /// `DECISION_HEURISTICS.md`); used when backend exposes list endpoint
    /// in Phase 6+.
    required Clock clock,

    /// See above re: Phase 6+ usage.
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache;

  final ProtectionCache _cache;

  Future<Result<PlacementHistoryResponse?>> call(String patientId) async {
    final cachedResult = await _cache.findPlacementHistory(patientId);
    switch (cachedResult) {
      case Success(:final value):
        return Success<PlacementHistoryResponse?>(value);
      case Failure(:final error, :final stackTrace):
        return Failure<PlacementHistoryResponse?>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}

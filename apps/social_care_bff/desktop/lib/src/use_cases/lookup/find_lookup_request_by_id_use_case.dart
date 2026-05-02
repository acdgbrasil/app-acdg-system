import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/lookup_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — cache-only by id. `LookupContract` exposes no
/// fetch-by-id endpoint; we serve the cache verbatim and return
/// `Success(null)` on miss.
class FindLookupRequestByIdUseCase {
  FindLookupRequestByIdUseCase({
    required LookupCache cache,
    required LookupContract remote,

    /// Param accepted for Pattern 1 uniformity (H3 — handbook
    /// `DECISION_HEURISTICS.md`); used when backend exposes list endpoint
    /// in Phase 6+.
    required Clock clock,

    /// See above re: Phase 6+ usage.
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache;

  final LookupCache _cache;

  Future<Result<LookupRequestResponse?>> call(String requestId) async {
    final cachedResult = await _cache.findRequestById(requestId);
    switch (cachedResult) {
      case Success(:final value):
        return Success<LookupRequestResponse?>(value?.dto);
      case Failure(:final error, :final stackTrace):
        return Failure<LookupRequestResponse?>(error, stackTrace: stackTrace);
    }
  }
}

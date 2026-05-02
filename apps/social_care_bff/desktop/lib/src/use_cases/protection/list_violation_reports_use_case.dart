import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/protection_cache.dart';
import '../_shared/clock.dart';

class ListViolationReportsUseCase {
  ListViolationReportsUseCase({
    required ProtectionCache cache,

    /// Param accepted for Pattern 1 uniformity (H3 — handbook
    /// `DECISION_HEURISTICS.md`); used when backend exposes list endpoint
    /// in Phase 6+.
    required Clock clock,

    /// See above re: Phase 6+ usage.
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache;

  final ProtectionCache _cache;

  Future<Result<List<ViolationReportResponse>>> call(String patientId) async {
    final cachedResult = await _cache.listViolationReports(patientId);
    switch (cachedResult) {
      case Success(:final value):
        return Success<List<ViolationReportResponse>>(value);
      case Failure(:final error, :final stackTrace):
        return Failure<List<ViolationReportResponse>>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}

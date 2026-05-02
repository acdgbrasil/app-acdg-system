import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/patients_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — FTS5 search over `patient_summaries_fts` with remote
/// fallback when the cache returns no matches.
class SearchPatientsUseCase {
  SearchPatientsUseCase({
    required PatientsCache cache,
    required RegistryContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote;

  final PatientsCache _cache;
  final RegistryContract _remote;

  Future<Result<List<PatientSummaryResponse>>> call(String term) async {
    final cachedResult = await _cache.searchSummaries(term);
    if (cachedResult case Success(:final value) when value.isNotEmpty) {
      return Success<List<PatientSummaryResponse>>(value);
    }
    final fresh = await _remote.fetchPatients(search: term);
    switch (fresh) {
      case Success(:final value):
        for (final summary in value.data) {
          await _cache.upsertSummary(summary, version: 1);
        }
        return Success<List<PatientSummaryResponse>>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<List<PatientSummaryResponse>>(
          error,
          stackTrace: stackTrace,
        );
    }
  }
}

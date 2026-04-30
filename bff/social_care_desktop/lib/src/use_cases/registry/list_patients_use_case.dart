import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/patients_cache.dart';
import '../_shared/clock.dart';

/// Pattern 1 — read use case for the patient list view.
///
/// Cache-first via `listSummaries`. If the cache returns rows, they are
/// served (filtered by the optional `status`). On cache miss, the
/// remote `fetchPatients` is consulted, and every returned summary is
/// upserted before returning.
///
/// `cachedAt` per summary row is not consulted here — the cache is a
/// short-lived projection populated on every read miss; staleness is
/// only meaningful for single-aggregate reads.
class ListPatientsUseCase {
  ListPatientsUseCase({
    required PatientsCache cache,
    required RegistryContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote;

  final PatientsCache _cache;
  final RegistryContract _remote;

  Future<Result<List<PatientSummaryResponse>>> call({
    String? status,
    String? cursor,
    int? limit,
  }) async {
    final cachedResult = await _cache.listSummaries(
      status: status,
      cursor: cursor,
      limit: limit,
    );
    if (cachedResult case Success(:final value) when value.isNotEmpty) {
      return Success<List<PatientSummaryResponse>>(value);
    }
    final fresh = await _remote.fetchPatients(
      status: status,
      cursor: cursor,
      limit: limit,
    );
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

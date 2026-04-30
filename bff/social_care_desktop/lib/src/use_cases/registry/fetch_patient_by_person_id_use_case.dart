import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/patients_cache.dart';
import '../_shared/clock.dart';
import '../_shared/stale_policy.dart';

/// Pattern 1 — cache-first lookup by `personId`. Backed by the cache's
/// B-Tree index on `personId` for O(log N) reads.
class FetchPatientByPersonIdUseCase {
  FetchPatientByPersonIdUseCase({
    required PatientsCache cache,
    required RegistryContract remote,
    required Clock clock,
    Duration staleAfter = const Duration(minutes: 5),
  }) : _cache = cache,
       _remote = remote,
       _clock = clock,
       _stale = StalePolicy(staleAfter: staleAfter);

  final PatientsCache _cache;
  final RegistryContract _remote;
  final Clock _clock;
  final StalePolicy _stale;

  Future<Result<PatientResponse>> call(String personId) async {
    final cachedResult = await _cache.findByPersonId(personId);
    if (cachedResult case Success(value: final cached?)) {
      if (!_stale.isStale(cached.cachedAt, now: _clock.now())) {
        return Success<PatientResponse>(cached.dto);
      }
    }
    final fresh = await _remote.fetchPatientByPersonId(personId);
    switch (fresh) {
      case Success(:final value):
        await _cache.upsertPatient(value.data, version: value.data.version);
        return Success<PatientResponse>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<PatientResponse>(error, stackTrace: stackTrace);
    }
  }
}

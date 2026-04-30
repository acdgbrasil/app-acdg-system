import 'package:core_contracts/core_contracts.dart';
import 'package:shared/shared.dart';

import '../../cache/contracts/patients_cache.dart';
import '../_shared/clock.dart';
import '../_shared/stale_policy.dart';

/// Pattern 1 — read use case.
///
/// Cache-first by `patientId`. Refreshes from remote when the cached row
/// is older than [staleAfter] (default 5 minutes). On cache miss or
/// stale hit, the remote response is upserted into the cache before
/// returning so the next read is local.
class FetchPatientUseCase {
  FetchPatientUseCase({
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

  Future<Result<PatientResponse>> call(String patientId) async {
    final cachedResult = await _cache.findById(patientId);
    if (cachedResult case Success(value: final cached?)) {
      if (!_stale.isStale(cached.cachedAt, now: _clock.now())) {
        return Success<PatientResponse>(cached.dto);
      }
    }
    final fresh = await _remote.fetchPatient(patientId);
    switch (fresh) {
      case Success(:final value):
        await _cache.upsertPatient(value.data, version: value.data.version);
        return Success<PatientResponse>(value.data);
      case Failure(:final error, :final stackTrace):
        return Failure<PatientResponse>(error, stackTrace: stackTrace);
    }
  }
}
